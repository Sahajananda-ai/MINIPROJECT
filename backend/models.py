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
    location = Column(Geometry(geometry_type='POINT', srid=4326))
    
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
    last_location = Column(Geometry(geometry_type='POINT', srid=4326))

class Deal(Base):
    __tablename__ = "deals"

    id = Column(Integer, primary_key=True, index=True)
    vendor_id = Column(Integer, ForeignKey("vendors.id"))
    
    title = Column(String, default="Surplus Mystery Box")
    description = Column(String, nullable=True)
    dietary_tag = Column(String, default="Vegetarian")
    image_url = Column(String, nullable=True)
    
    original_value = Column(Float)
    start_price = Column(Float)
    min_price = Column(Float)
    
    quantity = Column(Integer)
    closing_time = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    is_active = Column(Boolean, default=True)

    vendor = relationship("Vendor", back_populates="deals")


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    deal_id = Column(Integer, ForeignKey("deals.id"), index=True)
    student_id = Column(Integer, ForeignKey("students.id"), index=True)
    vendor_id = Column(Integer, ForeignKey("vendors.id"), index=True)

    pickup_code = Column(String, unique=True, index=True)
    status = Column(String, default="PAID")  # RESERVED, PAID, COLLECTED, CANCELLED
    paid_price = Column(Float)
    original_value = Column(Float)

    reserved_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    collected_at = Column(DateTime(timezone=True), nullable=True)

    deal = relationship("Deal", backref="orders")
    student = relationship("Student", backref="orders")
    vendor = relationship("Vendor", backref="orders")
