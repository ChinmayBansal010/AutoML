from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from app.schemas.model import TrainingRequest, StatusResponse, TaskResponse, PredictionRequest, PredictionResponse
from app.services.model_service import ModelService
from app.core.security import get_current_user
from app.limiter import limiter
from urllib.parse import unquote

router = APIRouter()

@limiter.limit("5/hour")
@router.post(
    "/train",
    response_model=TaskResponse,
    status_code=202,
    dependencies=[Depends(get_current_user)]
)
async def train_model(
    request: Request,
    train_request: TrainingRequest,
    background_tasks: BackgroundTasks,
    model_service: ModelService = Depends(),
):
    """
    Starts the asynchronous training job for the selected models.
    """
    try:
        task_id = model_service.start_training_job(train_request, background_tasks)
        return TaskResponse(
            task_id=task_id, 
            status="queued"
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/status/{task_id}", response_model=StatusResponse, dependencies=[Depends(get_current_user)])
async def get_training_status(
    task_id: str,
    model_service: ModelService = Depends(),
):
    """
    Retrieves the status and results of a specific training job.
    """
    status = model_service.get_job_status(task_id)
    if not status:
        raise HTTPException(status_code=404, detail="Task ID not found.")
    return status


@router.get("/download/{model_id:path}")
async def download_model(model_id: str):
    """
    Allows downloading of a trained model file from Vercel Blob.
    Model files are stored publicly on Vercel Blob, so authentication is not required.
    """
    try:
        # URL decode the model_id (in case it contains special characters)
        decoded_model_id = unquote(model_id)
        
        # Model ID from Vercel Blob is already a full URL
        if decoded_model_id.startswith("https://"):
            return {"download_url": decoded_model_id}
        else:
            # If it's just a UUID/filename, construct the blob URL
            return {"download_url": f"https://blob.vercel-storage.com/{decoded_model_id}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/predict", response_model=PredictionResponse, dependencies=[Depends(get_current_user)])
async def predict(
    request: PredictionRequest,
    service: ModelService = Depends(),
):
    """
    Makes a prediction using a trained model.
    """
    try:
        prediction_response = service.predict(request)
        return prediction_response
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

