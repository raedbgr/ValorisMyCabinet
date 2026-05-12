"""
Migration script to push local JSON data to Firestore.
Run this once after setting up serviceAccountKey.json.
"""
import json
import asyncio
from pathlib import Path
from app.services.firebase_service import fb_service

async def migrate():
    print("Starting migration to Firestore...")
    
    # Initialize Firebase
    fb_service.initialize()
    db = fb_service.get_db()
    
    if not db:
        print("Error: Could not connect to Firestore. Check serviceAccountKey.json")
        return

    # 1. Migrate Deadlines
    deadlines_file = Path("data/deadlines.json")
    if deadlines_file.exists():
        with open(deadlines_file, "r", encoding="utf-8") as f:
            deadlines = json.load(f)
            
        print(f"Migrating {len(deadlines)} deadlines...")
        for d in deadlines:
            # We use client_id + label as a semi-unique ID or let Firestore generate
            doc_id = f"{d['client_id']}_{d['label']}".replace(" ", "_").lower()
            db.collection("deadlines").document(doc_id).set(d)
        print("[OK] Deadlines migrated.")

    # 2. Migrate Reminders
    reminders_file = Path("data/reminders.json")
    if reminders_file.exists():
        with open(reminders_file, "r", encoding="utf-8") as f:
            reminders = json.load(f)
            
        print(f"Migrating {len(reminders)} reminders...")
        for r in reminders:
            db.collection("reminders").document(r["id"]).set(r)
        print("[OK] Reminders migrated.")

    print("\nMigration complete! You can now see your data in the Firebase Console.")

if __name__ == "__main__":
    asyncio.run(migrate())
