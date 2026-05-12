import json
import os
from datetime import date, datetime, timedelta
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter

from app.models.schemas import Deadline, DeadlineCreate

router = APIRouter(prefix="/deadlines", tags=["deadlines"])

# Create data folder on startup
DATA_DIR = Path("data")
DATA_DIR.mkdir(exist_ok=True)
DEADLINES_FILE = DATA_DIR / "deadlines.json"


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
    """Read deadlines.json and return a list (or [] if file missing)."""
    if not DEADLINES_FILE.exists():
        return []
    with open(DEADLINES_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def save_deadlines(deadlines: list[dict]):
    """Write the full list back to deadlines.json."""
    with open(DEADLINES_FILE, "w", encoding="utf-8") as f:
        json.dump(deadlines, f, ensure_ascii=False, indent=2)


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

    all_deadlines = load_deadlines()
    all_deadlines.append(deadline)
    save_deadlines(all_deadlines)

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

        all_deadlines.append(deadline)
        created.append(deadline)

    save_deadlines(all_deadlines)
    return created
