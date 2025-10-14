from pydantic import BaseModel
from typing import Optional, List, Dict

# Defines the configuration for data preprocessing steps
class PreprocessingConfig(BaseModel):
    numeric_imputation: str = "median"
    categorical_imputation: str = "most_frequent"
    scaling_strategy: str = "standard_scaler"
    encoding_strategy: str = "one-hot"

# Defines the structure of a request to start a training job
class TrainingRequest(BaseModel):
    target_column: str
    models_to_train: List[str]
    preprocessing_config: PreprocessingConfig
    hyperparameter_tuning: bool = False # Add the tuning flag

# Defines the structure of a response that returns a task ID
class TaskResponse(BaseModel):
    task_id: str
    status: str

# Defines the metrics for a single trained model
class ModelMetrics(BaseModel):
    model_id: str
    model_name: str
    file_id: str
    accuracy: float
    precision: float
    recall: float
    f1_score: float
    confusion_matrix: List[List[int]]
    report_url: str

# Defines the status of a background task
class StatusResponse(BaseModel):
    task_id: str
    status: str
    progress: Optional[str] = None
    result: Optional[ModelMetrics] = None

