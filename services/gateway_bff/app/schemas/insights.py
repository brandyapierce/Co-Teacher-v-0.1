from pydantic import BaseModel
from typing import List, Optional

class InsightPattern(BaseModel):
    type: str
    description: str
    confidence: float
    explanation: str

class AttendanceInsightResponse(BaseModel):
    total_students: int
    attendance_rate: float
    total_scans: int
    date_range_days: int
    patterns: List[InsightPattern]

class RotationInsightResponse(BaseModel):
    total_rotations: int
    completed_rotations: int
    completion_rate: float
    average_arrival_time_seconds: Optional[float] = None
    patterns: List[InsightPattern]

class StudentInsightResponse(BaseModel):
    student_id: str
    student_name: str
    attendance_rate: float
    rotation_participation: int
    period_days: int
    patterns: List[InsightPattern]

