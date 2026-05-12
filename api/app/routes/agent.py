import json
import os
from datetime import datetime
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter

from app.models.schemas import AgentRequest, AgentResponse
from app.services.ollama_service import ollama_service
from app.routes.deadlines import load_deadlines, calculate_status

router = APIRouter(prefix="/agent", tags=["agent"])

from app.services.firebase_service import fb_service


UPLOAD_DIR = Path("uploads")

# Map deadline types to expected document types
DEADLINE_DOC_MAP = {
    "TVA": "facture",
    "CNSS": "releve_bancaire",
    "IS": "justificatif",
    "IR": "facture",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_reminders() -> list[dict]:
    """Read reminders from Firestore."""
    db = fb_service.get_db()
    if not db:
        return []
        
    docs = db.collection("reminders").stream()
    return [doc.to_dict() for doc in docs]


def save_reminder(reminder: dict):
    """Save a single reminder to Firestore."""
    db = fb_service.get_db()
    if db:
        db.collection("reminders").document(reminder["id"]).set(reminder)


def get_urgent_deadlines_for_client(client_id: str) -> list[dict]:
    """Load deadlines, filter by client_id, keep only urgent/late."""
    all_deadlines = load_deadlines()
    urgent = []
    for d in all_deadlines:
        if d["client_id"] != client_id:
            continue
        days_left, status = calculate_status(d["due_date"])
        d["days_left"] = days_left
        d["status"] = status
        if status in ("urgent", "late"):
            urgent.append(d)
    return urgent


def scan_missing_documents(client_id: str, urgent_deadlines: list[dict]) -> list[dict]:
    """
    Based on urgent deadlines, determine what docs are expected.
    If uploads folder is empty or missing, all docs are missing.
    """
    client_dir = UPLOAD_DIR / client_id
    existing_files = []

    if client_dir.exists():
        existing_files = [f.name.lower() for f in client_dir.iterdir() if f.is_file()]

    missing = []
    for d in urgent_deadlines:
        expected_type = DEADLINE_DOC_MAP.get(d["type"], "autre")
        # Check if any uploaded file relates to this doc type
        has_doc = any(expected_type in fname for fname in existing_files)
        if not has_doc:
            missing.append({
                "name": f"{d['label']} - {expected_type}",
                "type": expected_type
            })

    return missing


async def run_agent_check(client_id: str) -> dict:
    """Core agent logic shared between check and remind routes."""

    # STEP 1 — Load urgent deadlines
    urgent_deadlines = get_urgent_deadlines_for_client(client_id)

    # STEP 2 — Scan missing documents
    missing_docs = scan_missing_documents(client_id, urgent_deadlines)

    # STEP 3 — No urgent deadlines → early return
    if not urgent_deadlines:
        return {
            "should_remind": False,
            "message": "Aucune échéance urgente pour ce client",
            "client_id": client_id,
            "urgent_deadlines_count": 0,
            "missing_docs_count": 0,
            "checked_at": datetime.now().isoformat()
        }

    # STEP 4 — Call Ollama agent
    deadlines_dicts = [
        {"label": d["label"], "due_date": d["due_date"], "days_left": d["days_left"]}
        for d in urgent_deadlines
    ]

    result = await ollama_service.analyze_and_remind(
        client_name=client_id,
        deadlines=deadlines_dicts,
        missing_documents=missing_docs
    )

    # STEP 5 — Build full response
    return {
        "should_remind": result.get("should_remind", True),
        "reminder_message": result.get("reminder_message", ""),
        "urgency": result.get("urgency", "medium"),
        "missing_docs_summary": result.get("missing_docs_summary", ""),
        "client_id": client_id,
        "urgent_deadlines_count": len(urgent_deadlines),
        "missing_docs_count": len(missing_docs),
        "checked_at": datetime.now().isoformat()
    }


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@router.post("/analyze", response_model=AgentResponse)
async def analyze(request: AgentRequest):
    """Manual analysis with provided data."""
    deadlines = [d.model_dump() for d in request.deadlines]
    missing_docs = [d.model_dump() for d in request.missing_documents]

    result = await ollama_service.analyze_and_remind(
        client_name=request.client_name,
        deadlines=deadlines,
        missing_documents=missing_docs
    )

    return AgentResponse(**result)


@router.get("/check/{client_id}")
async def check_client(client_id: str):
    """Full automatic agent loop — read deadlines, scan docs, generate reminder."""
    return await run_agent_check(client_id)


@router.post("/remind/{client_id}")
async def remind_client(client_id: str):
    """Same as check but also saves the reminder to reminders.json."""
    result = await run_agent_check(client_id)

    if result.get("should_remind", False):
        reminder = {
            "id": str(uuid4()),
            "client_id": client_id,
            "message": result.get("reminder_message", ""),
            "urgency": result.get("urgency", "medium"),
            "sent_at": datetime.now().isoformat(),
            "auto": True
        }

        save_reminder(reminder)
        
        fcm_token = fb_service.get_client_fcm_token(client_id)
        if fcm_token:
            fb_service.send_push_notification(
                token=fcm_token,
                title="Rappel MyCabinet",
                body=reminder["message"],
                data={"client_id": client_id, "urgency": reminder["urgency"]}
            )

        result["reminder_saved"] = True
    else:
        result["reminder_saved"] = False

    return result


@router.get("/reminders/{client_id}")
async def get_reminders(client_id: str):
    """Load all saved reminders for a client, sorted by sent_at descending."""
    all_reminders = load_reminders()
    client_reminders = [r for r in all_reminders if r["client_id"] == client_id]
    client_reminders.sort(key=lambda r: r["sent_at"], reverse=True)
    return client_reminders
