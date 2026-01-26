from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import numpy as np
import cv2
import io

from app.core.database import get_db
from app.models.attendance import AttendanceRecord, Student, FaceTemplate
from app.schemas.attendance import AttendanceScanRequest, AttendanceScanResponse, StudentResponse
from app.services.cv_service import CVService

router = APIRouter()
cv_service = CVService()


@router.post("/scan", response_model=AttendanceScanResponse)
async def scan_attendance(
    teacher_id: str = Form(...),
    image_data: UploadFile = File(...),
    class_id: Optional[str] = Form(None),
    location: Optional[str] = Form(None),
    db: Session = Depends(get_db)
):
    """
    Process attendance scan using computer vision.
    
    Args:
        teacher_id: ID of teacher taking attendance
        image_data: Image file from camera
        class_id: Optional class ID filter
        location: Optional location information
    
    Returns:
        List of detected students with confidence scores
    """
    try:
        # Read and decode image
        image_bytes = await image_data.read()
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Invalid image format")
        
        # Detect faces in image
        detected_faces = cv_service.detect_faces(image)
        
        if not detected_faces:
            return AttendanceScanResponse(
                detected_students=[],
                total_detected=0,
                scan_time=datetime.utcnow()
            )
        
        # Process each detected face
        detected_students = []
        
        for face_data in detected_faces:
            # Extract embedding
            embedding = cv_service.extract_embedding(face_data)
            
            # Match against templates
            match = cv_service.match_student(embedding, db)
            
            if match and match.get("confidence", 0) >= cv_service.confidence_threshold:
                student_id = match["student_id"]
                confidence = match["confidence"]
                
                # Record attendance
                attendance_record = cv_service.record_attendance(
                    student_id=student_id,
                    teacher_id=teacher_id,
                    confidence=confidence,
                    location=location,
                    db=db
                )
                
                # Get student info
                student = db.query(Student).filter(Student.id == student_id).first()
                if student:
                    detected_students.append({
                        "student_id": student_id,
                        "first_name": student.first_name,
                        "last_name": student.last_name,
                        "confidence": confidence,
                        "face_box": face_data.get("box"),
                        "recorded_at": attendance_record.scan_time
                    })
        
        return AttendanceScanResponse(
            detected_students=detected_students,
            total_detected=len(detected_students),
            scan_time=datetime.utcnow()
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Scan failed: {str(e)}"
        )


@router.post("/manual-record")
async def manual_attendance_record(
    student_id: str = Form(...),
    teacher_id: str = Form(...),
    location: Optional[str] = Form(None),
    db: Session = Depends(get_db)
):
    """
    Manually record attendance for a student.
    
    Args:
        student_id: Student ID
        teacher_id: Teacher ID
        location: Optional location
    """
    try:
        # Verify student exists
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Student not found")
        
        # Record attendance
        record = cv_service.record_attendance(
            student_id=student_id,
            teacher_id=teacher_id,
            confidence=1.0,  # Manual entry has full confidence
            location=location,
            db=db
        )
        
        return {
            "success": True,
            "message": f"Attendance recorded for {student.first_name} {student.last_name}",
            "record_id": record.id,
            "recorded_at": record.scan_time
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to record attendance: {str(e)}"
        )


@router.get("/records/{student_id}", response_model=List[dict])
async def get_attendance_records(
    student_id: str,
    days: int = 30,
    db: Session = Depends(get_db)
):
    """
    Get attendance records for a student.
    
    Args:
        student_id: Student ID
        days: Number of days to look back (default 30)
    """
    try:
        from datetime import timedelta
        
        # Verify student exists
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Student not found")
        
        # Get records from last N days
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        records = db.query(AttendanceRecord).filter(
            AttendanceRecord.student_id == student_id,
            AttendanceRecord.scan_time >= cutoff_date
        ).order_by(AttendanceRecord.scan_time.desc()).all()
        
        return [
            {
                "id": r.id,
                "student_id": r.student_id,
                "scan_time": r.scan_time,
                "confidence": r.confidence,
                "status": r.status,
                "location": r.location
            }
            for r in records
        ]
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get records: {str(e)}"
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


@router.get("/class-summary/{class_id}")
async def get_class_attendance_summary(
    class_id: str,
    date: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Get attendance summary for a class.
    
    Args:
        class_id: Class ID
        date: Optional date filter (YYYY-MM-DD)
    """
    try:
        from datetime import datetime as dt
        
        # Get all students in class
        students = db.query(Student).filter(Student.class_id == class_id).all()
        
        if not students:
            return {
                "class_id": class_id,
                "summary": [],
                "total_students": 0,
                "present_count": 0
            }
        
        summary = []
        present_count = 0
        
        for student in students:
            query = db.query(AttendanceRecord).filter(
                AttendanceRecord.student_id == student.id
            )
            
            # Filter by date if provided
            if date:
                try:
                    filter_date = dt.strptime(date, "%Y-%m-%d").date()
                    query = query.filter(
                        AttendanceRecord.scan_time >= dt.combine(filter_date, dt.min.time()),
                        AttendanceRecord.scan_time < dt.combine(filter_date, dt.max.time())
                    )
                except ValueError:
                    pass
            
            records = query.all()
            is_present = len(records) > 0
            
            if is_present:
                present_count += 1
            
            summary.append({
                "student_id": student.id,
                "name": f"{student.first_name} {student.last_name}",
                "present": is_present,
                "records_count": len(records),
                "last_record": records[0].scan_time if records else None
            })
        
        return {
            "class_id": class_id,
            "date_filter": date,
            "summary": summary,
            "total_students": len(students),
            "present_count": present_count,
            "attendance_rate": (present_count / len(students) * 100) if students else 0
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get summary: {str(e)}"
        )

