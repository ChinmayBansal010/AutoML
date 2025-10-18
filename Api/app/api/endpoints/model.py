from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from fastapi.responses import FileResponse
from app.schemas.model import TrainingRequest, StatusResponse, TaskResponse, PredictionRequest
from app.services.model_service import ModelService
from app.core.config import settings
import os

router = APIRouter()

@router.post("/train", response_model=TaskResponse)
async def train_model(
    request: TrainingRequest,
    background_tasks: BackgroundTasks,
    model_service: ModelService = Depends()
):
    """
    Starts the asynchronous training job for the selected models.
    """
    try:
        task_id = model_service.start_training_job(request, background_tasks)
        return TaskResponse(
            task_id=task_id, 
            status="queued"
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/status/{task_id}", response_model=StatusResponse)
async def get_training_status(
    task_id: str,
    model_service: ModelService = Depends()
):
    """
    Retrieves the status and results of a specific training job.
    """
    status = model_service.get_job_status(task_id)
    if not status:
        raise HTTPException(status_code=404, detail="Task ID not found.")
    return status


@router.get("/download/{model_id}")
async def download_model(model_id: str):
    """
    Allows downloading of a trained model file.
    """
    try:
        model_path = settings.MODELS_DIR / f"{model_id}.joblib"
        if not os.path.exists(model_path):
            raise HTTPException(status_code=404, detail="Model file not found.")
        return FileResponse(path=model_path, filename=f"{model_id}.joblib", media_type='application/octet-stream')
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/predict")
async def predict(
    request: PredictionRequest,
    service: ModelService = Depends()
):
    """
    Makes a prediction using a trained model.
    """
    try:
        prediction = service.predict(request)
        return {"prediction": prediction}
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

