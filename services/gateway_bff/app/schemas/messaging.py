from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class MessageStatus(str, Enum):
    sent = "sent"
    delivered = "delivered"
    failed = "failed"
    pending = "pending"

class DigestRequest(BaseModel):
    student_id: str
    date: str
    include_evidence: bool = True
    custom_message: Optional[str] = None

class DigestContent(BaseModel):
    student_name: str
    date: str
    attendance_summary: str
    evidence_count: int
    top_artifacts: List[Dict[str, Any]]
    enrichment_suggestion: Optional[str] = None

class DigestResponse(BaseModel):
    message_id: str
    sent_at: datetime
    delivery_status: MessageStatus
    recipient_email: str
    digest_content: DigestContent

class BulkDigestRequest(BaseModel):
    class_id: str
    date: Optional[str] = None
    include_evidence: bool = True

