import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    APP_NAME: str = "PhishCatch API"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")

settings = Settings()
