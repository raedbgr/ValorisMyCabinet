"""
Test Phase 3 — The Agent Loop (Complete)
Tests: 6 tools, tool-calling loop, retry logic, idempotency, citations
"""
import asyncio
import json
import os
from pathlib import Path
from datetime import datetime, timedelta
from uuid import uuid4

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
CLIENT_ID = "phase3_test_client"
DATA_DIR = Path("data")
DEADLINES_FILE = DATA_DIR / "deadlines.json"
REMINDERS_FILE = DATA_DIR / "reminders.json"
UPLOADS_DIR = Path("uploads") / CLIENT_ID

passed = 0
failed = 0

def log(status, test_name, detail=""):
    global passed, failed
    tag = "[PASS]" if status else "[FAIL]"
    if status:
        passed += 1
    else:
        failed += 1
    msg = f"{tag} {test_name}"
    if detail:
        msg += f" -- {detail}"
    print(msg)


def clean_test_data():
    """Remove previous test data for this client."""
    # Clean reminders for this client
    if REMINDERS_FILE.exists():
        with open(REMINDERS_FILE, "r", encoding="utf-8") as f:
            reminders = json.load(f)
        reminders = [r for r in reminders if r.get("client_id") != CLIENT_ID]
        with open(REMINDERS_FILE, "w", encoding="utf-8") as f:
            json.dump(reminders, f, ensure_ascii=False, indent=2)

    # Clean deadlines for this client
    if DEADLINES_FILE.exists():
        with open(DEADLINES_FILE, "r", encoding="utf-8") as f:
            deadlines = json.load(f)
        deadlines = [d for d in deadlines if d.get("client_id") != CLIENT_ID]
        with open(DEADLINES_FILE, "w", encoding="utf-8") as f:
            json.dump(deadlines, f, ensure_ascii=False, indent=2)

    # Clean uploads
    if UPLOADS_DIR.exists():
        for f in UPLOADS_DIR.iterdir():
            if f.is_file():
                f.unlink()

    # Clean status tracker
    status_file = UPLOADS_DIR / "document_status.json"
    if status_file.exists():
        status_file.unlink()


def seed_test_data():
    """Create urgent deadline + one uploaded file for testing."""
    DATA_DIR.mkdir(exist_ok=True)
    UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

    # Urgent deadline (3 days out)
    urgent_date = (datetime.now() + timedelta(days=3)).strftime("%Y-%m-%d")
    # Late deadline (2 days ago)
    late_date = (datetime.now() - timedelta(days=2)).strftime("%Y-%m-%d")

    deadlines = []
    if DEADLINES_FILE.exists():
        with open(DEADLINES_FILE, "r", encoding="utf-8") as f:
            deadlines = json.load(f)
    deadlines = [d for d in deadlines if d.get("client_id") != CLIENT_ID]
    deadlines.extend([
        {
            "id": "p3-test-1",
            "client_id": CLIENT_ID,
            "label": "TVA Mensuelle Test",
            "due_date": urgent_date,
            "type": "TVA",
            "status": "upcoming"
        },
        {
            "id": "p3-test-2",
            "client_id": CLIENT_ID,
            "label": "CNSS Retard Test",
            "due_date": late_date,
            "type": "CNSS",
            "status": "upcoming"
        }
    ])
    with open(DEADLINES_FILE, "w", encoding="utf-8") as f:
        json.dump(deadlines, f, indent=2)

    # Create one uploaded file
    (UPLOADS_DIR / "facture_test.pdf").touch()


# ---------------------------------------------------------------------------
# Test 1: All 6 tools exist in registry
# ---------------------------------------------------------------------------
def test_tools_registry():
    print("\n=== TEST 1: Tools Registry ===")
    from app.services.tools import TOOLS_REGISTRY

    expected = [
        "list_documents",
        "get_upcoming_deadlines",
        "get_missing_documents",
        "request_document",
        "get_client_status",
        "mark_document_received"
    ]
    for name in expected:
        log(name in TOOLS_REGISTRY, f"Tool '{name}' registered")

    log(len(TOOLS_REGISTRY) >= 6, f"Registry has {len(TOOLS_REGISTRY)} tools (expected >= 6)")


# ---------------------------------------------------------------------------
# Test 2: Each tool executes correctly
# ---------------------------------------------------------------------------
def test_tool_execution():
    print("\n=== TEST 2: Tool Execution ===")
    from app.services.tools import TOOLS_REGISTRY

    # list_documents
    res = TOOLS_REGISTRY["list_documents"]({"client_id": CLIENT_ID})
    log(res["count"] >= 1, "list_documents", f"Found {res['count']} doc(s)")

    # list_documents with category filter
    res2 = TOOLS_REGISTRY["list_documents"]({"client_id": CLIENT_ID, "category": "facture"})
    log(res2["count"] >= 1, "list_documents (filtered)", f"Found {res2['count']} facture(s)")

    # get_upcoming_deadlines
    res = TOOLS_REGISTRY["get_upcoming_deadlines"]({"client_id": CLIENT_ID})
    log(res["count"] >= 2, "get_upcoming_deadlines", f"Found {res['count']} deadline(s)")

    # get_missing_documents
    res = TOOLS_REGISTRY["get_missing_documents"]({"client_id": CLIENT_ID, "deadline_type": "TVA"})
    log(len(res["missing"]) > 0, "get_missing_documents", f"Missing: {res['missing']}")

    # request_document
    res = TOOLS_REGISTRY["request_document"]({
        "client_id": CLIENT_ID,
        "doc_type": "releve_bancaire",
        "reason": "Phase 3 test"
    })
    log(res["success"] == True, "request_document", res["message"])

    # get_client_status
    res = TOOLS_REGISTRY["get_client_status"]({"client_id": CLIENT_ID})
    log(res["overall_status"] in ("ok", "attention", "critique"), "get_client_status", f"Status: {res['overall_status']}")

    # mark_document_received (file exists)
    res = TOOLS_REGISTRY["mark_document_received"]({"client_id": CLIENT_ID, "filename": "facture_test.pdf"})
    log(res["success"] == True, "mark_document_received (exists)", res["message"])

    # mark_document_received (file does NOT exist)
    res = TOOLS_REGISTRY["mark_document_received"]({"client_id": CLIENT_ID, "filename": "ghost_file.pdf"})
    log(res["success"] == False, "mark_document_received (missing)", res["message"])

    # Verify status tracker was created
    status_file = UPLOADS_DIR / "document_status.json"
    log(status_file.exists(), "document_status.json created")
    if status_file.exists():
        with open(status_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        log(data.get("facture_test.pdf") == "received", "Status tracker correct", str(data))


# ---------------------------------------------------------------------------
# Test 3: Tool-calling loop with Ollama (requires Ollama running)
# ---------------------------------------------------------------------------
async def test_tool_calling_loop():
    print("\n=== TEST 3: Tool-Calling Loop (Ollama) ===")
    from app.services.ollama_service import ollama_service

    alive = await ollama_service.is_alive()
    if not alive:
        print("[SKIP] Ollama is not running -- skipping loop test")
        return

    result = await ollama_service.analyze_and_remind(
        client_name=CLIENT_ID,
        deadlines=[
            {"label": "TVA Mensuelle Test", "due_date": "2026-05-15", "days_left": 3}
        ],
        missing_documents=[
            {"name": "factures", "type": "facture"},
            {"name": "releve_bancaire", "type": "releve_bancaire"}
        ]
    )

    log("should_remind" in result, "Loop returned should_remind", str(result.get("should_remind")))
    log("reminder_message" in result, "Loop returned reminder_message", result.get("reminder_message", "")[:80])
    log("urgency" in result, "Loop returned urgency", result.get("urgency"))
    log("missing_docs_summary" in result, "Loop returned missing_docs_summary")


# ---------------------------------------------------------------------------
# Test 4: Idempotency check
# ---------------------------------------------------------------------------
async def test_idempotency():
    print("\n=== TEST 4: Idempotency ===")
    from app.routes.agent import load_reminders, save_reminders

    # Inject a fake "recent" reminder (sent 1 hour ago)
    all_reminders = load_reminders()
    fake_reminder = {
        "id": str(uuid4()),
        "client_id": CLIENT_ID,
        "message": "Fake recent reminder for idempotency test",
        "urgency": "high",
        "sent_at": (datetime.now() - timedelta(hours=1)).isoformat(),
        "auto": True,
        "channel": "push_notification"
    }
    all_reminders.append(fake_reminder)
    save_reminders(all_reminders)

    # Now run the scheduler job
    from app.services.scheduler import proactive_agent_job
    from app.services.ollama_service import ollama_service

    alive = await ollama_service.is_alive()
    if not alive:
        print("[SKIP] Ollama is not running -- skipping idempotency test")
        return

    count_before = len([r for r in load_reminders() if r["client_id"] == CLIENT_ID])
    await proactive_agent_job()
    count_after = len([r for r in load_reminders() if r["client_id"] == CLIENT_ID])

    log(count_after == count_before, "Idempotency: no duplicate reminder",
        f"Before={count_before}, After={count_after}")


# ---------------------------------------------------------------------------
# Test 5: Scope guard in system prompt
# ---------------------------------------------------------------------------
def test_scope_guard():
    print("\n=== TEST 5: Scope Guard + Citations in Prompt ===")
    # We can't test the LLM's behavior directly, but we verify
    # the system prompt contains the right instructions
    import app.services.ollama_service as svc
    import inspect
    source = inspect.getsource(svc.OllamaService.analyze_and_remind)

    log("hors sujet" in source or "question hors" in source or "ne peux pas aider" in source,
        "Scope guard present in prompt")
    log("[doc:" in source, "Citation markers [doc:] present in prompt")
    log("mark_document_received" in source, "Tool 6 registered in prompt")


# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
async def main():
    print("=" * 60)
    print("  PHASE 3 - COMPLETE AGENT LOOP TEST")
    print("=" * 60)

    clean_test_data()
    seed_test_data()

    test_tools_registry()
    test_tool_execution()
    await test_tool_calling_loop()
    await test_idempotency()
    test_scope_guard()

    print("\n" + "=" * 60)
    print(f"  RESULTS: {passed} passed, {failed} failed")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
