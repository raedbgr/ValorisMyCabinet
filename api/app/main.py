from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import chat, documents, deadlines, agent, cabinet
from app.services.scheduler import start_scheduler, stop_scheduler

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Start background jobs
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

@app.get("/")
async def health_check():
    return {
        "status": "ok",
        "project": "Valoris"
    }

@app.get("/test-ollama")
async def test_ollama():
    from app.services.ollama_service import ollama_service
    alive = await ollama_service.is_alive()
    if not alive:
        return {"status": "❌ Ollama not running"}
    response = await ollama_service.chat(
        messages=[{"role": "user", "content": "say hello in one sentence"}]
    )
    return {"status": "✅ Ollama running", "response": response}