from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List

class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    """
    # Add Project Name for the root endpoint message
    PROJECT_NAME: str = "Auto-ML API"
    API_KEY: str

    # Paths and Directories
    BASE_DIR: str = "data"
    UPLOADS_DIR: str = "data/uploads"
    REPORTS_DIR: str = "data/reports"
    MODELS_DIR: str = "models"

    # Task Management
    TASK_STATUS_DIR: str = "data/tasks"

    # Model & Training Configurations
    SUPPORTED_MODELS: List[str] = ["random_forest", "xgboost", "lightgbm", "catboost", "logistic_regression"]
    DEFAULT_TEST_SIZE: float = 0.2

    # Pydantic v2 configuration using model_config
    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        extra='ignore' # Allow other env vars without raising errors
    )

# Create a single, globally accessible instance of the settings
settings = Settings()

