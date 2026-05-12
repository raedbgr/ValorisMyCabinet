from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.services.firebase_service import fb_service

security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Dependency to verify a Firebase ID token sent in the Authorization header.
    Returns the decoded token (which contains user uid, email, etc.)
    """
    token = credentials.credentials
    decoded_token = await fb_service.verify_token(token)
    
    if not decoded_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token d'authentification invalide ou expiré",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    # decoded_token contains claims like: 'uid', 'email', 'role', etc.
    return decoded_token

async def get_current_accountant(user: dict = Depends(get_current_user)):
    """
    Optional dependency to restrict routes only to accountants.
    Assuming the Flutter app or Firestore assigns a custom claim 'role': 'accountant'
    """
    role = user.get("role", "client")
    if role != "accountant":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé. Réservé aux experts-comptables."
        )
    return user
