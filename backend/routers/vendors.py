from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import models, schemas
from ..database import get_db

router = APIRouter(
    prefix="/vendors",
    tags=["Vendors"]
)

@router.post("/register", response_model=schemas.VendorResponse, status_code=status.HTTP_201_CREATED)
def register_vendor(vendor: schemas.VendorCreate, db: Session = Depends(get_db)):
    # Check if FSSAI license already exists
    db_vendor = db.query(models.Vendor).filter(models.Vendor.fssai_license == vendor.fssai_license).first()
    if db_vendor:
        raise HTTPException(status_code=400, detail="FSSAI license already registered")

    # Convert lat/lon into PostGIS POINT format
    # Format: POINT(longitude latitude)
    point_wkt = f"POINT({vendor.longitude} {vendor.latitude})"

    # Create the database object
    new_vendor = models.Vendor(
        name=vendor.name,
        fssai_license=vendor.fssai_license,
        shop_category=vendor.shop_category,
        location=point_wkt
    )

    db.add(new_vendor)
    db.commit()
    db.refresh(new_vendor)

    return new_vendor

@router.post("/{vendor_id}/rate", response_model=dict)
def rate_vendor(vendor_id: int, request: schemas.RateVendorRequest, db: Session = Depends(get_db)):
    vendor = db.query(models.Vendor).filter(models.Vendor.id == vendor_id).first()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor not found")

    # A simple moving average for rating (in reality you'd store all ratings and compute)
    # We will just shift the rating 10% towards the new rating
    vendor.rating = round((vendor.rating * 0.9) + (request.rating * 0.1), 2)
    
    # Auto-suspend logic
    if vendor.rating < 3.0:
        vendor.is_suspended = True
        
    db.commit()
    db.refresh(vendor)

    return {
        "success": True, 
        "new_rating": vendor.rating, 
        "is_suspended": vendor.is_suspended,
        "message": "Account suspended due to low ratings" if vendor.is_suspended else "Rating submitted"
    }
