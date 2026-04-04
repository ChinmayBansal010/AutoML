import firebase_admin
from firebase_admin import credentials, auth
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.core.config import settings
import os

cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_FILE)

try:
    firebase_admin.initialize_app(cred)
except ValueError:
    pass

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token", auto_error=False)


async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Dependency that verifies the Firebase ID token in the Authorization header.
    Returns the decoded token (which contains user info like 'uid', 'email').
    In development mode (ENVIRONMENT=development), allows requests without tokens.
    """
    # Allow unauthenticated requests in development
    environment = os.getenv("ENVIRONMENT", "development")
    if environment == "development" and not token:
        return {"uid": "dev-user", "email": "dev@localhost"}
    
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials: {e}",
            headers={"WWW-Authenticate": "Bearer"},
        )