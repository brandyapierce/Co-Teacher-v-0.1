from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import base64

from app.core.database import get_db
from app.models.attendance import AttendanceRecord, Student
from app.schemas.attendance import AttendanceScanRequest, AttendanceScanResponse, StudentResponse

router = APIRouter()

@router.post("/scan", response_model=AttendanceScanResponse)
async def scan_attendance(
    request: AttendanceScanRequest,
    db: Session = Depends(get_db)
):
    """Process attendance scan using computer vision"""
    # Placeholder - CV service integration needed
    detected_students = []
    
    return AttendanceScanResponse(
        detected_students=detected_students,
        total_detected=len(detected_students),
        scan_time=datetime.utcnow()
    )

@router.get("/students", response_model=List[StudentResponse])
async def get_students(
    class_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get list of students"""
    query = db.query(Student)
    if class_id:
        query = query.filter(Student.class_id == class_id)
    students = query.all()
    return [StudentResponse(**{
        "id": s.id,
        "first_name": s.first_name,
        "last_name": s.last_name,
        "class_id": s.class_id,
        "grade_level": s.grade_level,
        "parent_email": s.parent_email,
        "is_active": s.is_active
    }) for s in students]

