from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from .. import models, schemas
from ..database import get_db
from ..redis_client import redis_client

router = APIRouter(
    prefix="/deals",
    tags=["Deals (Mystery Boxes)"]
)

@router.post("/create", response_model=schemas.DealResponse, status_code=status.HTTP_201_CREATED)
def create_deal(deal: schemas.DealCreate, db: Session = Depends(get_db)):
    # Ensure the vendor exists
    vendor = db.query(models.Vendor).filter(models.Vendor.id == deal.vendor_id).first()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor not found")

    # Ensure closing time is in the future
    now = datetime.now(timezone.utc).replace(tzinfo=None) # Keep naive for simple comparison if your DB is naive
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

    # TODO: Trigger background task to notify students via geofence here
    
    return new_deal
