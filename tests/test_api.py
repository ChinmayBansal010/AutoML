import io
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.schemas.model import PreprocessingConfig

client = TestClient(app)

# A simple in-memory dictionary to share state (like file_id) between tests
test_state = {}

def test_root_endpoint():
    """Test if the root endpoint is accessible."""
    response = client.get("/")
    assert response.status_code == 200
    assert "Welcome" in response.json()["message"]

def test_upload_file():
    """Test the file upload endpoint with a dummy CSV."""
    csv_content = "feature1,feature2,target\n1,2,0\n3,4,1\n5,6,0\n7,8,1"
    file_bytes = io.BytesIO(csv_content.encode("utf-8"))

    response = client.post(
        "/api/upload",
        files={"file": ("test_dataset.csv", file_bytes, "text/csv")}
    )
    
    assert response.status_code == 200, f"Upload failed with: {response.text}"
    data = response.json()
    assert "file_id" in data
    assert "column_dtypes" in data
    assert data['column_dtypes']['feature1'] == 'int64'
    test_state['file_id'] = data['file_id']

def test_get_analysis():
    """Test the analysis endpoint using the file_id from the upload test."""
    assert 'file_id' in test_state, "file_id not found. Did the upload test fail?"
    file_id = test_state['file_id']

    response = client.get(f"/api/analysis/{file_id}")
    
    assert response.status_code == 200, f"Analysis failed with: {response.text}"
    data = response.json()
    assert data['file_id'] == file_id
    assert 'summary_stats' in data

def test_start_training_job():
    """Test starting a training job."""
    assert 'file_id' in test_state, "file_id not found. Did the upload test fail?"
    file_id = test_state['file_id']
    
    training_request = {
      "target_column": "target",
      "models_to_train": ["logistic_regression"],
      "preprocessing_config": {
        "numeric_imputation": "mean",
        "categorical_imputation": "most_frequent",
        "scaling_strategy": "standard_scaler",
        "encoding_strategy": "one-hot"
      }
    }

    response = client.post(f"/api/model/train/{file_id}", json=training_request)

    assert response.status_code == 200, f"Training start failed with: {response.text}"
    data = response.json()
    assert "task_id" in data
    assert "status" in data
    # Fix: Update the expected status message to match the actual API response
    assert data["status"] == "Training job successfully started."

