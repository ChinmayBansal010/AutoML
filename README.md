This is a comprehensive project spanning a Python **FastAPI backend** and a Flutter **mobile/web frontend** for a machine learning automation service. A strong README will highlight the full stack and the ML capabilities.

Here is a structured [`README.md`](http://README.md) file for your project:

---

# AutoML: Automated Machine Learning Platform

🛡️ **Full-Stack ML Platform** | 🚀 **FastAPI Backend** | 💙 **Flutter Frontend**

This project provides a complete, end-to-end solution for automating data analysis and machine learning model training. Users can upload their datasets via a sleek mobile/web app, analyze the data, trigger automated model training, and retrieve model performance results—all through a robust, containerized API.

## 🌟 Features

### Frontend (Flutter)

* **Cross-Platform UI:** Modern and responsive interface for both **Mobile (Android/iOS)** and **Web**.
    
* **Multi-Step Job Creation:** A clear, guided process for uploading data, setting job parameters, and tracking progress.
    
* **Live Job Status:** Real-time feedback on data processing and model training progress.
    

### Backend (FastAPI & Python ML)

* **High-Performance API:** Built with **FastAPI** for fast, asynchronous request handling.
    
* **Automated Data Analysis:** Endpoints for data profiling, visualization (plots saved as images), and preliminary analysis ([`analysis_service.py`](https://github.com/ChinmayBansal010/AutoML/blob/main/Api/app/services/analysis_service.py)).
    
* **ML Pipeline:** Seamless execution of data preprocessing ([`data_pipeline.py`](https://github.com/ChinmayBansal010/AutoML/blob/main/Api/app/pipelines/data_pipeline.py)) and model training ([`training_pipeline.py`](https://github.com/ChinmayBansal010/AutoML/blob/main/Api/app/pipelines/training_pipeline.py)) using industry-standard Python ML libraries.
    
* **Containerized Environment:** Packaged with **Docker** for consistent, reproducible deployments.
    

## 🛠️ Tech Stack

| **Component** | **Technology** | **Role** |
| --- | --- | --- |
| **Backend API** | Python, FastAPI | Core service logic, API endpoints |
| **Machine Learning** | Pandas, Scikit-learn, AutoGluon (or similar) | Data Processing and Model Training |
| **Frontend** | Flutter / Dart | Cross-platform Mobile and Web UI |
| **Deployment** | Docker, Render | Containerization and Cloud Hosting |
| **Storage** | Cloudflare R2 / AWS S3 (Planned) | **Persistent** storage for datasets and trained models |

## 🚀 Getting Started

Follow these steps to set up the project locally for development.

### Prerequisites

You need the following installed on your machine:

* **Docker & Docker Compose**
    
* **Python 3.10+** (for local backend development)
    
* **Flutter SDK** (for local frontend development)
    

### 1\. Backend Setup (API)

The backend is fully containerized using Docker, simplifying the setup process.

1. **Navigate to the API directory:**
    
    ```bash
    cd Api
    ```
    
2. **Create Environment File:** Copy the example environment file. You will need to replace the placeholder values.
    
    ```bash
    cp .env.example .env
    # NOTE: Update the secret keys and storage credentials in the new .env file
    ```
    
3. **Build and Run with Docker Compose:** This command builds the Docker image and starts the service.
    
    ```bash
    docker-compose up --build
    ```
    
    The API will be running at [`http://localhost:8000`](http://localhost:8000). You can view the interactive documentation at [`http://localhost:8000/docs`](http://localhost:8000/docs).
    

### 2\. Frontend Setup (Flutter)

1. **Navigate to the Flutter directory:**
    
    ```ini
    cd ../automl
    ```
    
2. **Install Dependencies:**
    
    ```bash
    flutter pub get
    ```
    
3. **Configure API URL:** Before running, you must ensure the Flutter app points to your local or deployed API. Check `lib/core/api_service.dart` and confirm the `_baseUrl` points to your backend.
    
4. **Run the App:**
    
    ```bash
    flutter run -d web # or choose an emulator
    ```
    

## 📂 Project Structure

The repository is split into two main components:

```ini
├── Api/                          # FastAPI Backend & Docker Setup
│   ├── app/                      # Python application source code
│   │   ├── api/                  # API router and endpoints (model.py, upload.py)
│   │   ├── pipelines/            # Core ML logic (data_pipeline.py, training_pipeline.py)
│   │   ├── services/             # Application services (file_service.py, analysis_service.py)
│   ├── Dockerfile                # Defines the API container image
│   ├── requirements.txt          # Python dependencies
│   └── render.yaml               # Infrastructure-as-Code for Render deployment
│
└── automl/                       # Flutter Cross-Platform Frontend
    ├── lib/                      # Dart source code
    │   ├── core/                 # API service, Firebase setup
    │   ├── data/models/          # Data models (JSON serialization)
    │   └── screens/              # UI pages (dashboard, job creation steps, results)
    └── pubspec.yaml              # Flutter dependencies
```

## ☁️ Deployment

The project is designed for one-click deployment to **Render** using **Docker** and the `render.yaml` Blueprint file located in the `Api/` directory.

### Persistent Storage Note

To maintain **free** hosting, this project **replaces Render's Persistent Disk** (a paid feature) with **Cloudflare R2** for storing user-uploaded files, models, and plots.

* **Render:** Hosts the stateless `automl-api` web service (Free Tier).
    
* **Cloudflare R2:** Provides free, persistent object storage (10GB free tier) for files.
    
    * The configuration and API integration happen via Environment Variables (`R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, etc.) defined in the Render service settings.
        

## 🤝 Contributing

Contributions are welcome! If you have suggestions or find bugs, please open an issue or submit a pull request.

1. **Fork** the project.
    
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
    
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
    
4. Push to the branch (`git push origin feature/AmazingFeature`).
    
5. Open a **Pull Request**.
    

## 📄 License

Distributed under the **MIT License**. See the repository's `LICENSE` file for more information.
