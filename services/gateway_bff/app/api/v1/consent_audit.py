from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.core.database import get_db
from app.models.consent_audit import ConsentRecord, AuditLog
from app.schemas.consent_audit import ConsentRequest, ConsentResponse, ConsentStatusResponse

router = APIRouter()

@router.post("/consent", response_model=ConsentResponse)
async def record_consent(
    request: ConsentRequest,
    db: Session = Depends(get_db)
):
    """Record parent consent for student data processing"""
    consent = ConsentRecord(
        student_id=request.student_id,
        parent_email=request.parent_email,
        consent_type=request.consent_type,
        granted=request.granted,
        granted_at=datetime.utcnow(),
        expires_at=request.expires_at,
        consent_text=request.consent_text,
        version=request.version
    )
    db.add(consent)
    db.commit()
    db.refresh(consent)
    return ConsentResponse(**{
        "id": consent.id,
        "student_id": consent.student_id,
        "parent_email": consent.parent_email,
        "consent_type": consent.consent_type,
        "granted": consent.granted,
        "granted_at": consent.granted_at,
        "expires_at": consent.expires_at
    })

@router.get("/consent/{student_id}", response_model=ConsentStatusResponse)
async def get_consent_status(
    student_id: str,
    consent_type: str,
    db: Session = Depends(get_db)
):
    """Get current consent status for a student"""
    consent = db.query(ConsentRecord).filter(
        ConsentRecord.student_id == student_id,
        ConsentRecord.consent_type == consent_type
    ).order_by(ConsentRecord.granted_at.desc()).first()
    
    if not consent:
        return ConsentStatusResponse(
            student_id=student_id,
            consent_type=consent_type,
            has_consent=False,
            granted=False,
            granted_at=None,
            expires_at=None
        )
    
    is_valid = consent.granted and (
        consent.expires_at is None or consent.expires_at > datetime.utcnow()
    )
    
    return ConsentStatusResponse(
        student_id=student_id,
        consent_type=consent_type,
        has_consent=True,
        granted=is_valid,
        granted_at=consent.granted_at,
        expires_at=consent.expires_at
    )
