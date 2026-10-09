from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import asyncio
from routers import vendors, deals, students, auth
from database import engine, SessionLocal
from services import decay_pricing
import models

# Create all database tables
models.Base.metadata.create_all(bind=engine)

async def periodic_pricing_updater():
    """Background task to run decay pricing updates every 15 minutes."""
    while True:
        try:
            db = SessionLocal()
            print("--- Running Decay Pricing Update ---")
            decay_pricing.run_pricing_update_job(db)
            db.close()
        except Exception as e:
            print(f"Error in pricing job: {e}")
            
        # Wait 15 minutes (900 seconds) before running again
        await asyncio.sleep(900)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Start the background task when the app starts
    task = asyncio.create_task(periodic_pricing_updater())
    yield
    # Clean up when the app shuts down
    task.cancel()

app = FastAPI(
    title="Mystery Box API",
    description="Hyperlocal surplus food marketplace API",
    version="1.0.0",
    lifespan=lifespan,
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
app.include_router(students.router)
app.include_router(auth.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Mystery Box API!"}
