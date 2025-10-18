import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List
from pathlib import Path

# Base directory of the project
BASE_DIR = Path(__file__).resolve().parent.parent

class Settings(BaseSettings):
    """
    Application settings loaded from environment variables via a .env file.
    """
    PROJECT_NAME: str = "AutoML API"
    
    # --- SECURITY SETTINGS ---
    # This key MUST be set in your .env file. It should be a long, random string.
    API_KEY: str 
    
    # CORS: List of allowed origins for your Flutter app.
    # For production, set this to your app's domain.
    # Example .env: ALLOWED_ORIGINS='["https://my-app.com", "http://localhost:8080"]'
    ALLOWED_ORIGINS: List[str] = ["*"] # Default to all for easy local testing

    # --- STORAGE SETTINGS FOR DEPLOYMENT ---
    # This is the crucial part for Render's persistent disk.
    # It reads STORAGE_DIR from the environment, defaulting to a local 'storage' folder.
    # On Render, you will set this to the disk's mount path (e.g., /var/data/automl_storage).
    STORAGE_DIR: Path = BASE_DIR / "storage"

    # Define data directories as properties relative to the STORAGE_DIR
    @property
    def UPLOADS_DIR(self) -> Path:
        return self.STORAGE_DIR / "uploads"

    @property
    def REPORTS_DIR(self) -> Path:
        return self.STORAGE_DIR / "reports"

    @property
    def MODELS_DIR(self) -> Path:
        return self.STORAGE_DIR / "models"
    
    @property
    def TASK_STATUS_DIR(self) -> Path:
        return self.STORAGE_DIR / "task_status"

    # --- MODEL & TRAINING CONFIGURATIONS ---
    SUPPORTED_MODELS: List[str] = ["random_forest", "xgboost", "lightgbm", "catboost", "logistic_regression"]
    DEFAULT_TEST_SIZE: float = 0.2

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        extra='ignore'
    )

settings = Settings()