from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timezone, timedelta
import secrets
import time
from .. import models, schemas
from ..database import get_db
from ..dependencies import require_student, require_vendor
from ..redis_client import redis_client
from ..services import geofence, notifications, decay_pricing
from ..core.config import settings

router = APIRouter(
    prefix="/deals",
    tags=["Deals (Mystery Boxes)"]
)

# How long a reservation hold lasts (matches the client-side checkout countdown)
LOCK_TTL_SECONDS = 300


def locks_key(deal_id: int) -> str:
    return f"deal_locks:{deal_id}"


def locks_for_deal(deal_id: int):
    return redis_client


def sweep_expired_locks(deal_id: int, now_ts: float) -> int:
    """Drops holds whose 5 minutes elapsed so capacity returns to the pool."""
    key = locks_key(deal_id)
    redis_client.zremrangebyscore(key, "-inf", now_ts)
    return redis_client.zcard(key)

@router.post("/create", response_model=schemas.DealResponse, status_code=status.HTTP_201_CREATED)
def create_deal(
    deal: schemas.DealCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    user: dict = Depends(require_vendor),
):
    # The listing vendor comes from the signed token — a client cannot publish
    # deals on behalf of another shop.
    vendor_id = user["id"]
    vendor = db.query(models.Vendor).filter(models.Vendor.id == vendor_id).first()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor not found")

    # Ensure closing time is in the future
    now = datetime.now(timezone.utc)
    closing_time = deal.closing_time
    if closing_time.tzinfo is None:
        closing_time = closing_time.replace(tzinfo=timezone.utc)
    if closing_time <= now:
        raise HTTPException(status_code=400, detail="Closing time must be in the future")

    # Guard against obviously nonsensical pricing input
    if deal.min_price > deal.start_price:
        raise HTTPException(status_code=400, detail="min_price cannot exceed start_price")
    if deal.start_price > deal.original_value:
        raise HTTPException(status_code=400, detail="start_price cannot exceed the original value")

    # Create the deal in PostgreSQL
    new_deal = models.Deal(
        vendor_id=vendor_id,
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
    """
    Active, in-stock deals with the vendor's coordinates and the LIVE decayed
    price. The client must render `current_price` (the price actually charged),
    not `start_price`.
    """
    now = datetime.now(timezone.utc)
    
    active_deals = db.query(models.Deal).filter(
        models.Deal.is_active == True,
        models.Deal.closing_time > now,
        models.Deal.quantity > 0
    ).order_by(models.Deal.closing_time.asc()).all()
    
    results = []
    for deal in active_deals:
        vendor = deal.vendor
        lng, lat = _lng_lat(vendor.location, db, vendor.id)
        current_price = decay_pricing.calculate_decay_price(deal)

        results.append({
            **{k: v for k, v in deal.__dict__.items() if k != "_sa_instance_state"},
            "current_price": current_price,
            "discount_percent": (
                round(((deal.original_value - current_price) / deal.original_value) * 100)
                if deal.original_value and deal.original_value > 0 else 0
            ),
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


def _lng_lat(location, db: Session, vendor_id: int):
    """
    Reads a PostGIS POINT without a per-deal round trip.
    Falls back to a filtered ST_X/ST_Y query if the geometry is unexpected.
    """
    if location is None:
        return None, None
    try:
        raw = bytes(location) if not isinstance(location, (bytes, str)) else location
        if isinstance(raw, str):
            if raw.upper().startswith("POINT"):
                coords = raw[raw.index("(") + 1:raw.index(")")].split()
                return float(coords[0]), float(coords[1])
            raw = bytes.fromhex(raw)
        if isinstance(raw, bytes):
            import struct
            # EWKB little-endian: 1 byte order, 4 type, optional 4-byte SRID, then lon/lat doubles
            if len(raw) >= 25 and raw[0] == 1 and (struct.unpack("<I", raw[1:5])[0] & 0x20000000):
                return struct.unpack("<dd", raw[9:25])
            if len(raw) >= 21 and raw[0] == 1:
                return struct.unpack("<dd", raw[5:21])
    except Exception:
        pass
    try:
        lng = db.execute(select(func.ST_X(models.Vendor.location)).where(models.Vendor.id == vendor_id)).scalar()
        lat = db.execute(select(func.ST_Y(models.Vendor.location)).where(models.Vendor.id == vendor_id)).scalar()
        return lng, lat
    except Exception:
        return None, None

@router.post("/reserve", response_model=schemas.ReserveResponse)
def reserve_deal(
    request: schemas.ReserveRequest,
    db: Session = Depends(get_db),
    user: dict = Depends(require_student),
):
    """
    Holds a box for 5 minutes.

    Locking model: a Redis sorted set `deal_locks:{deal_id}` stores one member per
    student with an expiry score. The set is swept of expired members before every
    capacity check, so an abandoned reservation heals itself when its 5 minutes end
    — no permanently decremented stock, no phantom sold-out.
    """
    student_id = user["id"]  # server-derived, never client-supplied

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

    # 2. Already holding a live order for this deal? Return it idempotently.
    live_order = (
        db.query(models.Order)
        .filter(
            models.Order.deal_id == deal.id,
            models.Order.student_id == student_id,
            models.Order.status.in_(["RESERVED", "PAID"]),
        )
        .first()
    )
    if live_order:
        return schemas.ReserveResponse(
            success=True,
            message="You already have a live order for this box. See My Pickups for your code.",
            reserved_price=live_order.paid_price,
            expires_in_seconds=0,
        )

    # 3. Check for an existing hold (allows smooth re-entry into checkout)
    locks = locks_for_deal(deal.id)
    member = str(student_id)
    existing = locks.zscore(locks_key(deal.id), member)
    if existing is not None and existing > time.time():
        ttl = int(existing - time.time())
        current_price = decay_pricing.calculate_decay_price(deal)
        return schemas.ReserveResponse(
            success=True,
            message="Active reservation found. You have time remaining to complete payment.",
            reserved_price=current_price,
            expires_in_seconds=max(ttl, 1)
        )

    # 4. Sweep expired holds, then check capacity against DB truth
    sweep_expired_locks(deal.id, now_ts=time.time())
    held = int(locks.zcard(locks_key(deal.id)))
    if held >= deal.quantity:
        raise HTTPException(status_code=409, detail="All mystery boxes for this batch have already been reserved!")

    # 5. Acquire this student's hold (5 minute TTL)
    expires_at = time.time() + LOCK_TTL_SECONDS
    locks.zadd(locks_key(deal.id), {member: expires_at})
    locks.expire(locks_key(deal.id), LOCK_TTL_SECONDS * 2)

    current_price = decay_pricing.calculate_decay_price(deal)

    return schemas.ReserveResponse(
        success=True,
        message="Reservation successful. You have 5 minutes to complete payment.",
        reserved_price=current_price,
        expires_in_seconds=LOCK_TTL_SECONDS
    )


# Stronger, unguessable pickup codes: 8 chars of Crockford-style base32 (~36 bits)
_PICKUP_ALPHABET = "ABCDEFGHJKMNPQRSTVWXYZ23456789"


def _new_pickup_code(deal_id: int) -> str:
    suffix = "".join(secrets.choice(_PICKUP_ALPHABET) for _ in range(8))
    return f"SB-{suffix}"


@router.post("/orders/create", response_model=dict)
def create_order(
    request: schemas.CreateOrderRequest,
    db: Session = Depends(get_db),
    user: dict = Depends(require_student),
):
    """
    Finalizes the reservation: converts the 5-minute hold into a paid order,
    decrements stock exactly once under a row lock, and issues a pickup pass.

    A valid hold is mandatory — this endpoint can no longer be called cold.
    """
    student_id = user["id"]  # server-derived, never client-supplied

    # Idempotency: a retried payment must return the original order, not a new one
    if request.client_request_id:
        existing = (
            db.query(models.Order)
            .filter(models.Order.client_request_id == request.client_request_id)
            .first()
        )
        if existing:
            return _order_payload(db, existing, message="Order already confirmed.")

    # Live order already exists for this pair? Return it instead of double-charging.
    existing_live = (
        db.query(models.Order)
        .filter(
            models.Order.deal_id == request.deal_id,
            models.Order.student_id == student_id,
            models.Order.status.in_(["RESERVED", "PAID"]),
        )
        .first()
    )
    if existing_live:
        return _order_payload(db, existing_live, message="You already have a live order for this box.")

    # Lock the deal row so concurrent buyers cannot oversell the last box
    deal = (
        db.query(models.Deal)
        .filter(models.Deal.id == request.deal_id)
        .with_for_update()
        .first()
    )
    if not deal:
        raise HTTPException(status_code=404, detail="Deal not found")

    # An active hold is REQUIRED before payment can finalize
    locks = locks_for_deal(deal.id)
    member = str(student_id)
    score = locks.zscore(locks_key(deal.id), member)
    if score is None or score <= time.time():
        locks.zrem(locks_key(deal.id), member)
        raise HTTPException(
            status_code=409,
            detail="Your reservation hold has expired. Please reserve the box again.",
        )

    if deal.quantity <= 0:
        raise HTTPException(status_code=409, detail="All boxes for this deal are completely sold out.")

    now = datetime.now(timezone.utc)
    current_price = decay_pricing.calculate_decay_price(deal)
    pickup_code = _new_pickup_code(deal.id)

    # Create persistent Order in Postgres
    order = models.Order(
        deal_id=deal.id,
        student_id=student_id,
        vendor_id=deal.vendor_id,
        pickup_code=pickup_code,
        status="PAID",
        paid_price=current_price,
        original_value=deal.original_value,
        reserved_at=now,
        client_request_id=request.client_request_id,
    )
    db.add(order)

    # Permanently decrement inventory (row is locked, so this is atomic)
    deal.quantity = max(0, deal.quantity - 1)
    if deal.quantity == 0:
        deal.is_active = False

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="This box was just claimed by another student.")
    db.refresh(order)

    # Release the hold now that it became a real order
    locks.zrem(locks_key(deal.id), member)

    return _order_payload(db, order, message="Order confirmed! Present this pickup code at counter.")


def _order_payload(db: Session, order: models.Order, message: str = "") -> dict:
    """Shared response builder so retry/idempotent paths return identical shapes."""
    vendor = order.vendor
    deal = order.deal
    vendor = deal.vendor if deal and deal.vendor else vendor
    closing = deal.closing_time if deal else None
    reserved_at = order.reserved_at.replace(tzinfo=timezone.utc) if order.reserved_at and order.reserved_at.tzinfo is None else order.reserved_at
    closing_str = None
    if closing:
        closing = closing.replace(tzinfo=timezone.utc) if closing.tzinfo is None else closing
        closing_str = closing.isoformat().replace("+00:00", "Z")

    return {
        "success": True,
        "message": message or "Order confirmed!",
        "order_id": order.id,
        "pickup_code": order.pickup_code,
        "vendor_name": vendor.name if vendor else "Mystery Box Partner",
        "paid_price": order.paid_price,
        "remaining_quantity": deal.quantity if deal else 0,
        "order": {
            "id": order.id,
            "deal_id": order.deal_id,
            "pickup_code": order.pickup_code,
            "vendor_id": order.vendor_id,
            "vendor_name": vendor.name if vendor else "Mystery Box Partner",
            "shop_category": vendor.shop_category if vendor else "Surplus",
            "paid_price": order.paid_price,
            "original_value": order.original_value,
            "savings": round((order.original_value or 0) - (order.paid_price or 0), 2),
            "status": order.status,
            "reserved_at": reserved_at.isoformat().replace("+00:00", "Z") if reserved_at else None,
            "closing_time": closing_str,
        }
    }

@router.post("/orders/verify-pickup", response_model=schemas.VerifyPickupResponse)
def verify_pickup(
    request: schemas.VerifyPickupRequest,
    db: Session = Depends(get_db),
    user: dict = Depends(require_vendor),
):
    """
    Vendor-facing validation: checks the code is valid, belongs to THIS vendor
    (taken from the signed token, never the request body), and is unused.

    Failed attempts are rate-limited per vendor so the 8-char code cannot be
    brute-forced.
    """
    vendor_id = user["id"]  # server-derived, never client-supplied
    clean_code = (request.pickup_code or "").strip().upper()
    if not clean_code:
        raise HTTPException(status_code=400, detail="Pickup code cannot be blank")

    # Rate-limit failed attempts: PICKUP_VERIFY_MAX_ATTEMPTS per window
    attempts_key = f"pickup_attempts:{vendor_id}"
    attempts = redis_client.incr(attempts_key)
    if attempts == 1:
        redis_client.expire(attempts_key, settings.PICKUP_VERIFY_WINDOW_SECONDS)
    if attempts > settings.PICKUP_VERIFY_MAX_ATTEMPTS:
        remaining = redis_client.ttl(attempts_key)
        raise HTTPException(
            status_code=429,
            detail=f"Too many wrong codes. Try again in {max(remaining, 1)} seconds.",
        )

    # Search for matching order (row-locked so two staff cannot redeem at once)
    order = (
        db.query(models.Order)
        .filter(func.upper(models.Order.pickup_code) == clean_code)
        .with_for_update()
        .first()
    )

    if not order:
        raise HTTPException(
            status_code=404,
            detail=f"Passcode '{clean_code}' is invalid or does not exist. Please check with customer."
        )

    if order.vendor_id != vendor_id:
        raise HTTPException(
            status_code=403,
            detail=f"Passcode '{clean_code}' belongs to a different store. Cannot redeem here."
        )

    if order.status == "COLLECTED":
        collected_at = order.collected_at
        if collected_at and collected_at.tzinfo is None:
            collected_at = collected_at.replace(tzinfo=timezone.utc)
        # Show local Indian time to staff, not UTC
        ist = timezone(timedelta(hours=5, minutes=30))
        collected_time_str = collected_at.astimezone(ist).strftime("%I:%M %p") if collected_at else "earlier"
        raise HTTPException(
            status_code=400,
            detail=f"This Mystery Box was already collected at {collected_time_str}!"
        )

    # Mark as collected — this is the ONLY path that completes an order
    order.status = "COLLECTED"
    order.collected_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(order)

    redis_client.delete(attempts_key)  # successful handoff resets the counter

    deal = order.deal
    student = order.student
    student_name = student.name if student else "Campus Student"

    collected_at = order.collected_at.isoformat().replace("+00:00", "Z")
    return schemas.VerifyPickupResponse(
        success=True,
        message=f"Pickup verified! Mystery Box handed over to {student_name}.",
        order={
            "id": order.id,
            "deal_id": order.deal_id,
            "pickup_code": order.pickup_code,
            "student_name": student_name,
            "deal_title": deal.title if deal else "Surplus Mystery Box",
            "paid_price": order.paid_price,
            "original_value": order.original_value,
            "savings": round((order.original_value or 0) - (order.paid_price or 0), 2),
            "status": order.status,
            "collected_at": collected_at,
        }
    )


def _serialize_student_order(o: models.Order) -> dict:
    def _iso(value):
        if value is None:
            return None
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.isoformat().replace("+00:00", "Z")

    vendor = o.vendor
    deal = o.deal
    return {
        "id": o.id,
        "deal_id": o.deal_id,
        "vendor_id": o.vendor_id,
        "pickup_code": o.pickup_code,
        "vendor_name": vendor.name if vendor else "Mystery Box Partner",
        "shop_category": vendor.shop_category if vendor else "Surplus",
        "latitude": None,
        "longitude": None,
        "paid_price": o.paid_price,
        "original_value": o.original_value,
        "savings": round((o.original_value or 0) - (o.paid_price or 0), 2),
        "status": o.status,
        "is_collected": o.status == "COLLECTED",
        "reserved_at": _iso(o.reserved_at),
        "closing_time": _iso(deal.closing_time) if deal else None,
    }


@router.get("/orders/me", response_model=List[dict])
def get_my_orders(db: Session = Depends(get_db), user: dict = Depends(require_student)):
    """Orders for the signed-in student. Identity comes from the token."""
    orders = (
        db.query(models.Order)
        .filter(models.Order.student_id == user["id"])
        .order_by(models.Order.id.desc())
        .all()
    )
    results = []
    for o in orders:
        item = _serialize_student_order(o)
        # Expose vendor coordinates so the client can draw the route
        vendor = o.vendor
        if vendor is not None:
            lng, lat = _lng_lat(vendor.location, db, vendor.id)
            item["longitude"], item["latitude"] = lng, lat
        results.append(item)
    return results


@router.get("/orders/vendor/me", response_model=List[dict])
def get_my_vendor_orders(db: Session = Depends(get_db), user: dict = Depends(require_vendor)):
    """Orders for the signed-in vendor's store."""
    orders = (
        db.query(models.Order)
        .filter(models.Order.vendor_id == user["id"])
        .order_by(models.Order.id.desc())
        .all()
    )
    results = []
    for o in orders:
        student = o.student
        deal = o.deal
        results.append({
            "id": o.id,
            "deal_id": o.deal_id,
            "student_id": o.student_id,
            "pickup_code": o.pickup_code,
            "student_name": student.name if student else "Campus Student",
            "deal_title": deal.title if deal else "Surplus Box",
            "paid_price": o.paid_price,
            "original_value": o.original_value,
            "savings": round((o.original_value or 0) - (o.paid_price or 0), 2),
            "status": o.status,
            "is_collected": o.status == "COLLECTED",
            "reserved_at": o.reserved_at.isoformat().replace("+00:00", "Z") if o.reserved_at else None,
            "collected_at": o.collected_at.isoformat().replace("+00:00", "Z") if o.collected_at else None,
        })
    return results
