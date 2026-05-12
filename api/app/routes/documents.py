import os
from pathlib import Path
from uuid import uuid4
from datetime import datetime

from fastapi import APIRouter, UploadFile, File, Form, HTTPException

from app.models.schemas import DocumentResponse

router = APIRouter(prefix="/documents", tags=["documents"])

# Create upload directory on startup
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

ALLOWED_EXTENSIONS = {"pdf", "jpg", "jpeg", "png"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


@router.post("/upload", response_model=DocumentResponse)
async def upload_document(
    file: UploadFile = File(...),
    client_id: str = Form(...),
    document_type: str = Form(...)
):
    # Validate file extension
    extension = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Type de fichier non autorisé")

    # Read file content and validate size
    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail="Fichier trop volumineux (max 10MB)")

    # Generate unique filename
    unique_filename = f"{uuid4()}_{file.filename}"

    # Create client folder if not exists
    client_dir = UPLOAD_DIR / client_id
    client_dir.mkdir(exist_ok=True)

    # Save file
    file_path = client_dir / unique_filename
    with open(file_path, "wb") as f:
        f.write(content)

    return DocumentResponse(
        id=str(uuid4()),
        client_id=client_id,
        name=file.filename,
        type=document_type,
        status="pending",
        uploaded_at=datetime.now().isoformat(),
        file_url=f"uploads/{client_id}/{unique_filename}"
    )


@router.get("/{client_id}")
async def list_documents(client_id: str):
    client_dir = UPLOAD_DIR / client_id

    if not client_dir.exists():
        return []

    files = []
    for f in client_dir.iterdir():
        if f.is_file():
            files.append({
                "name": f.name,
                "path": f"uploads/{client_id}/{f.name}"
            })

    return files


@router.delete("/{client_id}/{filename}")
async def delete_document(client_id: str, filename: str):
    file_path = UPLOAD_DIR / client_id / filename

    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Document non trouvé")

    os.remove(file_path)

    return {"message": "Document supprimé avec succès"}
