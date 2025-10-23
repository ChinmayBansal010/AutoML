from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

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

# --- UPDATED SCHEMAS ---

# Specific schema for the confusion matrix plot data
class ConfusionMatrixPlot(BaseModel):
    labels: List[str]
    matrix: List[List[int]]

# Specific schema for all plot data
class PlotData(BaseModel):
    confusion_matrix: ConfusionMatrixPlot
    shap_summary: Optional[Dict[str, Any]] = None # Kept as None since it was removed

# Defines the result structure for a single trained model
class ModelResult(BaseModel):
    model_id: str
    metrics: Dict
    details: Dict
    plots: PlotData  # <-- Updated from simple Dict

# Defines the status of a background training task
class StatusResponse(BaseModel):
    task_id: str
    status: str
    progress: Optional[str] = None
    results: Optional[Dict[str, ModelResult]] = None
    error: Optional[str] = None
