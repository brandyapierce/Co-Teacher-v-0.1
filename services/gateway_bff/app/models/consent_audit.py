from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text
from datetime import datetime

from app.core.database import Base

class ConsentRecord(Base):
    __tablename__ = "consent_records"
    
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, nullable=False)
    parent_email = Column(String, nullable=False)
    consent_type = Column(String, nullable=False)  # face_template, evidence_capture, location_tracking
    granted = Column(Boolean, nullable=False)
    granted_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)
    ip_address = Column(String)
    user_agent = Column(Text)
    consent_text = Column(Text)
    version = Column(String)  # Version of consent text

class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, nullable=False)
    action = Column(String, nullable=False)  # login, face_enrollment, consent_granted, etc.
    resource_type = Column(String, nullable=False)  # student, teacher, attendance, etc.
    resource_id = Column(String, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    ip_address = Column(String)
    user_agent = Column(Text)
    details = Column(Text)  # JSON string with additional details
    success = Column(Boolean, default=True)
    error_message = Column(Text)

