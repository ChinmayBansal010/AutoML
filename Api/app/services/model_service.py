import io
import uuid
import joblib
import pandas as pd
import json
import traceback
from fastapi import BackgroundTasks, Depends
from vercel_kv import KV      # <-- 1. Import the KV *class*
from vercel_blob import put # <-- Import Vercel Blob 'put'

from app.core.config import settings # <-- Import our settings
from app.schemas.model import TrainingRequest, StatusResponse, ModelResult
from app.pipelines.training_pipeline import run_training_pipeline
from app.services.file_service import FileService

class ModelService:
    def __init__(self, file_service: FileService = Depends(FileService)):
        self.file_service = file_service
        # 2. Create a KV instance from the REDIS_URL in your settings
        self.kv = KV.from_url(settings.REDIS_URL) 

    def start_training_job(self, request: TrainingRequest, background_tasks: BackgroundTasks) -> str:
        task_id = str(uuid.uuid4())
        task_key = f"task:{task_id}" # This is the key we will use in Vercel KV
        
        initial_status = StatusResponse(
            task_id=task_id,
            status="queued",
            progress="Training job has been queued."
        )
        
        # 3. Use self.kv to set the status
        self.kv.set(task_key, json.dumps(initial_status.dict()), ex=86400) # 24h expiration

        background_tasks.add_task(self._run_training_in_background, task_id, request)
        return task_id

    def get_job_status(self, task_id: str) -> dict:
        task_key = f"task:{task_id}"
        
        # 4. Use self.kv to get the status
        status_data = self.kv.get(task_key)
        
        if not status_data:
            return StatusResponse(task_id=task_id, status="not_found", error="Task ID not found.").dict()
        
        # Vercel KV returns the JSON string, so we parse it
        return json.loads(status_data)

    def _run_training_in_background(self, task_id: str, request: TrainingRequest):
        task_key = f"task:{task_id}"

        def update_status(status: str, progress: str = None, results: dict = None, error: str = None):
            # Get current data, update it, and set it back in Vercel KV
            try:
                # 5. Use self.kv everywhere
                current_data_str = self.kv.get(task_key)
                if not current_data_str:
                    data = StatusResponse(task_id=task_id, status=status).dict()
                else:
                    data = json.loads(current_data_str)
                
                data['status'] = status
                if progress: data['progress'] = progress
                if results: data['results'] = results
                if error: data['error'] = error
                
                # Set the updated status back into Vercel KV
                self.kv.set(task_key, json.dumps(data), ex=86400) # Reset 24h expiration
            
            except Exception as e:
                print(f"CRITICAL: Failed to update status for task {task_id}: {e}")

        try:
            update_status("running", progress="Loading data...")
            # This part already works, as file_service reads from a URL
            df = self.file_service.get_dataframe(request.file_id)
            if df is None:
                raise FileNotFoundError(f"Could not load dataframe for file_id: {request.file_id}")

            all_results = {}
            total_models = len(request.models)
            
            for i, model_name in enumerate(request.models):
                progress_message = f"({i+1}/{total_models}) Training {model_name}..."
                update_status("running", progress=progress_message)
                
                # ------------------------------------------------------------------
                pipeline_result = run_training_pipeline(
                    df=df.copy(),
                    target_column=request.target_column,
                    model_name=model_name,
                    preprocessing_config=request.preprocessing_config,
                    test_size=request.test_size,
                    # plots_dir=...  <-- REMOVED!
                    hyperparameter_tuning=request.hyperparameter_tuning
                )
                
                model_object = pipeline_result.pop("model") # Remove model object for serialization
                
                # 7. --- VERCEL BLOB: SAVE MODEL ---
                model_filename = f"{task_id}_{model_name}.joblib"
                
                # 7a. Create an in-memory buffer
                model_buffer = io.BytesIO()
                
                # 7b. Save the model to the in-memory buffer
                joblib.dump(model_object, model_buffer)
                
                # 7c. Reset buffer's position
                model_buffer.seek(0)
                
                # 7d. Upload the model to Vercel Blob
                blob_result = put(
                    f"models/{model_filename}", # Path in Vercel Blob
                    model_buffer.getvalue(),    # Get bytes from buffer
                    options={'access': 'public', 'add_random_suffix': False}
                )
                
                # 7e. Get the public URL of the saved model
                model_url = blob_result['url']
                # --- END VERCEL BLOB ---
                
                
                # 8. Use the new model_url as the model_id
                model_result_obj = ModelResult(model_id=model_url, **pipeline_result)
                all_results[model_name] = model_result_obj.dict()

            update_status("completed", progress="All models trained successfully.", results=all_results)

        except Exception as e:
            error_details = traceback.format_exc()
            print(f"TRAINING FAILED for task {task_id}:\n{error_details}")
            update_status("failed", progress=f"Error: {str(e)}", error=str(e))
