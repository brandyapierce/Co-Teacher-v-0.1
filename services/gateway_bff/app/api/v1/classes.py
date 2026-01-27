"""Class management endpoints"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import uuid

from app.core.database import get_db
from app.models.attendance import Student
from app.models.classes import Class
from app.schemas.classes import (
    ClassCreate,
    ClassUpdate,
    ClassResponse,
    ClassDetailResponse,
    ClassListResponse,
    EnrollStudentRequest,
    StudentEnrollmentResponse,
)

router = APIRouter()


@router.get("", response_model=ClassListResponse)
async def list_classes(
    teacher_id: Optional[str] = Query(None, description="Filter by teacher ID"),
    grade_level: Optional[str] = Query(None, description="Filter by grade level"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db),
):
    """
    List all classes with optional filtering
    
    Args:
        teacher_id: Filter by teacher ID
        grade_level: Filter by grade level
        is_active: Filter by active status
        skip: Number of records to skip
        limit: Maximum number of records to return
    """
    query = db.query(Class)
    
    if teacher_id:
        query = query.filter(Class.teacher_id == teacher_id)
    if grade_level:
        query = query.filter(Class.grade_level == grade_level)
    if is_active is not None:
        query = query.filter(Class.is_active == is_active)
    
    total = query.count()
    classes = query.offset(skip).limit(limit).all()
    
    return ClassListResponse(
        total=total,
        classes=[ClassResponse.from_orm(c) for c in classes]
    )


@router.post("", response_model=ClassResponse, status_code=201)
async def create_class(
    class_data: ClassCreate,
    db: Session = Depends(get_db),
):
    """
    Create a new class
    
    Args:
        class_data: Class data to create
    
    Returns:
        Created class object
    """
    # Generate ID if not provided
    class_id = class_data.id or f"class_{uuid.uuid4().hex[:8]}"
    
    # Check if class already exists
    existing = db.query(Class).filter(Class.id == class_id).first()
    if existing:
        raise HTTPException(status_code=409, detail="Class ID already exists")
    
    # Create new class
    db_class = Class(
        id=class_id,
        name=class_data.name,
        grade_level=class_data.grade_level,
        room_number=class_data.room_number,
        teacher_id=class_data.teacher_id,
        school_id=class_data.school_id,
        description=class_data.description,
        schedule=class_data.schedule,
        capacity=class_data.capacity,
    )
    
    db.add(db_class)
    db.commit()
    db.refresh(db_class)
    
    return ClassResponse.from_orm(db_class)


@router.get("/{class_id}", response_model=ClassDetailResponse)
async def get_class(
    class_id: str,
    db: Session = Depends(get_db),
):
    """
    Get a specific class with student list
    
    Args:
        class_id: Class ID to retrieve
    
    Returns:
        Class details with enrolled students
    """
    db_class = db.query(Class).filter(Class.id == class_id).first()
    
    if not db_class:
        raise HTTPException(status_code=404, detail="Class not found")
    
    # Get enrolled students
    students = db.query(Student).filter(Student.class_id == class_id).all()
    
    response = ClassDetailResponse.from_orm(db_class)
    response.student_count = len(students)
    response.students = [
        {
            "id": s.id,
            "first_name": s.first_name,
            "last_name": s.last_name,
            "grade_level": s.grade_level,
            "parent_email": s.parent_email,
            "is_active": s.is_active,
        }
        for s in students
    ]
    
    return response


@router.put("/{class_id}", response_model=ClassResponse)
async def update_class(
    class_id: str,
    class_data: ClassUpdate,
    db: Session = Depends(get_db),
):
    """
    Update a class
    
    Args:
        class_id: Class ID to update
        class_data: Updated class data
    
    Returns:
        Updated class object
    """
    db_class = db.query(Class).filter(Class.id == class_id).first()
    
    if not db_class:
        raise HTTPException(status_code=404, detail="Class not found")
    
    # Update fields
    update_data = class_data.dict(exclude_unset=True)
    update_data["updated_at"] = datetime.utcnow()
    
    for field, value in update_data.items():
        setattr(db_class, field, value)
    
    db.commit()
    db.refresh(db_class)
    
    return ClassResponse.from_orm(db_class)


@router.delete("/{class_id}", status_code=204)
async def delete_class(
    class_id: str,
    db: Session = Depends(get_db),
):
    """
    Delete a class (soft delete - sets is_active to False)
    
    Args:
        class_id: Class ID to delete
    """
    db_class = db.query(Class).filter(Class.id == class_id).first()
    
    if not db_class:
        raise HTTPException(status_code=404, detail="Class not found")
    
    # Soft delete
    db_class.is_active = False
    db_class.updated_at = datetime.utcnow()
    
    db.commit()


@router.post("/{class_id}/enroll", response_model=StudentEnrollmentResponse)
async def enroll_student_in_class(
    class_id: str,
    enrollment_data: EnrollStudentRequest,
    db: Session = Depends(get_db),
):
    """
    Enroll a student in a class
    
    Args:
        class_id: Class ID to enroll into
        enrollment_data: Student enrollment data
    
    Returns:
        Enrollment response
    """
    # Verify class exists
    db_class = db.query(Class).filter(Class.id == class_id).first()
    if not db_class:
        raise HTTPException(status_code=404, detail="Class not found")
    
    # Verify student exists
    student = db.query(Student).filter(Student.id == enrollment_data.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Check capacity
    if db_class.capacity:
        enrolled_count = db.query(Student).filter(
            Student.class_id == class_id
        ).count()
        if enrolled_count >= db_class.capacity:
            raise HTTPException(
                status_code=400,
                detail=f"Class is full (capacity: {db_class.capacity})"
            )
    
    # Update student's class
    student.class_id = class_id
    student.grade_level = db_class.grade_level
    
    db.commit()
    db.refresh(student)
    
    return StudentEnrollmentResponse(
        success=True,
        message=f"Student {student.first_name} {student.last_name} enrolled in {db_class.name}",
        student_id=student.id,
        class_id=class_id,
        student_name=f"{student.first_name} {student.last_name}",
        class_name=db_class.name,
    )


@router.delete("/{class_id}/students/{student_id}", status_code=200)
async def remove_student_from_class(
    class_id: str,
    student_id: str,
    db: Session = Depends(get_db),
):
    """
    Remove a student from a class
    
    Args:
        class_id: Class ID to remove student from
        student_id: Student ID to remove
    """
    # Verify class exists
    db_class = db.query(Class).filter(Class.id == class_id).first()
    if not db_class:
        raise HTTPException(status_code=404, detail="Class not found")
    
    # Verify student exists and is in the class
    student = db.query(Student).filter(
        Student.id == student_id,
        Student.class_id == class_id
    ).first()
    
    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student not found in this class"
        )
    
    # Move student to unassigned class or default
    student.class_id = "UNASSIGNED"
    
    db.commit()
    
    return {
        "success": True,
        "message": f"Student {student.first_name} {student.last_name} removed from {db_class.name}"
    }


@router.get("/", response_model=List[ClassResponse])
async def list_class_by_teacher(
    teacher_id: str = Query(..., description="Teacher ID"),
    db: Session = Depends(get_db),
):
    """
    List all classes for a specific teacher
    
    Args:
        teacher_id: Teacher ID
    
    Returns:
        List of teacher's classes
    """
    classes = db.query(Class).filter(
        Class.teacher_id == teacher_id,
        Class.is_active == True
    ).all()
    
    return [ClassResponse.from_orm(c) for c in classes]
