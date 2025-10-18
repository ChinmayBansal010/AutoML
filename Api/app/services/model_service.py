import os
import uuid
import joblib
import pandas as pd
import shutil
import json
import traceback
from fastapi import BackgroundTasks, Depends
from pathlib import Path

from app.core.config import settings
from app.schemas.model import TrainingRequest, StatusResponse, ModelResult
from app.pipelines.training_pipeline import run_training_pipeline
from app.services.file_service import FileService

class ModelService:
    def __init__(self, file_service: FileService = Depends(FileService)):
        self.file_service = file_service

    def start_training_job(self, request: TrainingRequest, background_tasks: BackgroundTasks) -> str:
        task_id = str(uuid.uuid4())
        status_file = settings.TASK_STATUS_DIR / f"{task_id}.json"
        
        initial_status = StatusResponse(
            task_id=task_id,
            status="queued",
            progress="Training job has been queued."
        )
        with open(status_file, 'w') as f:
            json.dump(initial_status.dict(), f, indent=4)

        background_tasks.add_task(self._run_training_in_background, task_id, request)
        return task_id

    def get_job_status(self, task_id: str) -> dict:
        status_file = settings.TASK_STATUS_DIR / f"{task_id}.json"
        if not status_file.exists():
            return StatusResponse(task_id=task_id, status="not_found", error="Task ID not found.").dict()
        with open(status_file, 'r') as f:
            return json.load(f)

    def _run_training_in_background(self, task_id: str, request: TrainingRequest):
        status_file = settings.TASK_STATUS_DIR / f"{task_id}.json"

        def update_status(status: str, progress: str = None, results: dict = None, error: str = None):
            with open(status_file, 'r+') as f:
                data = json.load(f)
                data['status'] = status
                if progress: data['progress'] = progress
                if results: data['results'] = results
                if error: data['error'] = error
                f.seek(0)
                json.dump(data, f, indent=4)
                f.truncate()

        try:
            update_status("running", progress="Loading data...")
            df = self.file_service.get_dataframe(request.file_id)
            if df is None:
                raise FileNotFoundError(f"Could not load dataframe for file_id: {request.file_id}")

            all_results = {}
            total_models = len(request.models)
            
            for i, model_name in enumerate(request.models):
                progress_message = f"({i+1}/{total_models}) Training {model_name}..."
                update_status("running", progress=progress_message)
                
                # The pipeline now returns a perfectly clean dictionary
                pipeline_result = run_training_pipeline(
                    df=df.copy(),
                    target_column=request.target_column,
                    model_name=model_name,
                    preprocessing_config=request.preprocessing_config,
                    test_size=request.test_size,
                    plots_dir=str(settings.REPORTS_DIR),
                    hyperparameter_tuning=request.hyperparameter_tuning
                )
                
                model_object = pipeline_result.pop("model") # Remove model object before serialization
                model_id = f"{task_id}_{model_name}"
                model_path = settings.MODELS_DIR / f"{model_id}.joblib"
                joblib.dump(model_object, model_path)
                
                # The rest of the pipeline_result is already a clean dict
                model_result_obj = ModelResult(model_id=model_id, **pipeline_result)
                all_results[model_name] = model_result_obj.dict()

            update_status("completed", progress="All models trained successfully.", results=all_results)

        except Exception as e:
            error_details = traceback.format_exc()
            print(f"TRAINING FAILED for task {task_id}:\n{error_details}")
            update_status("failed", progress=f"Error: {str(e)}", error=str(e))

