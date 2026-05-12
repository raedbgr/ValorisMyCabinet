import asyncio
import json
import os
from pathlib import Path
from datetime import datetime, timedelta
from app.services.scheduler import proactive_agent_job

# Config
CLIENT_ID = "proactive_test_001"
DATA_DIR = Path("data")
DEADLINES_FILE = DATA_DIR / "deadlines.json"
REMINDERS_FILE = DATA_DIR / "reminders.json"
UPLOADS_DIR = Path("uploads") / CLIENT_ID

def seed_urgent_data():
    """Seed a client with an urgent deadline and no documents."""
    print(f"--- Seeding urgent data for {CLIENT_ID} ---")
    
    # 1. Create data folder
    DATA_DIR.mkdir(exist_ok=True)
    
    # 2. Create an URGENT deadline (3 days from now)
    urgent_date = (datetime.now() + timedelta(days=3)).strftime("%Y-%m-%d")
    
    deadlines = [
        {
            "id": "urgent-job-test",
            "client_id": CLIENT_ID,
            "label": "TVA Mensuelle Proactive",
            "due_date": urgent_date,
            "type": "TVA",
            "status": "upcoming" # Will be calculated as 'urgent' by the agent
        }
    ]
    
    # Load existing or start fresh
    all_deadlines = []
    if DEADLINES_FILE.exists():
        with open(DEADLINES_FILE, "r", encoding="utf-8") as f:
            all_deadlines = json.load(f)
            
    # Remove existing test client data if any
    all_deadlines = [d for d in all_deadlines if d["client_id"] != CLIENT_ID]
    all_deadlines.extend(deadlines)
    
    with open(DEADLINES_FILE, "w", encoding="utf-8") as f:
        json.dump(all_deadlines, f, indent=2)
        
    # 3. Ensure uploads folder exists but is EMPTY
    UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    for f in UPLOADS_DIR.iterdir():
        if f.is_file():
            f.unlink()
            
    print(f"Done. {CLIENT_ID} has 1 urgent deadline and 0 documents.\n")

async def test_job():
    seed_urgent_data()
    
    print("--- Manually triggering Proactive Agent Job ---")
    print("(This will call Ollama, please wait...)\n")
    
    # Check current reminders count
    initial_reminders = []
    if REMINDERS_FILE.exists():
        with open(REMINDERS_FILE, "r", encoding="utf-8") as f:
            initial_reminders = json.load(f)
    
    # Run the background job logic once
    await proactive_agent_job()
    
    # Check new reminders
    if REMINDERS_FILE.exists():
        with open(REMINDERS_FILE, "r", encoding="utf-8") as f:
            final_reminders = json.load(f)
            
        new_reminders = [r for r in final_reminders if r["client_id"] == CLIENT_ID]
        
        if len(new_reminders) > 0:
            print(f"\n[SUCCESS] The agent generated {len(new_reminders)} reminders.")
            for r in new_reminders:
                print(f"--- Reminder [{r['urgency'].upper()}] ---")
                print(f"Message: {r['message']}")
                print(f"Sent at: {r['sent_at']}")
        else:
            print("\n[FAILED] No reminders generated in reminders.json.")
    else:
        print("\n[FAILED] reminders.json does not exist.")

if __name__ == "__main__":
    asyncio.run(test_job())
