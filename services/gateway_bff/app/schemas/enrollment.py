"""Enrollment request/response schemas"""

from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


class EnrollmentRequest(BaseModel):
    """Request for enrolling a student"""
    student_id: str = Field(..., description="Student ID")
    image_data: str = Field(..., description="Base64 encoded image data")
    pose_index: int = Field(default=0, description="Which pose this is (0-4)")
    
    class Config:
        json_schema_extra = {
            "example": {
                "student_id": "STU001",
                "image_data": "base64_encoded_image_here",
                "pose_index": 0,
            }
        }


class EnrollmentResponse(BaseModel):
    """Response from enrollment endpoint"""
    success: bool
    message: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    student_id: str
    template_id: Optional[int] = None
    is_enrolled: Optional[bool] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "message": "Face enrolled successfully (pose 0)",
                "confidence": 0.95,
                "student_id": "STU001",
                "template_id": 1,
                "is_enrolled": True,
            }
        }


class StudentEnrollmentInfo(BaseModel):
    """Info about a student's enrollment status"""
    student_id: str
    first_name: str
    last_name: str
    is_enrolled: bool
    enrolled_at: Optional[datetime] = None


class EnrollmentListResponse(BaseModel):
    """Response for enrollment list"""
    class_id: str
    total_students: int
    enrolled_students: int
    students: List[StudentEnrollmentInfo]


class EnrollmentProgressResponse(BaseModel):
    """Response for enrollment progress"""
    class_id: str
    total_students: int
    enrolled: int
    progress_percent: float = Field(..., ge=0.0, le=100.0)


class EnrollmentStatsResponse(BaseModel):
    """CV system statistics"""
    enrolled_students: int
    total_attendance_records: int
    confidence_threshold: float
    embedding_dimension: int
