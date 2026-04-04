from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional

class PreprocessingConfig(BaseModel):
    """
    Configuration for data preprocessing steps.
    """
    numeric_imputation: str = Field(default="mean", description="Strategy for handling missing numeric values: mean, median, most_frequent")
    categorical_imputation: str = Field(default="most_frequent", description="Strategy for handling missing categorical values: most_frequent, constant")
    scaling_strategy: str = Field(default="standard_scaler", description="Scaling strategy for numeric features: standard_scaler, minmax")
    remove_outliers: bool = Field(default=False, description="Whether to remove outliers")

    def dict(self):
        return {
            "numeric_imputation": self.numeric_imputation,
            "categorical_imputation": self.categorical_imputation,
            "scaling_strategy": self.scaling_strategy,
            "remove_outliers": self.remove_outliers,
        }


class TrainingRequest(BaseModel):
    """
    Schema for requesting model training with selected models and configuration.
    """
    models: List[str] = Field(..., description="List of model types to train")
    target_column: str = Field(..., description="Target column for training")
    test_size: float = Field(default=0.2, description="Test set size ratio")
    file_id: str = Field(..., description="File ID for the training dataset")
    preprocessing_config: PreprocessingConfig = Field(default_factory=PreprocessingConfig, description="Preprocessing configuration")
    hyperparameter_tuning: bool = Field(default=False, description="Whether to perform hyperparameter tuning")


class TaskResponse(BaseModel):
    """
    Response schema for task creation with task ID and status.
    """
    task_id: str = Field(..., description="Unique identifier for the training task")
    status: str = Field(..., description="Current status of the task")


class StatusResponse(BaseModel):
    """
    Response schema for training status with results and metrics.
    """
    task_id: str = Field(..., description="Unique identifier for the training task")
    status: str = Field(..., description="Current status of the task")
    progress: Optional[str] = Field(None, description="Progress message")
    results: Optional[Dict[str, Any]] = Field(None, description="Training results")
    error: Optional[str] = Field(None, description="Error message if training failed")


class ModelResult(BaseModel):
    """
    Schema for individual model training results.
    """
    model_id: str = Field(..., description="URL to the stored model file")
    preprocessor_url: str = Field(..., description="URL to the stored preprocessor file")
    metrics: Dict[str, Any] = Field(..., description="Model performance metrics")
    plots: Dict[str, Any] = Field(..., description="Visualization data")
    details: Dict[str, Any] = Field(..., description="Model details and parameters")


class PredictionRequest(BaseModel):
    """
    Schema for prediction requests with model ID and input features.
    """
    model_id: str = Field(..., description="ID of the trained model")
    data: Dict[str, Any] = Field(..., description="Input data for prediction")


class PredictionResponse(BaseModel):
    """
    Response schema for predictions.
    """
    predictions: List[Any] = Field(..., description="Predicted values or classes")