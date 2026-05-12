import json
import os
from datetime import date, datetime, timedelta
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter

from app.models.schemas import Deadline, DeadlineCreate

router = APIRouter(prefix="/deadlines", tags=["deadlines"])

from app.services.firebase_service import fb_service



# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def calculate_status(due_date_str: str) -> tuple[int, str]:
    """Parse due_date and return (days_left, status)."""
    due_date = datetime.strptime(due_date_str, "%Y-%m-%d").date()
    days_left = (due_date - date.today()).days

    if days_left < 0:
        status = "late"
    elif days_left <= 7:
        status = "urgent"
    else:
        status = "upcoming"

    return days_left, status


def load_deadlines() -> list[dict]:
    """Read deadlines from Firestore."""
    db = fb_service.get_db()
    if not db:
        return []
    
    docs = db.collection("deadlines").stream()
    return [doc.to_dict() for doc in docs]



# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@router.get("/{client_id}", response_model=list[Deadline])
async def get_deadlines(client_id: str):
    """Return all deadlines for a client, sorted by due_date ascending."""
    all_deadlines = load_deadlines()
    client_deadlines = [d for d in all_deadlines if d["client_id"] == client_id]

    # Recalculate days_left and status
    for d in client_deadlines:
        d["days_left"], d["status"] = calculate_status(d["due_date"])

    client_deadlines.sort(key=lambda d: d["due_date"])
    return client_deadlines


@router.post("/", response_model=Deadline)
async def create_deadline(body: DeadlineCreate):
    """Create a new deadline and persist it."""
    days_left, status = calculate_status(body.due_date)

    deadline = {
        "id": str(uuid4()),
        "client_id": body.client_id,
        "label": body.label,
        "due_date": body.due_date,
        "days_left": days_left,
        "status": status,
        "type": body.type
    }

    db = fb_service.get_db()
    if db:
        doc_id = f"{body.client_id}_{body.label}".replace(" ", "_").lower()
        db.collection("deadlines").document(doc_id).set(deadline)

    return deadline


@router.get("/{client_id}/urgent", response_model=list[Deadline])
async def get_urgent_deadlines(client_id: str):
    """Return only urgent or late deadlines (used by the agent)."""
    all_deadlines = load_deadlines()
    client_deadlines = [d for d in all_deadlines if d["client_id"] == client_id]

    urgent = []
    for d in client_deadlines:
        d["days_left"], d["status"] = calculate_status(d["due_date"])
        if d["status"] in ("urgent", "late"):
            urgent.append(d)

    urgent.sort(key=lambda d: d["due_date"])
    return urgent


@router.post("/seed/{client_id}", response_model=list[Deadline])
async def seed_deadlines(client_id: str):
    """Seed 5 realistic Tunisian fiscal deadlines for a client."""
    today = date.today()

    seeds = [
        {"label": "TVA Mensuelle",         "type": "TVA",  "offset": 10},
        {"label": "CNSS Employeur",        "type": "CNSS", "offset": 20},
        {"label": "Acompte IS",            "type": "IS",   "offset": 45},
        {"label": "IR Mensuel",            "type": "IR",   "offset": 5},
        {"label": "Déclaration Annuelle",  "type": "IS",   "offset": 90},
    ]

    created = []
    all_deadlines = load_deadlines()

    for s in seeds:
        due = today + timedelta(days=s["offset"])
        due_str = due.isoformat()
        days_left, status = calculate_status(due_str)

        deadline = {
            "id": str(uuid4()),
            "client_id": client_id,
            "label": s["label"],
            "due_date": due_str,
            "days_left": days_left,
            "type": s["type"],
            "status": status
        }

        created.append(deadline)

    db = fb_service.get_db()
    if db:
        batch = db.batch()
        for deadline in created:
            doc_id = f"{client_id}_{deadline['label']}".replace(" ", "_").lower()
            ref = db.collection("deadlines").document(doc_id)
            batch.set(ref, deadline)
        batch.commit()
        
    return created
