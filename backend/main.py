from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import asyncio
from .routers import vendors, deals, students, auth, ai
from .database import engine, SessionLocal
from .services import decay_pricing
from . import models

from sqlalchemy import text

def init_database_and_migrations():
    """Initializes tables and ensures newly added columns exist in PostgreSQL."""
    try:
        models.Base.metadata.create_all(bind=engine)
        with engine.connect() as conn:
            migration_sqls = [
                # Deals: AI curation columns
                "ALTER TABLE deals ADD COLUMN IF NOT EXISTS title VARCHAR DEFAULT 'Surplus Mystery Box';",
                "ALTER TABLE deals ADD COLUMN IF NOT EXISTS description TEXT;",
                "ALTER TABLE deals ADD COLUMN IF NOT EXISTS dietary_tag VARCHAR DEFAULT 'Vegetarian';",
                "ALTER TABLE deals ADD COLUMN IF NOT EXISTS image_url VARCHAR;",
                # Auth columns
                "ALTER TABLE students ADD COLUMN IF NOT EXISTS password_hash VARCHAR;",
                "ALTER TABLE vendors ADD COLUMN IF NOT EXISTS email VARCHAR;",
                "ALTER TABLE vendors ADD COLUMN IF NOT EXISTS password_hash VARCHAR;",
                # Idempotency key for order creation
                "ALTER TABLE orders ADD COLUMN IF NOT EXISTS client_request_id VARCHAR;",
                "CREATE UNIQUE INDEX IF NOT EXISTS ix_orders_client_request_id ON orders (client_request_id);",
                # Idempotency: one live order per student per deal
                "CREATE UNIQUE INDEX IF NOT EXISTS ix_orders_live_deal_student ON orders (deal_id, student_id) "
                "WHERE status IN ('RESERVED', 'PAID');",
                # Timezone correctness: convert naive UTC timestamps to timestamptz
                "ALTER TABLE deals ALTER COLUMN closing_time TYPE timestamptz "
                "USING closing_time AT TIME ZONE 'UTC';",
                "ALTER TABLE deals ALTER COLUMN created_at TYPE timestamptz "
                "USING created_at AT TIME ZONE 'UTC';",
                "ALTER TABLE orders ALTER COLUMN reserved_at TYPE timestamptz "
                "USING reserved_at AT TIME ZONE 'UTC';",
                "ALTER TABLE orders ALTER COLUMN collected_at TYPE timestamptz "
                "USING collected_at AT TIME ZONE 'UTC';",
            ]
            for sql in migration_sqls:
                conn.execute(text(sql))
            conn.commit()
    except Exception as e:
        print(f"Database init notice: {e}")

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
    # Initialize DB tables and migrations safely on startup
    init_database_and_migrations()
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
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include our new API routers
app.include_router(vendors.router)
app.include_router(deals.router)
app.include_router(students.router)
app.include_router(auth.router)
app.include_router(ai.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Mystery Box API!"}
