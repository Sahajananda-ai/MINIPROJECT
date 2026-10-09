from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from datetime import datetime, timezone

from .database import Base

class Vendor(Base):
    __tablename__ = "vendors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    fssai_license = Column(String, unique=True, index=True)
    shop_category = Column(String)
    
    # We use PostGIS 'POINT' geometry to store exact GPS coordinates (Longitude, Latitude)
    # spatial_index=True makes spatial queries (like 'find users within 2km') extremely fast
    location = Column(Geometry(geometry_type='POINT', srid=4326), spatial_index=True)
    
    rating = Column(Float, default=5.0)
    is_suspended = Column(Boolean, default=False)

    # Relationship to deals
    deals = relationship("Deal", back_populates="vendor")

class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    
    # Stores the student's last known location for geofencing notifications
    last_location = Column(Geometry(geometry_type='POINT', srid=4326), spatial_index=True)

class Deal(Base):
    __tablename__ = "deals"

    id = Column(Integer, primary_key=True, index=True)
    vendor_id = Column(Integer, ForeignKey("vendors.id"))
    
    original_value = Column(Float)
    start_price = Column(Float)
    min_price = Column(Float)
    
    quantity = Column(Integer)
    closing_time = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    is_active = Column(Boolean, default=True)

    vendor = relationship("Vendor", back_populates="deals")
