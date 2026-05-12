from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, HTTPException

from app.models.schemas import ClientSummary, CabinetDashboard
from app.routes.deadlines import load_deadlines, calculate_status

router = APIRouter(prefix="/cabinet", tags=["cabinet"])

UPLOAD_DIR = Path("uploads")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def get_client_ids() -> list[str]:
    """
    Scan uploads/ folder for subdirectories and
    data/deadlines.json for unique client_ids.
    Return merged unique list.
    """
    client_ids = set()

    # From uploads folder
    if UPLOAD_DIR.exists():
        for d in UPLOAD_DIR.iterdir():
            if d.is_dir():
                client_ids.add(d.name)

    # From deadlines data
    all_deadlines = load_deadlines()
    for d in all_deadlines:
        client_ids.add(d["client_id"])

    return sorted(client_ids)


def get_client_summary(client_id: str) -> ClientSummary:
    """Build a full summary for a single client."""

    # STEP 1 — Load deadlines for this client
    all_deadlines = load_deadlines()
    client_deadlines = [d for d in all_deadlines if d["client_id"] == client_id]

    total = len(client_deadlines)
    urgent = 0
    late = 0

    for d in client_deadlines:
        days_left, status = calculate_status(d["due_date"])
        d["days_left"] = days_left
        d["status"] = status
        if status == "urgent":
            urgent += 1
        elif status == "late":
            late += 1

    # STEP 2 — Count uploaded documents
    client_dir = UPLOAD_DIR / client_id
    uploaded_docs = 0
    if client_dir.exists():
        uploaded_docs = sum(1 for f in client_dir.iterdir() if f.is_file())

    # STEP 3 — Calculate completion %
    expected = total * 1  # 1 doc per deadline minimum
    if expected == 0:
        completion = 100.0
    else:
        completion = min(100.0, (uploaded_docs / expected) * 100)
    completion = round(completion, 1)

    # STEP 4 — Determine status
    if late > 0:
        status = "critique"
    elif urgent > 0:
        status = "attention"
    else:
        status = "ok"

    return ClientSummary(
        client_id=client_id,
        total_deadlines=total,
        urgent_deadlines=urgent,
        late_deadlines=late,
        uploaded_docs=uploaded_docs,
        completion_percentage=completion,
        status=status
    )


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

STATUS_ORDER = {"critique": 0, "attention": 1, "ok": 2}


@router.get("/dashboard", response_model=CabinetDashboard)
async def dashboard():
    """Full cabinet dashboard — all clients with their summaries."""
    client_ids = get_client_ids()

    if not client_ids:
        return CabinetDashboard(
            total_clients=0,
            clients=[],
            generated_at=datetime.now().isoformat()
        )

    clients = [get_client_summary(cid) for cid in client_ids]

    # Sort: critique first, then attention, then ok
    clients.sort(key=lambda c: STATUS_ORDER.get(c.status, 2))

    return CabinetDashboard(
        total_clients=len(clients),
        clients=clients,
        generated_at=datetime.now().isoformat()
    )


@router.get("/clients/{client_id}", response_model=ClientSummary)
async def get_single_client(client_id: str):
    """Return a single client summary."""
    all_client_ids = get_client_ids()

    if client_id not in all_client_ids:
        raise HTTPException(status_code=404, detail="Client non trouvé")

    return get_client_summary(client_id)


@router.get("/alerts")
async def get_alerts():
    """Return only clients with status 'critique' or 'attention', plus their urgent deadlines."""
    client_ids = get_client_ids()
    alerts = []

    all_deadlines = load_deadlines()

    for cid in client_ids:
        summary = get_client_summary(cid)

        if summary.status not in ("critique", "attention"):
            continue

        # Gather urgent deadlines for this client
        urgent_deadlines = []
        for d in all_deadlines:
            if d["client_id"] != cid:
                continue
            days_left, status = calculate_status(d["due_date"])
            if status in ("urgent", "late"):
                urgent_deadlines.append({
                    "label": d["label"],
                    "due_date": d["due_date"],
                    "days_left": days_left,
                    "status": status,
                    "type": d["type"]
                })

        alerts.append({
            "client": summary.model_dump(),
            "urgent_deadlines": urgent_deadlines
        })

    # Sort: critique first
    alerts.sort(key=lambda a: STATUS_ORDER.get(a["client"]["status"], 2))
    return alerts
