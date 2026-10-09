from sqlalchemy.orm import Session
from sqlalchemy import func
from .. import models

from sqlalchemy import cast
from geoalchemy2 import Geography

def find_students_near_vendor(db: Session, vendor_id: int, radius_meters: int = 2000):
    """
    Finds all students within a specific radius of a vendor.
    Uses PostGIS spatial querying for extreme performance.
    """
    # Execute the ST_DWithin spatial query using a JOIN
    # This keeps the geometry entirely inside the database and avoids SQLAlchemy casting crashes
    nearby_students = db.query(models.Student).join(
        models.Vendor, models.Vendor.id == vendor_id
    ).filter(
        func.ST_DWithin(
            cast(models.Student.last_location, Geography), 
            cast(models.Vendor.location, Geography), 
            radius_meters
        )
    ).all()

    return nearby_students
