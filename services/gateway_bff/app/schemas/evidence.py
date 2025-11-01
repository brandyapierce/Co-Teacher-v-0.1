from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class EvidenceUploadResponse(BaseModel):
    id: int
    file_path: str
    redacted_path: Optional[str] = None
    created_at: datetime

class EvidenceResponse(BaseModel):
    id: int
    student_id: str
    teacher_id: str
    file_path: str
    file_type: str
    redacted_path: Optional[str] = None
    created_at: datetime
    retention_days: int
    
    class Config:
        from_attributes = True

class EvidenceListResponse(BaseModel):
    evidence: List[EvidenceResponse]
    total_count: int
    limit: int
    offset: int
