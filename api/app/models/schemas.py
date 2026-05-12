from enum import Enum
from pydantic import BaseModel


class Message(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: list[Message]
    client_name: str = "Client"


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
