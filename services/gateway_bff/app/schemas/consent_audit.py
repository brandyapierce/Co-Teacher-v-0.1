from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class ConsentRequest(BaseModel):
    student_id: str
    parent_email: str
    consent_type: str  # face_template, evidence_capture, location_tracking
    granted: bool
    expires_at: Optional[datetime] = None
    consent_text: Optional[str] = None
    version: Optional[str] = None

class ConsentResponse(BaseModel):
    id: int
    student_id: str
    parent_email: str
    consent_type: str
    granted: bool
    granted_at: datetime
    expires_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class ConsentStatusResponse(BaseModel):
    student_id: str
    consent_type: str
    has_consent: bool
    granted: bool
    granted_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None

class AuditLogResponse(BaseModel):
    id: int
    user_id: str
    action: str
    resource_type: str
    resource_id: str
    timestamp: datetime
    success: bool
    error_message: Optional[str] = None
    
    class Config:
        from_attributes = True
