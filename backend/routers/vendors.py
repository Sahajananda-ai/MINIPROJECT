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
