from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Mystery Box API"
    DATABASE_URL: str = "postgresql+psycopg2://user:password@localhost/mysterybox"
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Razorpay Test Keys
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""

    # Secret used to sign session tokens. MUST be overridden in production.
    AUTH_SECRET_KEY: str = "savebite-local-dev-secret-change-me"

    # Google Gemini key for the AI curator (optional; falls back to templates)
    GEMINI_API_KEY: str = ""

    # Failed pickup-code attempts allowed per vendor before backoff
    PICKUP_VERIFY_MAX_ATTEMPTS: int = 5
    PICKUP_VERIFY_WINDOW_SECONDS: int = 300

    class Config:
        env_file = ".env"

settings = Settings()
