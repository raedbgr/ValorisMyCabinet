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


from app.models.schemas import FeedbackRequest
from app.services.firebase_service import fb_service
from datetime import datetime
from uuid import uuid4

@router.post("/feedback")
async def submit_feedback(request: FeedbackRequest):
    """Save thumbs up/down feedback to Firestore for future fine-tuning."""
    db = fb_service.get_db()
    
    feedback_data = {
        "id": str(uuid4()),
        "message_id": request.message_id,
        "client_id": request.client_id,
        "is_positive": request.is_positive,
        "comments": request.comments,
        "submitted_at": datetime.now().isoformat()
    }
    
    if db:
        # Save to 'feedback' collection
        db.collection("feedback").document(feedback_data["id"]).set(feedback_data)
        return {"success": True, "message": "Feedback enregistré"}
    else:
        # Fallback to local log if Firebase isn't up
        import json
        with open("data/feedback.json", "a", encoding="utf-8") as f:
            f.write(json.dumps(feedback_data) + "\n")
        return {"success": True, "message": "Feedback enregistré (local)"}

