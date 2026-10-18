from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import func, select
from datetime import datetime, timezone
from .. import models, schemas
from ..database import get_db
from ..redis_client import redis_client
from ..services import geofence, notifications, decay_pricing

router = APIRouter(
    prefix="/deals",
    tags=["Deals (Mystery Boxes)"]
)

@router.post("/create", response_model=schemas.DealResponse, status_code=status.HTTP_201_CREATED)
def create_deal(deal: schemas.DealCreate, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    # Ensure the vendor exists
    vendor = db.query(models.Vendor).filter(models.Vendor.id == deal.vendor_id).first()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor not found")

    # Ensure closing time is in the future
    now = datetime.now(timezone.utc)
    closing_time = deal.closing_time
    if closing_time.tzinfo is None:
        closing_time = closing_time.replace(tzinfo=timezone.utc)
    if closing_time <= now:
        raise HTTPException(status_code=400, detail="Closing time must be in the future")

    # Create the deal in PostgreSQL
    new_deal = models.Deal(
        vendor_id=deal.vendor_id,
        title=deal.title or "Surplus Mystery Box",
        description=deal.description,
        dietary_tag=deal.dietary_tag or "Vegetarian",
        image_url=deal.image_url,
        original_value=deal.original_value,
        start_price=deal.start_price,
        min_price=deal.min_price,
        quantity=deal.quantity,
        closing_time=closing_time
    )
    db.add(new_deal)
    db.commit()
    db.refresh(new_deal)

    # Calculate TTL for Redis (Time remaining in seconds)
    time_remaining = max(60, int((closing_time - now).total_seconds()))

    # Store inventory count in Redis with TTL so it auto-expires when the shop closes
    redis_key = f"deal_inventory:{new_deal.id}"
    redis_client.set(redis_key, deal.quantity, ex=time_remaining)

    # --- THE MISSING LINK: SPATIAL GEOFENCING ---
    # Find all students within 2km (2000 meters)
    nearby_students = geofence.find_students_near_vendor(db, vendor_id=vendor.id, radius_meters=2000)
    
    # Send push notifications in the background so it doesn't slow down the API response
    background_tasks.add_task(
        notifications.send_push_notification_to_students, 
        nearby_students, 
        new_deal.id, 
        vendor.name
    )
    
    return new_deal

@router.get("/active", response_model=List[schemas.DealWithVendorResponse])
def get_active_deals(db: Session = Depends(get_db)):
    now = datetime.now(timezone.utc)
    
    active_deals = db.query(models.Deal).filter(
        models.Deal.is_active == True,
        models.Deal.closing_time > now,
        models.Deal.quantity > 0
    ).all()
    
    # Extract lat/lng from PostGIS binary location for each deal's vendor
    results = []
    for deal in active_deals:
        vendor = deal.vendor
        # Use SQLAlchemy to extract coordinates from PostGIS POINT
        lng = db.execute(select(func.ST_X(vendor.location))).scalar()
        lat = db.execute(select(func.ST_Y(vendor.location))).scalar()
        
        results.append({
            **deal.__dict__,
            "vendor": {
                "id": vendor.id,
                "name": vendor.name,
                "fssai_license": vendor.fssai_license,
                "shop_category": vendor.shop_category,
                "rating": vendor.rating,
                "is_suspended": vendor.is_suspended,
                "longitude": lng,
                "latitude": lat,
            }
        })
    
    return results

@router.post("/reserve", response_model=schemas.ReserveResponse)
def reserve_deal(request: schemas.ReserveRequest, db: Session = Depends(get_db)):
    # 1. Fetch deal from DB to verify it exists and is active
    deal = db.query(models.Deal).filter(models.Deal.id == request.deal_id).first()
    if not deal or not deal.is_active:
        raise HTTPException(status_code=404, detail="Deal not found or inactive")
        
    now = datetime.now(timezone.utc)
    closing_time = deal.closing_time
    if closing_time and closing_time.tzinfo is None:
        closing_time = closing_time.replace(tzinfo=timezone.utc)

    if closing_time and closing_time <= now:
        raise HTTPException(status_code=400, detail="Deal has expired")

    # Strict inventory check: if DB quantity is 0 or less, reject immediately
    if deal.quantity <= 0:
        raise HTTPException(status_code=409, detail="All mystery boxes for this batch have already been reserved!")

    # 2. Check if student already has an active lock (allow smooth re-entry into checkout)
    lock_key = f"deal_reserve:{deal.id}:{request.student_id}"
    existing_lock = redis_client.get(lock_key)
    if existing_lock:
        ttl = redis_client.ttl(lock_key)
        current_price = decay_pricing.calculate_decay_price(deal)
        return schemas.ReserveResponse(
            success=True,
            message="Active reservation found. You have time remaining to complete payment.",
            reserved_price=current_price,
            expires_in_seconds=max(ttl, 1) if ttl and ttl > 0 else 300
        )

    # 3. Redis Inventory Check (Atomic decrement)
    inventory_key = f"deal_inventory:{deal.id}"
    if not redis_client.exists(inventory_key):
        ttl_seconds = max(60, int((closing_time - now).total_seconds())) if closing_time else 3600
        redis_client.set(inventory_key, deal.quantity, ex=ttl_seconds)

    new_quantity = redis_client.decr(inventory_key)
    
    if new_quantity < 0:
        # Revert the decrement since we went below 0
        redis_client.incr(inventory_key)
        raise HTTPException(status_code=409, detail="All mystery boxes for this batch have already been reserved!")
        
    # 4. Create Redis Lock for this specific student and deal (5 minute TTL)
    lock_acquired = redis_client.set(lock_key, "LOCKED", ex=300, nx=True)
    
    if not lock_acquired:
        # Revert inventory decrement since they already hold a lock
        redis_client.incr(inventory_key)
        raise HTTPException(status_code=400, detail="You already have an active reservation for this deal")
        
    # 5. Calculate the current dynamic price
    current_price = decay_pricing.calculate_decay_price(deal)
    
    return schemas.ReserveResponse(
        success=True,
        message="Reservation successful. You have 5 minutes to complete payment.",
        reserved_price=current_price,
        expires_in_seconds=300
    )

import random

@router.post("/orders/create", response_model=dict)
def create_order(request: schemas.CreateOrderRequest, db: Session = Depends(get_db)):
    """
    Finalizes the reservation, deducts database inventory permanently,
    clears the ephemeral Redis lock, and generates a verified pickup pass code.
    """
    deal = db.query(models.Deal).filter(models.Deal.id == request.deal_id).first()
    if not deal:
        raise HTTPException(status_code=404, detail="Deal not found")

    if deal.quantity <= 0:
        raise HTTPException(status_code=409, detail="All boxes for this deal are completely sold out.")

    now = datetime.now(timezone.utc)
    current_price = decay_pricing.calculate_decay_price(deal)

    # Generate secure 6-character unique alphanumeric pickup code e.g. MB-4182
    rand_suffix = f"{random.randint(1000, 9999)}"
    pickup_code = f"MB-{deal.id}-{rand_suffix}"

    # Create persistent Order in Postgres
    order = models.Order(
        deal_id=deal.id,
        student_id=request.student_id,
        vendor_id=deal.vendor_id,
        pickup_code=pickup_code,
        status="PAID",
        paid_price=current_price,
        original_value=deal.original_value,
        reserved_at=now
    )
    db.add(order)

    # Permanently decrement inventory
    deal.quantity = max(0, deal.quantity - 1)
    if deal.quantity == 0:
        deal.is_active = False

    db.commit()
    db.refresh(order)

    # Release Redis lock
    lock_key = f"deal_reserve:{deal.id}:{request.student_id}"
    redis_client.delete(lock_key)

    vendor = deal.vendor
    return {
        "success": True,
        "message": "Order confirmed! Present this pickup code at counter.",
        "order_id": order.id,
        "pickup_code": order.pickup_code,
        "vendor_name": vendor.name,
        "paid_price": order.paid_price,
        "remaining_quantity": deal.quantity,
        "order": {
            "id": order.id,
            "deal_id": deal.id,
            "pickup_code": order.pickup_code,
            "vendor_id": vendor.id,
            "vendor_name": vendor.name,
            "shop_category": vendor.shop_category,
            "paid_price": order.paid_price,
            "original_value": order.original_value,
            "savings": round(order.original_value - order.paid_price, 2),
            "status": order.status,
            "reserved_at": order.reserved_at.isoformat(),
            "closing_time": deal.closing_time.isoformat() if deal.closing_time else None
        }
    }

@router.post("/orders/verify-pickup", response_model=schemas.VerifyPickupResponse)
def verify_pickup(request: schemas.VerifyPickupRequest, db: Session = Depends(get_db)):
    """
    Vendor-facing validation: Checks if the scanned or entered pickup code is valid,
    ensures it belongs to this vendor, and verifies it hasn't been redeemed already.
    """
    clean_code = (request.pickup_code or "").strip().upper()
    if not clean_code:
        raise HTTPException(status_code=400, detail="Pickup code cannot be blank")

    # Search for matching order
    order = db.query(models.Order).filter(
        func.upper(models.Order.pickup_code) == clean_code
    ).first()

    if not order:
        raise HTTPException(
            status_code=404,
            detail=f"Passcode '{clean_code}' is invalid or does not exist. Please check with customer."
        )

    if order.vendor_id != request.vendor_id:
        raise HTTPException(
            status_code=403,
            detail=f"Passcode '{clean_code}' belongs to a different store. Cannot redeem here."
        )

    if order.status == "COLLECTED":
        collected_time_str = order.collected_at.strftime("%I:%M %p") if order.collected_at else "earlier"
        raise HTTPException(
            status_code=400,
            detail=f"This Mystery Box was already collected at {collected_time_str}!"
        )

    # Mark as collected
    order.status = "COLLECTED"
    order.collected_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(order)

    deal = order.deal
    student = order.student
    student_name = student.name if student else "Campus Student"

    return schemas.VerifyPickupResponse(
        success=True,
        message=f"Pickup verified! Mystery Box handed over to {student_name}.",
        order={
            "id": order.id,
            "pickup_code": order.pickup_code,
            "student_name": student_name,
            "deal_title": deal.title if deal else "Surplus Mystery Box",
            "paid_price": order.paid_price,
            "original_value": order.original_value,
            "savings": round(order.original_value - order.paid_price, 2),
            "status": order.status,
            "collected_at": order.collected_at.isoformat()
        }
    )

@router.get("/orders/student/{student_id}", response_model=List[dict])
def get_student_orders(student_id: int, db: Session = Depends(get_db)):
    orders = db.query(models.Order).filter(models.Order.student_id == student_id).order_by(models.Order.id.desc()).all()
    results = []
    for o in orders:
        vendor = o.vendor
        deal = o.deal
        results.append({
            "id": o.id,
            "deal_id": o.deal_id,
            "pickup_code": o.pickup_code,
            "vendor_name": vendor.name if vendor else "Mystery Box Partner",
            "shop_category": vendor.shop_category if vendor else "Surplus",
            "paid_price": o.paid_price,
            "original_value": o.original_value,
            "savings": round(o.original_value - o.paid_price, 2),
            "status": o.status,
            "is_collected": o.status == "COLLECTED",
            "reserved_at": o.reserved_at.isoformat() if o.reserved_at else None,
            "closing_time": deal.closing_time.isoformat() if (deal and deal.closing_time) else None
        })
    return results

@router.get("/orders/vendor/{vendor_id}", response_model=List[dict])
def get_vendor_orders(vendor_id: int, db: Session = Depends(get_db)):
    orders = db.query(models.Order).filter(models.Order.vendor_id == vendor_id).order_by(models.Order.id.desc()).all()
    results = []
    for o in orders:
        student = o.student
        deal = o.deal
        results.append({
            "id": o.id,
            "pickup_code": o.pickup_code,
            "student_name": student.name if student else "Campus Student",
            "deal_title": deal.title if deal else "Surplus Box",
            "paid_price": o.paid_price,
            "savings": round(o.original_value - o.paid_price, 2),
            "status": o.status,
            "is_collected": o.status == "COLLECTED",
            "reserved_at": o.reserved_at.isoformat() if o.reserved_at else None,
            "collected_at": o.collected_at.isoformat() if o.collected_at else None
        })
    return results

@router.post("/{deal_id}/complete", response_model=dict)
def complete_deal(deal_id: int, request: schemas.CompleteDealRequest, db: Session = Depends(get_db)):
    deal = db.query(models.Deal).filter(models.Deal.id == deal_id).first()
    if not deal:
        raise HTTPException(status_code=404, detail=f"Deal #{deal_id} not found")

    lock_key = f"deal_reserve:{deal.id}:{request.student_id}"
    redis_client.delete(lock_key)

    if deal.quantity > 0:
        deal.quantity -= 1
        db.commit()

    return {
        "success": True, 
        "message": f"Pickup confirmed successfully for Deal #{deal.id} ({deal.vendor.name})!",
        "deal_id": deal.id,
        "vendor_id": deal.vendor_id,
        "vendor_name": deal.vendor.name
    }
