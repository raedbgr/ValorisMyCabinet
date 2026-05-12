from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import chat, documents, deadlines, agent, cabinet
from app.services.scheduler import start_scheduler, stop_scheduler
import logging

logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Application starting up...")
    
    # Initialize Firebase
    from app.services.firebase_service import fb_service
    fb_service.initialize()
    
    start_scheduler()
    yield
    # Shutdown: Stop background jobs
    stop_scheduler()

app = FastAPI(title="Valoris API", lifespan=lifespan)

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(chat.router, prefix="/api")
app.include_router(documents.router, prefix="/api")
app.include_router(deadlines.router, prefix="/api")
app.include_router(agent.router, prefix="/api")
app.include_router(cabinet.router, prefix="/api")

from fastapi import Depends
from app.dependencies.auth import get_current_user
from app.services.firebase_service import fb_service
from app.services.ollama_service import ollama_service

@app.get("/api/health")
async def health_check():
    """Comprehensive health check for the entire backend."""
    ollama_alive = await ollama_service.is_alive()
    firebase_alive = fb_service._initialized and fb_service.get_db() is not None
    
    return {
        "status": "ok" if (ollama_alive and firebase_alive) else "degraded",
        "services": {
            "api": "ok",
            "ollama": "ok" if ollama_alive else "down",
            "firebase": "ok" if firebase_alive else "down"
        },
        "project": "Valoris"
    }

@app.get("/api/auth/me")
async def verify_auth(user: dict = Depends(get_current_user)):
    """Test endpoint for Flutter to verify the ID token."""
    return {
        "status": "authenticated",
        "user_id": user.get("uid"),
        "email": user.get("email"),
        "role": user.get("role", "client")
    }