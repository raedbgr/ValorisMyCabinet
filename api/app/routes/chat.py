from fastapi import APIRouter
from app.models.schemas import ChatRequest
from app.services.ollama_service import ollama_service

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("")
async def chat(request: ChatRequest):
    system_prompt = (
        f"Tu es un assistant comptable virtuel pour le cabinet Valoris. "
        f"Tu aides {request.client_name} à comprendre ses obligations fiscales "
        f"en Tunisie. Tu réponds en français, de manière claire et concise. "
        f"Tu ne réponds qu'aux questions liées à la comptabilité, "
        f"fiscalité, et documents administratifs. "
        f"Si la question est hors sujet, dis poliment que tu ne peux "
        f"pas aider avec ça."
    )

    # Convert Pydantic Message objects to list of dicts
    messages = [{"role": m.role, "content": m.content} for m in request.messages]

    response = await ollama_service.chat(messages, system_prompt)

    return {"reply": response}
