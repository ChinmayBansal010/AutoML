from fastapi import APIRouter
from app.api.endpoints import upload, analysis, model, auth # Import the new auth module

# Create the main API router that will be included in the FastAPI app instance
api_router = APIRouter()

# Include the routers from the individual endpoint modules.
# - prefix adds a path prefix to all routes in the included router.
# - tags group endpoints in the interactive API documentation.

# New: Authentication and Utility Endpoints
api_router.include_router(auth.router, prefix="/auth", tags=["0. Authentication & Utility"])
api_router.include_router(upload.router, prefix="/upload", tags=["1. File Upload"])
api_router.include_router(analysis.router, prefix="/analysis", tags=["2. Data Analysis"])
api_router.include_router(model.router, prefix="/model", tags=["3. Model Training & Prediction"])
