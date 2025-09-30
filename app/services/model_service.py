import os
import uuid
import joblib
import zipfile
import pandas as pd
import shutil
from fastapi import UploadFile, BackgroundTasks, Depends

from app.core.config import settings
from app.schemas.model import TrainingRequest, StatusResponse, ModelMetrics
from app.pipelines.training_pipeline import run_training_pipeline
from app.services.file_service import FileService

# This dictionary will act as our in-memory "database" for task statuses.
TASK_STATUS_STORE = {}

class ModelService:
    def __init__(self, file_service: FileService = Depends(FileService)):
        self.file_service = file_service
        self.task_store = TASK_STATUS_STORE

    def start_training_job(
        self, file_id: str, request: TrainingRequest, background_tasks: BackgroundTasks
    ) -> str:
        """Adds the training process to background tasks."""
        task_id = str(uuid.uuid4())
        
        self.task_store[task_id] = StatusResponse(
            task_id=task_id,
            status="starting",
            progress="Training job has been queued."
        )

        background_tasks.add_task(
            self._run_training_in_background, task_id, file_id, request
        )
        return task_id

    def get_job_status(self, task_id: str) -> StatusResponse | None:
        """Retrieves the status of a training job."""
        return self.task_store.get(task_id)

    def _run_training_in_background(self, task_id: str, file_id: str, request: TrainingRequest):
        """
        The actual training logic that runs in the background.
        - Trains all requested models.
        - Optionally performs hyperparameter tuning.
        - Compares models based on accuracy and saves only the best one.
        """
        try:
            self.task_store[task_id].status = "running"
            self.task_store[task_id].progress = "Loading data..."
            
            df = self.file_service.get_dataframe(file_id)
            if df is None:
                raise FileNotFoundError("Could not load dataframe for training.")

            best_model_results = None
            best_model_name = None
            best_accuracy = -1.0
            
            temp_dirs = []

            # --- NEW: Loop through all requested models ---
            for i, model_name in enumerate(request.models_to_train):
                progress_message = f"({i+1}/{len(request.models_to_train)}) Training {model_name}..."
                self.task_store[task_id].progress = progress_message
                print(progress_message) # Also print to server console

                temp_model_dir = os.path.join(settings.MODELS_DIR, "temp", str(uuid.uuid4()))
                os.makedirs(temp_model_dir, exist_ok=True)
                temp_dirs.append(temp_model_dir)
                
                current_results = run_training_pipeline(
                    df=df,
                    target_column=request.target_column,
                    model_name=model_name,
                    preprocessing_config=request.preprocessing_config,
                    test_size=settings.DEFAULT_TEST_SIZE,
                    plots_dir=temp_model_dir,
                    hyperparameter_tuning=request.hyperparameter_tuning
                )

                current_accuracy = current_results["metrics"]["accuracy"]
                print(f"Finished training {model_name} with accuracy: {current_accuracy:.4f}")

                # --- NEW: Compare with the best model so far ---
                if current_accuracy > best_accuracy:
                    print(f"New best model found: {model_name} (Accuracy: {current_accuracy:.4f})")
                    best_accuracy = current_accuracy
                    best_model_results = current_results
                    best_model_name = model_name
                    best_model_results["temp_dir"] = temp_model_dir

            if not best_model_results:
                raise RuntimeError("No models were trained successfully.")

            # --- NEW: Finalize and save ONLY the best model ---
            self.task_store[task_id].progress = f"Saving best model ({best_model_name}) with accuracy: {best_accuracy:.4f}"
            
            model_id = str(uuid.uuid4())
            final_model_dir = os.path.join(settings.MODELS_DIR, model_id)
            
            # Move the best model's directory to its final location
            shutil.move(best_model_results["temp_dir"], final_model_dir)
            joblib.dump(best_model_results["model"], os.path.join(final_model_dir, "model.joblib"))

            # Clean up other temporary directories
            for temp_dir in temp_dirs:
                if os.path.exists(temp_dir):
                    shutil.rmtree(temp_dir)

            final_metrics = ModelMetrics(
                model_id=model_id,
                model_name=best_model_name,
                file_id=file_id,
                **best_model_results["metrics"],
                report_url=f"/api/model/report/{model_id}"
            )
            
            self.task_store[task_id] = StatusResponse(
                task_id=task_id,
                status="complete",
                progress="Training finished successfully. Best model saved.",
                result=final_metrics
            )

        except Exception as e:
            import traceback
            error_details = traceback.format_exc()
            print(f"TRAINING FAILED for task {task_id}:\n{error_details}")
            
            self.task_store[task_id] = StatusResponse(
                task_id=task_id,
                status="failed",
                progress=f"Error: {str(e)}",
                result=None
            )

