from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime
from enum import Enum

class RotationStatus(str, Enum):
    scheduled = "scheduled"
    active = "active"
    completed = "completed"

class RotationCreateRequest(BaseModel):
    name: str
    class_id: str
    teacher_id: str
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    destination: str
    student_ids: List[str]

class RotationUpdateRequest(BaseModel):
    status: Optional[RotationStatus] = None
    student_status: Optional[Dict[str, str]] = None

class RotationStudentResponse(BaseModel):
    id: int
    rotation_id: int
    student_id: str
    assigned_destination: str
    arrival_time: Optional[datetime] = None
    status: str
    
    class Config:
        from_attributes = True

class RotationResponse(BaseModel):
    id: int
    name: str
    class_id: str
    teacher_id: str
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    status: str
    destination: str
    
    class Config:
        from_attributes = True
