"""Face enrollment endpoints for CV pipeline"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import numpy as np
import io
import cv2

from app.core.database import get_db
from app.models.attendance import FaceTemplate, Student
from app.services.cv_service import CVService
from app.schemas.enrollment import (
    EnrollmentRequest,
    EnrollmentResponse,
    EnrollmentListResponse,
    EnrollmentProgressResponse,
)

router = APIRouter()
cv_service = CVService()


@router.post("/enroll", response_model=EnrollmentResponse)
async def enroll_student(
    student_id: str = Form(...),
    image_data: UploadFile = File(...),
    pose_index: int = Form(default=0),
    db: Session = Depends(get_db),
):
    """
    Enroll a student with a face image.
    
    Args:
        student_id: Student ID to enroll
        image_data: Image file (JPEG/PNG)
        pose_index: Which pose this is (0-4 for multi-pose enrollment)
    
    Returns:
        Enrollment response with success status and confidence
    """
    try:
        # Verify student exists
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Student not found")
        
        # Read and decode image
        image_bytes = await image_data.read()
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Invalid image format")
        
        # Detect faces
        faces = cv_service.detect_faces(image)
        
        if not faces:
            return EnrollmentResponse(
                success=False,
                message="No face detected in image",
                confidence=0.0,
                student_id=student_id,
            )
        
        # Use first detected face
        face = faces[0]
        if face["confidence"] < 0.5:
            return EnrollmentResponse(
                success=False,
                message=f"Face confidence too low: {face['confidence']:.2f}",
                confidence=face["confidence"],
                student_id=student_id,
            )
        
        # Extract embedding
        embedding = cv_service.extract_embedding(face)
        
        # Store template (average with existing if not first pose)
        template = cv_service.store_face_template(
            student_id=student_id,
            embedding=embedding,
            db=db,
            overwrite=(pose_index == 0)
        )
        
        return EnrollmentResponse(
            success=True,
            message=f"Face enrolled successfully (pose {pose_index})",
            confidence=float(face["confidence"]),
            student_id=student_id,
            template_id=template.id,
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Enrollment failed: {str(e)}"
        )


@router.get("/status/{student_id}", response_model=EnrollmentResponse)
async def get_enrollment_status(
    student_id: str,
    db: Session = Depends(get_db),
):
    """Get enrollment status for a student"""
    try:
        # Verify student exists
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Student not found")
        
        # Check if enrolled
        template = cv_service.get_face_template(student_id, db)
        
        if template:
            return EnrollmentResponse(
                success=True,
                message="Student is enrolled",
                confidence=1.0,
                student_id=student_id,
                template_id=template.id,
                is_enrolled=True,
            )
        else:
            return EnrollmentResponse(
                success=False,
                message="Student is not enrolled",
                confidence=0.0,
                student_id=student_id,
                is_enrolled=False,
            )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Status check failed: {str(e)}"
        )


@router.delete("/unenroll/{student_id}")
async def unenroll_student(
    student_id: str,
    db: Session = Depends(get_db),
):
    """Unenroll a student (delete face template)"""
    try:
        # Verify student exists
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Student not found")
        
        # Delete template
        success = cv_service.delete_face_template(student_id, db)
        
        return {
            "success": success,
            "message": "Student unenrolled" if success else "Student was not enrolled",
            "student_id": student_id,
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Unenroll failed: {str(e)}"
        )


@router.get("/list/{class_id}", response_model=EnrollmentListResponse)
async def get_enrollment_list(
    class_id: str,
    db: Session = Depends(get_db),
):
    """Get enrollment status for all students in a class"""
    try:
        # Get all students in class
        students = db.query(Student).filter(Student.class_id == class_id).all()
        
        enrollment_data = []
        for student in students:
            template = cv_service.get_face_template(student.id, db)
            enrollment_data.append({
                "student_id": student.id,
                "first_name": student.first_name,
                "last_name": student.last_name,
                "is_enrolled": template is not None,
                "enrolled_at": template.created_at if template else None,
            })
        
        return EnrollmentListResponse(
            class_id=class_id,
            total_students=len(students),
            enrolled_students=sum(1 for e in enrollment_data if e["is_enrolled"]),
            students=enrollment_data,
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get enrollment list: {str(e)}"
        )


@router.get("/progress/{class_id}", response_model=EnrollmentProgressResponse)
async def get_enrollment_progress(
    class_id: str,
    db: Session = Depends(get_db),
):
    """Get enrollment progress for a class"""
    try:
        students = db.query(Student).filter(Student.class_id == class_id).all()
        
        if not students:
            return EnrollmentProgressResponse(
                class_id=class_id,
                total_students=0,
                enrolled=0,
                progress_percent=0.0,
            )
        
        # Count enrolled students
        enrolled_count = 0
        for student in students:
            template = cv_service.get_face_template(student.id, db)
            if template:
                enrolled_count += 1
        
        total = len(students)
        progress_percent = (enrolled_count / total * 100) if total > 0 else 0
        
        return EnrollmentProgressResponse(
            class_id=class_id,
            total_students=total,
            enrolled=enrolled_count,
            progress_percent=progress_percent,
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get enrollment progress: {str(e)}"
        )


@router.get("/stats")
async def get_cv_statistics(db: Session = Depends(get_db)):
    """Get CV system statistics"""
    try:
        stats = cv_service.get_statistics(db)
        return {
            "success": True,
            "data": stats,
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get statistics: {str(e)}"
        )
