import os
from pathlib import Path
from uuid import uuid4
from datetime import datetime

from fastapi import APIRouter, UploadFile, File, Form, HTTPException

from app.models.schemas import DocumentResponse, ProcessRequest

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
        raise HTTPException(status_code=404, detail="Document non trouve")

    os.remove(file_path)

    return {"message": "Document supprime avec succes"}


@router.post("/process")
async def process_document_route(request: ProcessRequest):
    from app.services.document_processor import process_document

    file_path = UPLOAD_DIR / request.client_id / request.filename

    if not file_path.exists():
        raise HTTPException(
            status_code=404,
            detail=f"Fichier non trouve: {request.filename}"
        )

    result = await process_document(file_path, request.client_id)
    return result


@router.post("/process-all/{client_id}")
async def process_all_documents(client_id: str):
    """Process all unprocessed documents for a client in one call."""
    from app.services.document_processor import process_document, get_document_metadata

    client_dir = UPLOAD_DIR / client_id
    if not client_dir.exists():
        raise HTTPException(status_code=404, detail="Client non trouve")

    results = []
    for f in client_dir.iterdir():
        if not f.is_file() or f.name.startswith("."):
            continue
        # Skip already-processed files
        existing = get_document_metadata(f)
        if existing and existing.get("status") == "processed":
            results.append({"filename": f.name, "status": "already_processed", "skipped": True})
            continue

        result = await process_document(f, client_id)
        results.append(result)

    return {
        "client_id": client_id,
        "total_files": len(results),
        "processed": sum(1 for r in results if r.get("status") == "processed"),
        "skipped": sum(1 for r in results if r.get("skipped", False)),
        "failed": sum(1 for r in results if r.get("status") == "extraction_failed"),
        "results": results
    }


@router.get("/{client_id}/{filename}/metadata")
async def get_document_metadata_route(client_id: str, filename: str):
    """Retrieve saved processing metadata for a specific document."""
    from app.services.document_processor import get_document_metadata

    file_path = UPLOAD_DIR / client_id / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Document non trouve")

    metadata = get_document_metadata(file_path)
    if not metadata:
        raise HTTPException(status_code=404, detail="Document non encore traite")

    return metadata

