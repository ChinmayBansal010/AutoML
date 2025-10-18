from fastapi import APIRouter, Depends, status
from app.core.security import get_api_key
from typing import Dict

# Create a new router for authentication/utility endpoints
router = APIRouter()

@router.post("/verify-key", 
             status_code=status.HTTP_200_OK,
             response_model=Dict[str, str],
             summary="Verify the provided API Key")
async def verify_api_key(api_key: str = Depends(get_api_key)):
    """
    Validates the API Key provided in the X-API-KEY header.
    
    If the key is valid (matches the backend's settings.API_KEY), 
    it returns a success status (200 OK). 
    If invalid, the `get_api_key` dependency raises a 401 Unauthorized exception.
    """
    # If the execution reaches this point, the key has been validated by the dependency.
    return {"message": "API Key successfully verified."}

@router.get("/status", 
            status_code=status.HTTP_200_OK,
            response_model=Dict[str, str],
            summary="Check API status")
async def api_status():
    """Returns a simple success message to confirm the API is running."""
    return {"status": "ok", "message": "AutoML API is running."}
