import os
import asyncio
from pathlib import Path
from app.services.firebase_service import fb_service
from app.services.document_processor import _save_metadata

async def migrate_uploads():
    print("Starting migration of local uploads to Firebase Storage...")
    fb_service.initialize()
    bucket = fb_service.get_bucket()
    
    if not bucket:
        print("Error: Could not connect to Storage.")
        return

    uploads_dir = Path("uploads")
    if not uploads_dir.exists():
        print("No uploads directory found.")
        return

    migrated = 0
    for client_dir in uploads_dir.iterdir():
        if not client_dir.is_dir():
            continue
            
        client_id = client_dir.name
        print(f"Checking client: {client_id}")
        
        for f in client_dir.iterdir():
            if f.is_file() and not f.name.startswith("."):
                blob_path = f"uploads/{client_id}/{f.name}"
                blob = bucket.blob(blob_path)
                
                if not blob.exists():
                    print(f"Uploading {f.name}...")
                    blob.upload_from_filename(str(f))
                    migrated += 1
                else:
                    print(f"Skipping {f.name} (already in Storage)")

                # Also upload metadata to Firestore if it exists
                meta_dir = client_dir / ".metadata"
                meta_file = meta_dir / f"{f.stem}_metadata.json"
                if meta_file.exists():
                    import json
                    with open(meta_file, "r", encoding="utf-8") as mf:
                        meta = json.load(mf)
                        # Save to Firestore
                        _save_metadata(client_id, f.name, meta)

    print(f"\nMigration complete! {migrated} files uploaded to Firebase Storage.")

if __name__ == "__main__":
    asyncio.run(migrate_uploads())
