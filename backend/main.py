from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import vendors, deals

app = FastAPI(
    title="Mystery Box API",
    description="Hyperlocal surplus food marketplace API",
    version="1.0.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify the exact domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include our new API routers
app.include_router(vendors.router)
app.include_router(deals.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Mystery Box API!"}
