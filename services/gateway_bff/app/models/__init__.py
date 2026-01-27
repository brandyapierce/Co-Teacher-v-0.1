"""Database models"""

from app.models.attendance import Student, AttendanceRecord, FaceTemplate, Rotation, RotationStudent, EvidenceMedia, Teacher, ConsentAudit
from app.models.classes import Class

__all__ = [
    "Student",
    "AttendanceRecord",
    "FaceTemplate",
    "Rotation",
    "RotationStudent",
    "EvidenceMedia",
    "Teacher",
    "ConsentAudit",
    "Class",
]
