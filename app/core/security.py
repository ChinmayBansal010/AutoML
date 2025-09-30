from fastapi import Security, HTTPException, status
from fastapi.security import APIKeyHeader
from app.core.config import settings # Import the central settings instance

# Define the header where the API key is expected
api_key_header = APIKeyHeader(name="X-API-KEY", auto_error=False)

# Use the API_KEY from the central settings object
API_KEY = settings.API_KEY

async def get_api_key(api_key_header: str = Security(api_key_header)):
    """
    Dependency to validate the API key from the request header.
    """
    if api_key_header == API_KEY:
        return api_key_header
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API Key"
        )

