from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Mystery Box API"
    DATABASE_URL: str = "postgresql+psycopg2://user:password@localhost/mysterybox"
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Razorpay Test Keys
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""

    class Config:
        env_file = ".env"

settings = Settings()
