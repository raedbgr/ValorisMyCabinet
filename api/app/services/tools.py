import json
import os
from datetime import datetime
from pathlib import Path
from uuid import uuid4

from app.routes.deadlines import load_deadlines, calculate_status

UPLOAD_DIR = Path("uploads")
DATA_DIR = Path("data")
REMINDERS_FILE = DATA_DIR / "reminders.json"

# Map deadline types to expected document types
DEADLINE_DOC_REQUIREMENTS = {
    "TVA":  ["factures", "releve_bancaire"],
    "IS":   ["bilan", "justificatif"],
    "CNSS": ["releve_bancaire", "bulletin_salaire"],
    "IR":   ["factures", "justificatif"],
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _load_reminders() -> list[dict]:
    if not REMINDERS_FILE.exists():
        return []
    with open(REMINDERS_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def _save_reminders(reminders: list[dict]):
    DATA_DIR.mkdir(exist_ok=True)
    with open(REMINDERS_FILE, "w", encoding="utf-8") as f:
        json.dump(reminders, f, ensure_ascii=False, indent=2)


# ---------------------------------------------------------------------------
# TOOL 1: list_documents
# ---------------------------------------------------------------------------

def list_documents(args: dict) -> dict:
    """
    Scan uploads/{client_id}/ folder and return file list.
    Optionally filter by category keyword in filename.
    """
    client_id = args.get("client_id", "")
    category = args.get("category", None)

    client_dir = UPLOAD_DIR / client_id

    if not client_dir.exists():
        return {"documents": [], "count": 0, "client_id": client_id}

    documents = []
    for f in client_dir.iterdir():
        if not f.is_file():
            continue
        # If category filter provided, match against filename
        if category and category.lower() not in f.name.lower():
            continue
        documents.append({
            "name": f.name,
            "path": f"uploads/{client_id}/{f.name}"
        })

    return {
        "documents": documents,
        "count": len(documents),
        "client_id": client_id
    }


# ---------------------------------------------------------------------------
# TOOL 2: get_upcoming_deadlines
# ---------------------------------------------------------------------------

def get_upcoming_deadlines(args: dict) -> dict:
    """
    Load deadlines for a client, recalculate status,
    return only upcoming + urgent + late (not done).
    """
    client_id = args.get("client_id", "")

    all_deadlines = load_deadlines()
    result = []

    for d in all_deadlines:
        if d["client_id"] != client_id:
            continue
        days_left, status = calculate_status(d["due_date"])
        d["days_left"] = days_left
        d["status"] = status
        if status != "done":
            result.append(d)

    result.sort(key=lambda d: d["due_date"])

    return {
        "deadlines": result,
        "count": len(result),
        "client_id": client_id
    }


# ---------------------------------------------------------------------------
# TOOL 3: get_missing_documents
# ---------------------------------------------------------------------------

def get_missing_documents(args: dict) -> dict:
    """
    Compare expected documents for a deadline type against
    what's actually uploaded for the client.
    """
    client_id = args.get("client_id", "")
    deadline_type = args.get("deadline_type", "autre")

    expected = DEADLINE_DOC_REQUIREMENTS.get(deadline_type, ["justificatif"])

    # Scan existing files
    client_dir = UPLOAD_DIR / client_id
    existing_files = []
    if client_dir.exists():
        existing_files = [f.name.lower() for f in client_dir.iterdir() if f.is_file()]

    # Compare
    missing = []
    existing_matched = []

    for doc_type in expected:
        found = any(doc_type in fname for fname in existing_files)
        if found:
            existing_matched.append(doc_type)
        else:
            missing.append(doc_type)

    return {
        "missing": missing,
        "existing": existing_matched,
        "complete": len(missing) == 0
    }


# ---------------------------------------------------------------------------
# TOOL 4: request_document
# ---------------------------------------------------------------------------

def request_document(args: dict) -> dict:
    """
    Create a reminder/request entry for a missing document
    and save it to reminders.json.
    """
    client_id = args.get("client_id", "")
    doc_type = args.get("doc_type", "")
    reason = args.get("reason", "")

    reminder = {
        "id": str(uuid4()),
        "client_id": client_id,
        "doc_type": doc_type,
        "reason": reason,
        "message": f"Document requis: {doc_type} — {reason}",
        "requested_at": datetime.now().isoformat(),
        "auto": True,
        "channel": "portail"
    }

    all_reminders = _load_reminders()
    all_reminders.append(reminder)
    _save_reminders(all_reminders)

    return {
        "success": True,
        "message": f"Demande envoyée pour {doc_type}",
        "client_id": client_id
    }


# ---------------------------------------------------------------------------
# TOOL 5: get_client_status
# ---------------------------------------------------------------------------

def get_client_status(args: dict) -> dict:
    """
    Build a quick status overview for a client:
    deadlines, docs, completion %, overall status.
    """
    client_id = args.get("client_id", "")

    # Deadlines
    all_deadlines = load_deadlines()
    client_deadlines = [d for d in all_deadlines if d["client_id"] == client_id]

    total = len(client_deadlines)
    urgent = 0
    late = 0

    for d in client_deadlines:
        days_left, status = calculate_status(d["due_date"])
        if status == "urgent":
            urgent += 1
        elif status == "late":
            late += 1

    # Uploaded docs
    client_dir = UPLOAD_DIR / client_id
    uploaded_docs = 0
    if client_dir.exists():
        uploaded_docs = sum(1 for f in client_dir.iterdir() if f.is_file())

    # Completion %
    expected = total * 1
    if expected == 0:
        completion = 100.0
    else:
        completion = min(100.0, (uploaded_docs / expected) * 100)
    completion = round(completion, 1)

    # Overall status
    if late > 0:
        overall = "critique"
    elif urgent > 0:
        overall = "attention"
    else:
        overall = "ok"

    return {
        "client_id": client_id,
        "urgent_deadlines": urgent,
        "late_deadlines": late,
        "uploaded_docs": uploaded_docs,
        "completion_percentage": completion,
        "overall_status": overall
    }


# ---------------------------------------------------------------------------
# TOOL 6: mark_document_received
# ---------------------------------------------------------------------------

def mark_document_received(args: dict) -> dict:
    """
    Check if a specific file exists in uploads/{client_id}/,
    and mark it as 'received' in a lightweight JSON tracker.
    This closes the loop: agent detects upload → confirms receipt.
    """
    client_id = args.get("client_id", "")
    filename = args.get("filename", "")

    client_dir = UPLOAD_DIR / client_id
    file_path = client_dir / filename
    status_file = client_dir / "document_status.json"

    # Load existing status tracker
    status_data = {}
    if status_file.exists():
        with open(status_file, "r", encoding="utf-8") as f:
            status_data = json.load(f)

    # Check if the file actually exists on disk
    if not file_path.exists():
        return {
            "success": False,
            "message": f"{filename} non trouve.",
            "status": "missing"
        }

    # Mark as received
    status_data[filename] = "received"

    # Ensure directory exists and save
    client_dir.mkdir(parents=True, exist_ok=True)
    with open(status_file, "w", encoding="utf-8") as f:
        json.dump(status_data, f, ensure_ascii=False, indent=2)

    return {
        "success": True,
        "message": f"{filename} marque comme recu.",
        "status": "received"
    }


# ---------------------------------------------------------------------------
# TOOLS REGISTRY
# ---------------------------------------------------------------------------

TOOLS_REGISTRY = {
    "list_documents": list_documents,
    "get_upcoming_deadlines": get_upcoming_deadlines,
    "get_missing_documents": get_missing_documents,
    "request_document": request_document,
    "get_client_status": get_client_status,
    "mark_document_received": mark_document_received,
}
