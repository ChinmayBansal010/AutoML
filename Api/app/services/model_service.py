import io
import uuid
import joblib
import pandas as pd
import numpy as np
import json
import traceback
import requests
import re
from fastapi import BackgroundTasks, Depends, HTTPException
from vercel_blob import put
from app.core.config import settings
from app.cache import cache
from app.schemas.model import (
    TrainingRequest,
    StatusResponse,
    ModelResult,
    PredictionRequest,
    PredictionResponse
)
from app.pipelines.training_pipeline import run_training_pipeline
from app.services.file_service import FileService

model_cache = {}
preprocessor_cache = {}

class ModelService:
    def __init__(self, file_service: FileService = Depends(FileService)):
        self.file_service = file_service
        # Use in-memory cache for job status tracking
        self.kv = cache

    def start_training_job(self, request: TrainingRequest, background_tasks: BackgroundTasks) -> str:
        task_id = str(uuid.uuid4())
        task_key = f"task:{task_id}"
        
        initial_status = StatusResponse(
            task_id=task_id,
            status="queued",
            progress="Training job has been queued."
        )
        
        self.kv.set(task_key, json.dumps(initial_status.dict()), ex=86400)
        background_tasks.add_task(self._run_training_in_background, task_id, request)
        return task_id

    def get_job_status(self, task_id: str) -> dict:
        task_key = f"task:{task_id}"
        status_data = self.kv.get(task_key)
        
        if not status_data:
            return StatusResponse(task_id=task_id, status="not_found", error="Task ID not found.").dict()
        
        return json.loads(status_data)

    def _run_training_in_background(self, task_id: str, request: TrainingRequest):
        task_key = f"task:{task_id}"

        def update_status(status: str, progress: str = None, results: dict = None, error: str = None):
            try:
                current_data_str = self.kv.get(task_key)
                if not current_data_str:
                    data = StatusResponse(task_id=task_id, status=status).dict()
                else:
                    data = json.loads(current_data_str)
                
                data['status'] = status
                if progress: data['progress'] = progress
                if results: data['results'] = results
                if error: data['error'] = error
                
                self.kv.set(task_key, json.dumps(data), ex=86400)
            
            except Exception as e:
                print(f"CRITICAL: Failed to update status for task {task_id}: {e}")

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
                
                pipeline_result = run_training_pipeline(
                    df=df.copy(),
                    target_column=request.target_column,
                    model_name=model_name,
                    preprocessing_config=request.preprocessing_config,
                    test_size=request.test_size,
                    hyperparameter_tuning=request.hyperparameter_tuning
                )
                
                model_object = pipeline_result.pop("model")
                preprocessor_object = pipeline_result.pop("preprocessor")
                
                model_filename = f"{task_id}_{model_name}.joblib"
                model_buffer = io.BytesIO()
                joblib.dump(model_object, model_buffer)
                model_buffer.seek(0)
                model_blob_result = put(
                    f"models/{model_filename}", model_buffer.getvalue(),
                    options={'access': 'public', 'add_random_suffix': False}
                )
                model_url = model_blob_result['url']

                preprocessor_filename = f"{task_id}_{model_name}_preprocessor.joblib"
                preprocessor_buffer = io.BytesIO()
                joblib.dump(preprocessor_object, preprocessor_buffer)
                preprocessor_buffer.seek(0)
                preprocessor_blob_result = put(
                    f"preprocessors/{preprocessor_filename}", preprocessor_buffer.getvalue(),
                    options={'access': 'public', 'add_random_suffix': False}
                )
                preprocessor_url = preprocessor_blob_result['url']
                
                model_result_obj = ModelResult(
                    model_id=model_url,
                    preprocessor_url=preprocessor_url,
                    **pipeline_result
                )
                all_results[model_name] = model_result_obj.dict()

            update_status("completed", progress="All models trained successfully.", results=all_results)

        except Exception as e:
            error_details = traceback.format_exc()
            print(f"TRAINING FAILED for task {task_id}:\n{error_details}")
            update_status("failed", progress=f"Error: {str(e)}", error=str(e))

    def predict(self, request: PredictionRequest) -> PredictionResponse:
        model_url = request.model_id
        preprocessor_url = model_url.replace("models/", "preprocessors/").replace(".joblib", "_preprocessor.joblib")

        try:
            if model_url in model_cache:
                model = model_cache[model_url]
            else:
                print(f"Downloading model from: {model_url}")
                response_model = requests.get(model_url, stream=True)
                response_model.raise_for_status()
                model_buffer = io.BytesIO(response_model.content)
                model = joblib.load(model_buffer)
                model_cache[model_url] = model
                print(f"Model {model_url} loaded and cached.")

            if preprocessor_url in preprocessor_cache:
                preprocessor = preprocessor_cache[preprocessor_url]
            else:
                print(f"Downloading preprocessor from: {preprocessor_url}")
                response_prep = requests.get(preprocessor_url, stream=True)
                response_prep.raise_for_status()
                preprocessor_buffer = io.BytesIO(response_prep.content)
                preprocessor = joblib.load(preprocessor_buffer)
                preprocessor_cache[preprocessor_url] = preprocessor
                print(f"Preprocessor {preprocessor_url} loaded and cached.")

            input_df = pd.DataFrame(request.data)

            try:
                preprocessor.set_output(transform="pandas") 
            except AttributeError:
                 pass
            
            input_df_processed = preprocessor.transform(input_df)
            input_df_processed = self._sanitize_feature_names(input_df_processed).astype(np.float64) 
            
            predictions = model.predict(input_df_processed)
            prediction_list = predictions.tolist()

            return PredictionResponse(predictions=prediction_list)

        except requests.exceptions.RequestException as e:
            failed_url = model_url if e.request.url == model_url else preprocessor_url
            raise HTTPException(status_code=404, detail=f"Could not download artifact from {failed_url}: {e}")
        except Exception as e:
            print(f"Prediction failed for model {model_url}:\n{traceback.format_exc()}")
            raise HTTPException(status_code=500, detail=f"Prediction failed: {e}")

    def _sanitize_feature_names(self, df: pd.DataFrame) -> pd.DataFrame:
        new_columns = {}
        for col in df.columns:
            sanitized_col = re.sub(r"[^A-Za-z0-9_]+", "_", str(col))
            if re.match(r"^\d", sanitized_col):
                sanitized_col = f"col_{sanitized_col}"
            new_columns[col] = sanitized_col
        return df.rename(columns=new_columns)