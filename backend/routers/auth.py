from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session

from .. import models, schemas
from ..core.security import create_token, hash_password, verify_password
from ..database import get_db
from ..dependencies import get_current_user

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


class RegisterStudentRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=80, example="Rahul Sharma")
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)


class RegisterVendorRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=80, example="Gupta Sweets & Bakery")
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)
    fssai_license: str = Field(..., min_length=6, max_length=32, example="11519024000111")
    shop_category: str = Field(default="Bakery", max_length=40)
    latitude: float
    longitude: float


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    role: str = Field("student", description="student | vendor")


def _token_for(user_id: int, role: str) -> dict:
    return {
        "access_token": create_token({"sub": str(user_id), "role": role}),
        "token_type": "bearer",
        "role": role,
        "id": user_id,
    }


@router.post("/register/student", response_model=dict, status_code=status.HTTP_201_CREATED)
def register_student(request: RegisterStudentRequest, db: Session = Depends(get_db)):
    email = request.email.lower().strip()
    if db.query(models.Student).filter(models.Student.email == email).first():
        raise HTTPException(status_code=400, detail="An account with this email already exists.")

    student = models.Student(name=request.name.strip(), email=email, password_hash=hash_password(request.password))
    db.add(student)
    db.commit()
    db.refresh(student)
    return _token_for(student.id, "student") | {"name": student.name, "email": student.email}


@router.post("/register/vendor", response_model=dict, status_code=status.HTTP_201_CREATED)
def register_vendor(request: RegisterVendorRequest, db: Session = Depends(get_db)):
    email = request.email.lower().strip()
    if db.query(models.Vendor).filter(models.Vendor.email == email).first():
        raise HTTPException(status_code=400, detail="An account with this email already exists.")
    if db.query(models.Vendor).filter(models.Vendor.fssai_license == request.fssai_license).first():
        raise HTTPException(status_code=400, detail="This FSSAI licence is already registered.")

    vendor = models.Vendor(
        name=request.name.strip(),
        email=email,
        password_hash=hash_password(request.password),
        fssai_license=request.fssai_license.strip(),
        shop_category=request.shop_category,
        location=f"POINT({request.longitude} {request.latitude})",
    )
    db.add(vendor)
    db.commit()
    db.refresh(vendor)
    return _token_for(vendor.id, "vendor") | {"name": vendor.name, "email": vendor.email}


@router.post("/login", response_model=dict)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    email = request.email.lower().strip()

    if request.role == "vendor":
        user = db.query(models.Vendor).filter(models.Vendor.email == email).first()
        if not user or not verify_password(request.password, user.password_hash):
            raise HTTPException(status_code=401, detail="Invalid email or password.")
        if user.is_suspended:
            raise HTTPException(status_code=403, detail="This vendor account is suspended.")
        return _token_for(user.id, "vendor") | {"name": user.name, "email": user.email}

    user = db.query(models.Student).filter(models.Student.email == email).first()
    if not user or not verify_password(request.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password.")
    return _token_for(user.id, "student") | {"name": user.name, "email": user.email}


@router.get("/me", response_model=dict)
def me(user: dict = Depends(get_current_user)):
    return user
