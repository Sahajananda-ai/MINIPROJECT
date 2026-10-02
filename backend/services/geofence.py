from sqlalchemy.orm import Session
from sqlalchemy import func
from .. import models

def find_students_near_vendor(db: Session, vendor_id: int, radius_meters: int = 2000):
    """
    Finds all students within a specific radius of a vendor.
    Uses PostGIS spatial querying for extreme performance.
    """
    # 1. Get the vendor's exact location
    vendor = db.query(models.Vendor).filter(models.Vendor.id == vendor_id).first()
    if not vendor:
        return []

    # 2. Execute the ST_DWithin spatial query
    # We cast to Geography to calculate true spherical distance in meters rather than degrees
    nearby_students = db.query(models.Student).filter(
        func.ST_DWithin(
            func.cast(models.Student.last_location, func.Geography()), 
            func.cast(vendor.location, func.Geography()), 
            radius_meters
        )
    ).all()

    return nearby_students
