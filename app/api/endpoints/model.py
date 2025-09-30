from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends, UploadFile, File, Path
from fastapi.responses import FileResponse
from typing import List

from app.schemas.model import TrainingRequest, TaskResponse, StatusResponse, ModelMetrics
from app.services.model_service import ModelService

router = APIRouter()

@router.post("/train/{file_id}", response_model=TaskResponse)
async def train_model(
    request: TrainingRequest,
    background_tasks: BackgroundTasks,
    file_id: str = Path(..., description="The unique ID of the file to use for training."),
    model_service: ModelService = Depends()
):
    """
    Starts a model training job in the background based on the provided configuration.
    Immediately returns a `task_id` for status tracking.
    """
    try:
        task_id = model_service.start_training_job(file_id, request, background_tasks)
        return {"task_id": task_id, "status": "Training job successfully started."}
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"File with ID '{file_id}' not found.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to start training job: {str(e)}")

@router.get("/status/{task_id}", response_model=StatusResponse)
async def get_training_status(
    task_id: str = Path(..., description="The ID of the training task."),
    model_service: ModelService = Depends()
):
    """
    Checks the status of a background training task. Poll this endpoint after starting a training job.
    """
    status = model_service.get_job_status(task_id)
    if status is None:
        raise HTTPException(status_code=404, detail="Task ID not found.")
    return status

@router.get("/{file_id}/list", response_model=List[ModelMetrics])
async def list_trained_models(
    file_id: str = Path(..., description="The file ID to list trained models for."),
    model_service: ModelService = Depends()
):
    """
    Lists all successfully trained models and their summary metrics for a given `file_id`.
    """
    models = model_service.get_models_for_file(file_id)
    if not models:
        raise HTTPException(status_code=404, detail="No models found for this file ID, or file ID is invalid.")
    return models

@router.post("/predict/{model_id}")
async def predict_with_model(
    model_id: str = Path(..., description="The unique ID of the trained model to use for predictions."),
    file: UploadFile = File(..., description="A file with new data for prediction. Must be Excel or CSV."),
    model_service: ModelService = Depends()
):
    """
    Uses a trained model to make predictions on new data.
    The input file structure must match the data used for training.
    Returns a CSV file with an added 'predictions' column.
    """
    if not file.filename.endswith(('.xlsx', '.xls', '.csv')):
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload an Excel or CSV file.")

    try:
        predictions_path = await model_service.make_predictions(model_id, file)
        return FileResponse(
            path=predictions_path,
            media_type='text/csv',
            filename=f"predictions_{model_id}.csv"
        )
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Model with ID '{model_id}' not found.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@router.get("/report/{model_id}")
async def download_report(
    model_id: str = Path(..., description="The unique ID of the model for which to download the report."),
    model_service: ModelService = Depends()
):
    """
    Downloads a ZIP archive containing the full report for a trained model, including:
    - Serialized model object (.joblib)
    - Final metrics (.json)
    - Diagnostic plots (e.g., confusion matrix, feature importance)
    - Model configuration file (.json)
    """
    try:
        report_path = model_service.create_report_zip(model_id)
        return FileResponse(
            path=report_path,
            media_type='application/zip',
            filename=f"report_{model_id}.zip"
        )
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Report not found. Model ID '{model_id}' may be invalid.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not generate report: {str(e)}")
