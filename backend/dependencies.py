"""Shared FastAPI dependencies: authenticated user resolution."""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from . import models
from .core.security import decode_token
from .database import get_db

_bearer = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> dict:
    """Validates the bearer token and loads the student or vendor it belongs to."""
    token = credentials.credentials if credentials else None
    payload = decode_token(token) if token else None

    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated. Please sign in.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    role = payload.get("role")
    try:
        user_id = int(payload.get("sub"))
    except (TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid session token.")

    if role == "vendor":
        vendor = db.query(models.Vendor).filter(models.Vendor.id == user_id).first()
        if not vendor:
            raise HTTPException(status_code=401, detail="Vendor account no longer exists.")
        if vendor.is_suspended:
            raise HTTPException(status_code=403, detail="Vendor account is suspended.")
        return {
            "role": "vendor",
            "id": vendor.id,
            "name": vendor.name,
            "email": vendor.email,
        }

    student = db.query(models.Student).filter(models.Student.id == user_id).first()
    if not student:
        raise HTTPException(status_code=401, detail="Student account no longer exists.")
    return {"role": "student", "id": student.id, "name": student.name, "email": student.email}


def require_student(user: dict = Depends(get_current_user)) -> dict:
    if user["role"] != "student":
        raise HTTPException(status_code=403, detail="Only students can perform this action.")
    return user


def require_vendor(user: dict = Depends(get_current_user)) -> dict:
    if user["role"] != "vendor":
        raise HTTPException(status_code=403, detail="Only vendors can perform this action.")
    return user
