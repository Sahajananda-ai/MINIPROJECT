from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
def login(request: LoginRequest):
    # Dummy authentication for mini-project
    # In a real app, verify against DB and return JWT token
    if request.email and request.password:
        return {"access_token": "dummy_token_123", "token_type": "bearer"}
    raise HTTPException(status_code=401, detail="Invalid credentials")
