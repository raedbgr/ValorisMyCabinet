"""
Document Processing Service for Valoris.

Pipeline:
  1. Text Extraction   — pypdf for PDFs, pytesseract for images
  2. AI Classification — Ollama classifies into fiscal categories
  3. AI Field Extract  — Ollama pulls structured fields (date, amount, vendor…)
  4. Persist           — Save extracted metadata alongside the original file
"""

import json
import logging
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Optional

import pytesseract

logger = logging.getLogger(__name__)

from app.services.ollama_service import ollama_service

# --- Windows Tesseract Configuration ---
# Point this to your Tesseract installation path
TESSERACT_CMD = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
if os.path.exists(TESSERACT_CMD):
    pytesseract.pytesseract.tesseract_cmd = TESSERACT_CMD
# ----------------------------------------

# ---------------------------------------------------------------------------
# Stage 1 — Text Extraction
# ---------------------------------------------------------------------------

SUPPORTED_PDF = {".pdf"}
SUPPORTED_IMG = {".jpg", ".jpeg", ".png", ".tiff", ".bmp"}


async def extract_text_from_file(file_path: Path) -> dict:
    """
    Extract text from a PDF or image file.
    Returns {"text": str, "method": str, "pages": int, "success": bool, "error": str|None}
    """
    suffix = file_path.suffix.lower()

    if suffix in SUPPORTED_PDF:
        return _extract_from_pdf(file_path)
    elif suffix in SUPPORTED_IMG:
        return _extract_from_image(file_path)
    else:
        return {
            "text": "",
            "method": "unsupported",
            "pages": 0,
            "success": False,
            "error": f"Format non supporte: {suffix}"
        }


def _extract_from_pdf(file_path: Path) -> dict:
    """Extract text from a PDF using pypdf. Falls back to OCR if text is empty."""
    try:
        from pypdf import PdfReader

        reader = PdfReader(str(file_path))
        pages = len(reader.pages)
        text_parts = []

        for page in reader.pages:
            page_text = page.extract_text() or ""
            text_parts.append(page_text.strip())

        full_text = "\n\n".join(text_parts).strip()

        # If pypdf got nothing (scanned PDF), try OCR
        if len(full_text) < 20:
            logger.info(f"PDF text too short ({len(full_text)} chars), attempting OCR fallback")
            ocr_result = _ocr_pdf_pages(file_path)
            if ocr_result["success"] and len(ocr_result["text"]) > len(full_text):
                return ocr_result

        return {
            "text": full_text,
            "method": "pypdf",
            "pages": pages,
            "success": len(full_text) > 0,
            "error": None if full_text else "Aucun texte extrait du PDF"
        }
    except Exception as e:
        logger.error(f"PDF extraction failed: {e}")
        return {
            "text": "",
            "method": "pypdf",
            "pages": 0,
            "success": False,
            "error": str(e)
        }


def _ocr_pdf_pages(file_path: Path) -> dict:
    """Convert PDF pages to images and OCR each one."""
    try:
        from PIL import Image

        # Try pdf2image first for proper PDF → image conversion
        try:
            from pdf2image import convert_from_path
            images = convert_from_path(str(file_path), dpi=300)
        except ImportError:
            # pdf2image not available — skip OCR for PDFs
            return {
                "text": "",
                "method": "ocr_pdf_skipped",
                "pages": 0,
                "success": False,
                "error": "pdf2image non installe pour l'OCR des PDFs scannes"
            }

        text_parts = []
        for img in images:
            text = pytesseract.image_to_string(img, lang="fra")
            text_parts.append(text.strip())

        full_text = "\n\n".join(text_parts).strip()
        return {
            "text": full_text,
            "method": "ocr_pdf",
            "pages": len(images),
            "success": len(full_text) > 0,
            "error": None
        }
    except Exception as e:
        logger.error(f"OCR PDF fallback failed: {e}")
        return {
            "text": "",
            "method": "ocr_pdf",
            "pages": 0,
            "success": False,
            "error": str(e)
        }


def _extract_from_image(file_path: Path) -> dict:
    """OCR an image file using pytesseract."""
    try:
        from PIL import Image

        img = Image.open(str(file_path))
        # Use French language pack for better fiscal doc recognition
        text = pytesseract.image_to_string(img, lang="fra")
        text = text.strip()

        return {
            "text": text,
            "method": "ocr_image",
            "pages": 1,
            "success": len(text) > 0,
            "error": None if text else "Aucun texte detecte dans l'image"
        }
    except Exception as e:
        logger.error(f"Image OCR failed: {e}")
        return {
            "text": "",
            "method": "ocr_image",
            "pages": 0,
            "success": False,
            "error": str(e)
        }


# ---------------------------------------------------------------------------
# Stage 2 — AI Classification
# ---------------------------------------------------------------------------

DOCUMENT_CATEGORIES = [
    "facture",
    "kbis",
    "justificatif",
    "releve_bancaire",
    "bulletin_salaire",
    "bilan",
    "declaration_fiscale",
    "contrat",
    "autre"
]

CLASSIFICATION_PROMPT = """Tu es un assistant de classification pour le cabinet Valoris.
Analyse le texte et choisis la categorie la plus probable.

Categories: facture, kbis, justificatif, releve_bancaire, bulletin_salaire, bilan, declaration_fiscale, contrat, autre

Reponds UNIQUEMENT en JSON:
{"category": "nom", "confidence": 0.9, "reasoning": "..."}"""


async def classify_document(text: str, filename: str = "") -> dict:
    """
    Use Ollama to classify a document. Falls back to filename analysis if text is sparse.
    """
    # 1. Filename-based heuristic (very reliable for common names)
    fn = filename.lower()
    if "facture" in fn:
        return {"category": "facture", "confidence": 0.8, "reasoning": "Detecte via le nom du fichier"}
    if "releve" in fn or "banque" in fn:
        return {"category": "releve_bancaire", "confidence": 0.8, "reasoning": "Detecte via le nom du fichier"}
    if "kbis" in fn or "rne" in fn:
        return {"category": "kbis", "confidence": 0.8, "reasoning": "Detecte via le nom du fichier"}
    if "salaire" in fn or "paie" in fn:
        return {"category": "bulletin_salaire", "confidence": 0.8, "reasoning": "Detecte via le nom du fichier"}

    # 2. Text-based AI classification
    if not text or len(text.strip()) < 10:
        return {
            "category": "autre",
            "confidence": 0.0,
            "reasoning": "Texte insuffisant et nom de fichier non explicite"
        }

    truncated = text[:2000] # Shorter for better reliability
    messages = [{"role": "user", "content": f"Texte du document: {truncated}"}]

    try:
        raw = await ollama_service.chat(messages, CLASSIFICATION_PROMPT)
        json_match = re.search(r"\{.*\}", raw, re.DOTALL)
        if json_match:
            result = json.loads(json_match.group())
            if result.get("category") in DOCUMENT_CATEGORIES:
                return result
    except Exception:
        pass

    return {
        "category": "autre",
        "confidence": 0.0,
        "reasoning": "Classification AI echouee"
    }


# ---------------------------------------------------------------------------
# Stage 3 — AI Field Extraction
# ---------------------------------------------------------------------------

EXTRACTION_PROMPT = """Tu es un assistant d'extraction de donnees pour le cabinet Valoris en Tunisie.

A partir du texte d'un document de type "{doc_type}", extrais les informations suivantes si elles sont presentes.

Reponds UNIQUEMENT en JSON valide avec cette structure:
{{
    "date_document": "YYYY-MM-DD ou null",
    "montant_total": 0.00,
    "montant_ht": 0.00,
    "montant_tva": 0.00,
    "devise": "TND",
    "fournisseur": "nom ou null",
    "client_destinataire": "nom ou null",
    "numero_document": "numero ou null",
    "description": "resume en une phrase du document",
    "champs_supplementaires": {{}}
}}

Si une information n'est pas trouvee, mets null.
Ne devine pas — extrais uniquement ce qui est clairement present dans le texte."""


async def extract_fields(text: str, doc_type: str) -> dict:
    """
    Use Ollama to extract structured fields from document text.
    Returns a dict of extracted fields.
    """
    if not text or len(text.strip()) < 10:
        return {
            "date_document": None,
            "montant_total": None,
            "montant_ht": None,
            "montant_tva": None,
            "devise": "TND",
            "fournisseur": None,
            "client_destinataire": None,
            "numero_document": None,
            "description": "Texte insuffisant pour l'extraction",
            "champs_supplementaires": {}
        }

    truncated = text[:3000]
    prompt = EXTRACTION_PROMPT.format(doc_type=doc_type)
    messages = [{"role": "user", "content": f"Voici le texte du document:\n\n{truncated}"}]

    raw = await ollama_service.chat(messages, prompt)

    try:
        json_match = re.search(r"\{.*\}", raw, re.DOTALL)
        if json_match:
            return json.loads(json_match.group())
    except Exception:
        pass

    # Retry once
    retry_msg = "Ta reponse n'etait pas un JSON valide. Reponds strictement en JSON."
    messages.append({"role": "user", "content": retry_msg})
    raw_retry = await ollama_service.chat(messages, prompt)

    try:
        json_match = re.search(r"\{.*\}", raw_retry, re.DOTALL)
        if json_match:
            return json.loads(json_match.group())
    except Exception:
        pass

    return {
        "date_document": None,
        "montant_total": None,
        "montant_ht": None,
        "montant_tva": None,
        "devise": "TND",
        "fournisseur": None,
        "client_destinataire": None,
        "numero_document": None,
        "description": "Extraction echouee",
        "champs_supplementaires": {}
    }


# ---------------------------------------------------------------------------
# Stage 4 — Full Pipeline
# ---------------------------------------------------------------------------

METADATA_DIR_NAME = ".metadata"


async def process_document(file_path: Path, client_id: str) -> dict:
    """
    Full processing pipeline:
      1. Extract text (PDF or OCR)
      2. Classify document type via AI
      3. Extract structured fields via AI
      4. Save metadata JSON alongside the file
      5. Return complete processing result

    Returns a rich dict with all processing results.
    """
    logger.info(f"Processing document: {file_path.name} for client {client_id}")
    started_at = datetime.now()

    result = {
        "filename": file_path.name,
        "client_id": client_id,
        "file_path": str(file_path),
        "file_size_bytes": file_path.stat().st_size if file_path.exists() else 0,
        "processing_started_at": started_at.isoformat(),
        "status": "processing"
    }

    # --- Stage 1: Text Extraction ---
    extraction = await extract_text_from_file(file_path)
    result["extraction"] = {
        "method": extraction["method"],
        "pages": extraction["pages"],
        "text_length": len(extraction["text"]),
        "success": extraction["success"],
        "error": extraction.get("error")
    }

    if not extraction["success"]:
        result["status"] = "extraction_failed"
        result["processing_completed_at"] = datetime.now().isoformat()
        _save_metadata(file_path, result)
        return result

    # --- Stage 2: Classification ---
    classification = await classify_document(extraction["text"], file_path.name)
    result["classification"] = {
        "category": classification.get("category", "autre"),
        "confidence": classification.get("confidence", 0.0),
        "reasoning": classification.get("reasoning", "")
    }

    # --- Stage 3: Field Extraction ---
    fields = await extract_fields(
        extraction["text"],
        classification.get("category", "autre")
    )
    result["extracted_fields"] = fields

    # --- Final ---
    result["status"] = "processed"
    result["processing_completed_at"] = datetime.now().isoformat()
    duration = (datetime.now() - started_at).total_seconds()
    result["processing_duration_seconds"] = round(duration, 2)

    # --- Stage 4: Save metadata ---
    _save_metadata(file_path, result)

    logger.info(
        f"Document processed: {file_path.name} -> "
        f"{classification.get('category')} "
        f"(confidence: {classification.get('confidence', 0)}) "
        f"in {duration:.1f}s"
    )

    return result


def _save_metadata(file_path: Path, metadata: dict):
    """Save processing metadata as a JSON file next to the original."""
    meta_dir = file_path.parent / METADATA_DIR_NAME
    meta_dir.mkdir(exist_ok=True)

    meta_file = meta_dir / f"{file_path.stem}_metadata.json"
    with open(meta_file, "w", encoding="utf-8") as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)


def get_document_metadata(file_path: Path) -> Optional[dict]:
    """Load previously saved metadata for a document, if it exists."""
    meta_file = file_path.parent / METADATA_DIR_NAME / f"{file_path.stem}_metadata.json"
    if not meta_file.exists():
        return None
    with open(meta_file, "r", encoding="utf-8") as f:
        return json.load(f)
