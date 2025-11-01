from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class AttendanceScanRequest(BaseModel):
    image_data: str  # Base64 encoded image
    teacher_id: str
    class_id: str
    location: Optional[str] = None
    confidence_threshold: float = 0.8

class DetectedStudent(BaseModel):
    student_id: str
    confidence: float
    face_box: tuple

class AttendanceScanResponse(BaseModel):
    detected_students: List[DetectedStudent]
    total_detected: int
    scan_time: datetime

class StudentResponse(BaseModel):
    id: str
    first_name: str
    last_name: str
    class_id: str
    grade_level: Optional[str] = None
    parent_email: Optional[str] = None
    is_active: bool = True
    
    class Config:
        from_attributes = True

class AttendanceRecordResponse(BaseModel):
    id: int
    student_id: str
    teacher_id: str
    scan_time: datetime
    confidence: float
    location: Optional[str] = None
    status: str = "present"
    
    class Config:
        from_attributes = True

