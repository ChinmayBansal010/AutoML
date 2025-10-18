from pydantic import BaseModel, Field
from typing import Optional, List, Dict

# Defines the configuration for data preprocessing steps
class PreprocessingConfig(BaseModel):
    numeric_imputation: str = "median"
    categorical_imputation: str = "most_frequent"
    scaling_strategy: str = "standard_scaler"

# Defines the structure of a request to start a training job
class TrainingRequest(BaseModel):
    file_id: str
    target_column: str
    models: List[str]
    test_size: float = Field(0.2, ge=0.1, le=0.5)
    hyperparameter_tuning: bool = False
    preprocessing_config: PreprocessingConfig = Field(default_factory=PreprocessingConfig)

# Defines the structure of a request to predict using a trained model
class PredictionRequest(BaseModel):
    model_id: str
    data: List[dict]

# Defines the structure of a response that returns a task ID
class TaskResponse(BaseModel):
    task_id: str
    status: str

# Defines the result structure for a single trained model
class ModelResult(BaseModel):
    model_id: str
    metrics: Dict
    details: Dict
    plots: Dict

# Defines the status of a background training task, capable of holding multiple model results
class StatusResponse(BaseModel):
    task_id: str
    status: str
    progress: Optional[str] = None
    results: Optional[Dict[str, ModelResult]] = None
    error: Optional[str] = None