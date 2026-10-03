from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from typing import List
from sqlalchemy.orm import Session
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
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if deal.closing_time <= now:
        raise HTTPException(status_code=400, detail="Closing time must be in the future")

    # Create the deal in PostgreSQL
    new_deal = models.Deal(
        vendor_id=deal.vendor_id,
        original_value=deal.original_value,
        start_price=deal.start_price,
        min_price=deal.min_price,
        quantity=deal.quantity,
        closing_time=deal.closing_time
    )
    db.add(new_deal)
    db.commit()
    db.refresh(new_deal)

    # Calculate TTL for Redis (Time remaining in seconds)
    time_remaining = (deal.closing_time - now).total_seconds()

    # Store inventory count in Redis with TTL so it auto-expires when the shop closes
    redis_key = f"deal_inventory:{new_deal.id}"
    redis_client.set(redis_key, deal.quantity, ex=int(time_remaining))

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
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    
    # We would typically do a spatial query here to only return deals near the student,
    # but for simplicity we return all active deals that haven't closed yet.
    active_deals = db.query(models.Deal).filter(
        models.Deal.is_active == True,
        models.Deal.closing_time > now,
        models.Deal.quantity > 0
    ).all()
    
    return active_deals

@router.post("/reserve", response_model=schemas.ReserveResponse)
def reserve_deal(request: schemas.ReserveRequest, db: Session = Depends(get_db)):
    # 1. Fetch deal from DB to verify it exists and is active
    deal = db.query(models.Deal).filter(models.Deal.id == request.deal_id).first()
    if not deal or not deal.is_active:
        raise HTTPException(status_code=404, detail="Deal not found or inactive")
        
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if deal.closing_time <= now:
        raise HTTPException(status_code=400, detail="Deal has expired")

    # 2. Redis Inventory Check (Atomic decrement)
    inventory_key = f"deal_inventory:{deal.id}"
    new_quantity = redis_client.decr(inventory_key)
    
    if new_quantity < 0:
        # Revert the decrement since we went below 0
        redis_client.incr(inventory_key)
        raise HTTPException(status_code=400, detail="Deal is completely sold out")
        
    # 3. Create Redis Lock for this specific student and deal (5 minute TTL)
    # The student now has 5 minutes to complete Razorpay payment
    lock_key = f"deal_reserve:{deal.id}:{request.student_id}"
    lock_acquired = redis_client.set(lock_key, "LOCKED", ex=300, nx=True)
    
    if not lock_acquired:
        # Revert inventory decrement since they already hold a lock
        redis_client.incr(inventory_key)
        raise HTTPException(status_code=400, detail="You already have an active reservation for this deal")
        
    # 4. Calculate the current dynamic price
    current_price = decay_pricing.calculate_decay_price(deal)
    
    return schemas.ReserveResponse(
        success=True,
        message="Reservation successful. You have 5 minutes to complete payment.",
        reserved_price=current_price,
        expires_in_seconds=300
    )

@router.post("/{deal_id}/complete", response_model=dict)
def complete_deal(deal_id: int, request: schemas.CompleteDealRequest, db: Session = Depends(get_db)):
    # 1. Verify deal exists
    deal = db.query(models.Deal).filter(models.Deal.id == deal_id).first()
    if not deal:
        raise HTTPException(status_code=404, detail="Deal not found")

    # 2. Check if a valid lock exists (meaning the student paid and the lock hasn't expired)
    lock_key = f"deal_reserve:{deal.id}:{request.student_id}"
    lock_status = redis_client.get(lock_key)
    
    if not lock_status:
        raise HTTPException(status_code=400, detail="No active reservation found for this student. The reservation may have expired.")

    # 3. Mark the lock as completed/deleted since pickup is done
    redis_client.delete(lock_key)

    # Note: In a production app, we would log this transaction in a new table (e.g., Transactions or Pickups)
    
    return {"success": True, "message": "Pickup confirmed successfully"}
