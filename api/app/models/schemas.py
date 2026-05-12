from enum import Enum
from pydantic import BaseModel


class Message(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: list[Message]
    client_name: str = "Client"


class FeedbackRequest(BaseModel):
    message_id: str
    client_id: str
    is_positive: bool
    comments: str | None = None


class DeadlineInfo(BaseModel):
    label: str        # ex: "TVA Juillet"
    due_date: str     # ex: "2024-07-20"
    days_left: int


class MissingDocument(BaseModel):
    name: str         # ex: "Factures juillet"
    type: str         # ex: "facture"


class AgentRequest(BaseModel):
    client_name: str
    deadlines: list[DeadlineInfo]
    missing_documents: list[MissingDocument]


class AgentResponse(BaseModel):
    should_remind: bool
    reminder_message: str
    urgency: str      # "low" | "medium" | "high"
    missing_docs_summary: str


class DocumentType(str, Enum):
    facture = "facture"
    kbis = "kbis"
    justificatif = "justificatif"
    releve_bancaire = "releve_bancaire"
    autre = "autre"


class DocumentResponse(BaseModel):
    id: str
    client_id: str
    name: str
    type: str
    status: str
    uploaded_at: str
    file_url: str


class Deadline(BaseModel):
    id: str
    client_id: str
    label: str
    due_date: str
    days_left: int
    status: str   # "upcoming" | "urgent" | "late" | "done"
    type: str     # "TVA" | "IS" | "CNSS" | "IR" | "autre"


class DeadlineCreate(BaseModel):
    client_id: str
    label: str
    due_date: str
    type: str


class ClientSummary(BaseModel):
    client_id: str
    total_deadlines: int
    urgent_deadlines: int
    late_deadlines: int
    uploaded_docs: int
    completion_percentage: float
    status: str  # "ok" | "attention" | "critique"


class CabinetDashboard(BaseModel):
    total_clients: int
    clients: list[ClientSummary]
    generated_at: str


# ---------------------------------------------------------------------------
# Document Processing Schemas
# ---------------------------------------------------------------------------

class ProcessRequest(BaseModel):
    client_id: str
    filename: str

class ExtractionResult(BaseModel):
    method: str          # "pypdf" | "ocr_image" | "ocr_pdf"
    pages: int
    text_length: int
    success: bool
    error: str | None = None

class ClassificationResult(BaseModel):
    category: str        # facture | kbis | justificatif | releve_bancaire | ...
    confidence: float
    reasoning: str

class ExtractedFields(BaseModel):
    date_document: str | None = None
    montant_total: float | None = None
    montant_ht: float | None = None
    montant_tva: float | None = None
    devise: str = "TND"
    fournisseur: str | None = None
    client_destinataire: str | None = None
    numero_document: str | None = None
    description: str | None = None
    champs_supplementaires: dict = {}

class ProcessingResponse(BaseModel):
    filename: str
    client_id: str
    status: str          # "processed" | "extraction_failed"
    extraction: ExtractionResult
    classification: ClassificationResult | None = None
    extracted_fields: ExtractedFields | None = None
    processing_duration_seconds: float | None = None

