"""Pydantic schemas for class management"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ClassBase(BaseModel):
    """Base class schema"""
    name: str = Field(..., min_length=1, max_length=255, description="Class name")
    grade_level: str = Field(..., description="Grade level (e.g., '3A', '4B')")
    room_number: Optional[str] = Field(None, description="Room number/location")
    teacher_id: str = Field(..., description="Teacher ID")
    school_id: Optional[str] = Field(None, description="School ID")
    description: Optional[str] = Field(None, description="Class description")
    schedule: Optional[str] = Field(None, description="Class schedule (JSON)")
    capacity: Optional[int] = Field(None, ge=1, description="Class capacity")


class ClassCreate(ClassBase):
    """Create class schema"""
    id: Optional[str] = Field(None, description="Class ID (auto-generated if not provided)")


class ClassUpdate(BaseModel):
    """Update class schema"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    grade_level: Optional[str] = None
    room_number: Optional[str] = None
    teacher_id: Optional[str] = None
    school_id: Optional[str] = None
    description: Optional[str] = None
    schedule: Optional[str] = None
    capacity: Optional[int] = Field(None, ge=1)
    is_active: Optional[bool] = None


class ClassResponse(ClassBase):
    """Class response schema"""
    id: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ClassDetailResponse(ClassResponse):
    """Class detail response with students"""
    student_count: int = 0
    students: Optional[List[dict]] = None


class EnrollStudentRequest(BaseModel):
    """Request to enroll student in class"""
    student_id: str = Field(..., description="Student ID to enroll")
    class_id: str = Field(..., description="Class ID to enroll in")


class ClassListResponse(BaseModel):
    """Class list response"""
    total: int
    classes: List[ClassResponse]


class StudentEnrollmentResponse(BaseModel):
    """Response for student enrollment"""
    success: bool
    message: str
    student_id: Optional[str] = None
    class_id: Optional[str] = None
    student_name: Optional[str] = None
    class_name: Optional[str] = None


class ClassSchedule(BaseModel):
    """Class schedule entry"""
    day_of_week: str  # monday, tuesday, etc.
    start_time: str  # HH:MM format
    end_time: str  # HH:MM format
    location: Optional[str] = None
