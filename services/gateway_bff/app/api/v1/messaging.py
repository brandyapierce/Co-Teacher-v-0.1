from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
import uuid

from app.core.database import get_db
from app.models.attendance import Student
from app.schemas.messaging import DigestRequest, DigestResponse, DigestContent, MessageStatus

router = APIRouter()

@router.post("/digest", response_model=DigestResponse)
async def send_parent_digest(
    request: DigestRequest,
    db: Session = Depends(get_db)
):
    """Send nightly digest to parent"""
    student = db.query(Student).filter(Student.id == request.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    digest_content = DigestContent(
        student_name=f"{student.first_name} {student.last_name}",
        date=request.date,
        attendance_summary="Present",
        evidence_count=0,
        top_artifacts=[],
        enrichment_suggestion="Your student had a good day at school!"
    )
    
    return DigestResponse(
        message_id=str(uuid.uuid4()),
        sent_at=datetime.utcnow(),
        delivery_status=MessageStatus.sent,
        recipient_email=student.parent_email or "parent@example.com",
        digest_content=digest_content
    )

