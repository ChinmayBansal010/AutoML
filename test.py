import requests
import time
import sys
import os

# Configuration
BASE_URL = "http://127.0.0.1:8000"
API_KEY = "873a0e1a4e6630cb43fa875b1770515c454aca44a15f59de03ff32e502509e74873a0e1a4e6630cb43fa875b1770515c454aca44a15f59de03ff32e502509e74" # Make sure this matches your .env file
HEADERS = {"X-API-Key": API_KEY}

def upload_dataset(file_path: str) -> str | None:
    """Uploads the dataset and returns the file_id."""
    print(f"Uploading dataset from: {file_path}...")
    try:
        with open(file_path, "rb") as f:
            response = requests.post(
                f"{BASE_URL}/api/upload",
                files={"file": (os.path.basename(file_path), f)},
                headers=HEADERS
            )
            response.raise_for_status()
            data = response.json()
            print(f"✅ Upload successful. File ID: {data['file_id']}")
            return data["file_id"]
    except requests.exceptions.RequestException as e:
        print(f"❌ Upload failed: {e}")
        print(f"Server response: {e.response.text if e.response else 'No response'}")
        return None

def start_training(file_id: str) -> str | None:
    """Starts the training job and returns the task_id."""
    print(f"\nStarting training job for file ID: {file_id}...")
    
    # --- NEW: Define the request to train ALL models with tuning enabled ---
    training_request = {
        "target_column": "target",
        # Request all supported models for a competition
        "models_to_train": ["logistic_regression", "random_forest", "lightgbm"], # Using a subset for speed
        "hyperparameter_tuning": False, # Enable tuning
        "preprocessing_config": {
            "numeric_imputation": "mean",
            "categorical_imputation": "most_frequent",
            "scaling_strategy": "standard_scaler",
            "encoding_strategy": "one-hot"
        }
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/model/train/{file_id}",
            json=training_request,
            headers=HEADERS
        )
        response.raise_for_status()
        data = response.json()
        print(f"✅ Training job started. Task ID: {data['task_id']}")
        return data["task_id"]
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to start training: {e}")
        print(f"Server response: {e.response.text if e.response else 'No response'}")
        return None

def poll_status(task_id: str):
    """Polls the status of the training task until completion."""
    print(f"\nPolling for results for task ID: {task_id} (checking every 5 seconds)...")
    while True:
        try:
            response = requests.get(f"{BASE_URL}/api/model/status/{task_id}", headers=HEADERS)
            response.raise_for_status()
            data = response.json()
            
            status = data.get("status")
            progress = data.get("progress")

            print(f"  - Status: {status} | Message: {progress}")

            if status == "complete":
                print("\n🎉 Training complete!")
                print("Final Results:")
                print(data)
                break
            elif status == "failed":
                print("\n❌ Training failed.")
                print("Error Details:")
                print(data)
                break
            
            time.sleep(5)
        except requests.exceptions.RequestException as e:
            print(f"❌ Error polling status: {e}")
            break

def main(file_path: str):
    file_id = upload_dataset(file_path)
    if file_id:
        task_id = start_training(file_id)
        if task_id:
            poll_status(task_id)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python api_client.py <path_to_csv_file>")
        sys.exit(1)
    
    csv_file_path = sys.argv[1]
    if not os.path.exists(csv_file_path):
        print(f"Error: File not found at '{csv_file_path}'")
        sys.exit(1)
        
    main(csv_file_path)

