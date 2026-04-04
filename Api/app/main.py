import os
from dotenv import load_dotenv
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from app.api.router import api_router
from app.core.config import settings

# Load environment variables from .env file
load_dotenv()

# --- Rate Limiting Imports ---
from app.limiter import limiter
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url="/api/v1/openapi.json"
)

# --- Rate Limiting Setup ---
app.state.limiter = limiter
app.add_middleware(SlowAPIMiddleware)

@app.exception_handler(RateLimitExceeded)
async def rate_limit_exceeded_callback(request: Request, exc: RateLimitExceeded):
    return JSONResponse(
        status_code=429,
        content={"detail": f"Rate limit exceeded: {exc.detail}"}
    )
# --- End Rate Limiting ---

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- REMOVED GLOBAL LIMIT ---
# The router no longer has a 'dependencies' argument.
# We will apply limits to specific endpoints instead.
app.include_router(
    api_router,
    prefix="/api"
)
# --- END REMOVED GLOBAL LIMIT ---

@app.get("/")
def read_root():
    """ Root endpoint for health checks. """
    return {"message": f"Welcome to {settings.PROJECT_NAME}"}

