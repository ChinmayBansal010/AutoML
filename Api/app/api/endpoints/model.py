from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from app.schemas.model import TrainingRequest, StatusResponse, ModelMetrics
from app.services.model_service import ModelService
import os
import shutil

router = APIRouter()

@router.post("/train", response_model=StatusResponse)
async def train_model(
    request: TrainingRequest,
    background_tasks: BackgroundTasks,
    model_service: ModelService = Depends()
):
    """
    Starts the asynchronous training job for the best model selection.
    """
    try:
        task_id = model_service.start_training_job(
            request.file_id, 
            request, 
            background_tasks
        )
        return StatusResponse(
            task_id=task_id, 
            status="queued", 
            progress=f"Training job started with ID: {task_id}"
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


@router.get("/metrics/{model_id}", response_model=ModelMetrics)
async def get_model_metrics(
    model_id: str,
    model_service: ModelService = Depends()
):
    """
    Retrieves the stored metrics for a completed model.
    NOTE: This endpoint is currently not used, as metrics are returned via /status.
    """
    raise HTTPException(status_code=501, detail="This endpoint is deprecated. Use /status/{task_id} instead.")

@router.get("/report/{model_id}")
async def get_model_report(
    model_id: str
):
    """
    Serves the HTML report for a trained model.
    NOTE: Report generation is currently done client-side. This is a placeholder.
    """
    report_path = os.path.join("REPORTS_DIR", f"{model_id}.html")
    if not os.path.exists(report_path):
        raise HTTPException(status_code=404, detail="Report not found. The client is expected to generate the report from the status response data.")
    
    # In a fully functional system, we would return a FileResponse here.
    return {"message": "Report generation is handled by the client."}
