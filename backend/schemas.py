from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime

# --- VENDOR SCHEMAS ---
class VendorBase(BaseModel):
    name: str = Field(..., example="Gupta Sweets & Bakery")
    fssai_license: str = Field(..., example="11519024000111")
    shop_category: str = Field(..., example="Bakery")
    longitude: float = Field(..., description="GPS Longitude", example=77.2090)
    latitude: float = Field(..., description="GPS Latitude", example=28.6139)

class VendorCreate(VendorBase):
    pass

class VendorResponse(VendorBase):
    id: int
    rating: float
    is_suspended: bool

    class Config:
        from_attributes = True


# --- STUDENT SCHEMAS ---
class StudentBase(BaseModel):
    name: str = Field(..., example="Rahul Sharma")
    email: EmailStr = Field(..., example="rahul@college.edu")

class StudentCreate(StudentBase):
    pass

class StudentResponse(StudentBase):
    id: int

    class Config:
        from_attributes = True


# --- DEAL (MYSTERY BOX) SCHEMAS ---
class DealBase(BaseModel):
    original_value: float = Field(..., gt=0, description="Actual value of the food")
    start_price: float = Field(..., gt=0, description="Price at listing")
    min_price: float = Field(..., gt=0, description="Absolute lowest price it can drop to")
    quantity: int = Field(..., gt=0, description="Number of boxes available")
    closing_time: datetime = Field(..., description="When the shop closes / food expires")

class DealCreate(DealBase):
    vendor_id: int

class DealResponse(DealBase):
    id: int
    created_at: datetime
    is_active: bool

    class Config:
        from_attributes = True
