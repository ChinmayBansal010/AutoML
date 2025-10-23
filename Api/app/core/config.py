import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List
from pathlib import Path

class Settings(BaseSettings):
    """
    Application settings loaded from environment variables via a .env file.
    """
    PROJECT_NAME: str = "AutoML API"
    
    # --- SECURITY SETTINGS ---
    API_KEY: str 
    ALLOWED_ORIGINS: List[str] = ["*"]

    # --- VERCEL BLOB STORAGE (for large files) ---
    BLOB_READ_WRITE_TOKEN: str

    # --- VERCEL KV (REDIS) (for job status) ---
    REDIS_URL: str # <-- This is the variable Vercel provided

    # --- MODEL & TRAINING CONFIGURATIONS ---
    SUPPORTED_MODELS: List[str] = ["random_forest", "xgboost", "lightgbm", "catboost", "logistic_regression"]
    DEFAULT_TEST_SIZE: float = 0.2

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        extra='ignore'
    )

settings = Settings()