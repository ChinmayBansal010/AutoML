import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List
from pathlib import Path

# Use environment variable or relative path (works on Windows and Linux)
SERVICE_ACCOUNT_KEY_PATH = os.getenv(
    "FIREBASE_SERVICE_ACCOUNT_FILE",
    str(Path(__file__).parent.parent.parent / "firebase_service_account.json")
)

class Settings(BaseSettings):
    """
    Application settings loaded from environment variables via a .env file.
    """
    PROJECT_NAME: str = "AutoML API"
    
    FIREBASE_SERVICE_ACCOUNT_FILE: str = SERVICE_ACCOUNT_KEY_PATH
    
    ALLOWED_ORIGINS: List[str] = ["*"]

    BLOB_READ_WRITE_TOKEN: str

    REDIS_URL: str

    SUPPORTED_MODELS: List[str] = ["random_forest", "logistic_regression", "decision_tree"]
    DEFAULT_TEST_SIZE: float = 0.2

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        extra='ignore'
    )

settings = Settings()