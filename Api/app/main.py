from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware
from app.api.router import api_router
from app.core.config import settings
import os

# Create necessary directories on startup
os.makedirs(settings.UPLOADS_DIR, exist_ok=True)
os.makedirs(settings.REPORTS_DIR, exist_ok=True)
os.makedirs(settings.MODELS_DIR, exist_ok=True)
os.makedirs(settings.TASK_STATUS_DIR, exist_ok=True)


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url="/api/openapi.json"
)

# CORS (Cross-Origin Resource Sharing)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

# Include the main API router
app.include_router(api_router, prefix="/api")

@app.get("/")
def read_root():
    """
    Root endpoint providing a welcome message.
    """
    return {"message": f"Welcome to the {settings.PROJECT_NAME}! Visit /docs for documentation."}

