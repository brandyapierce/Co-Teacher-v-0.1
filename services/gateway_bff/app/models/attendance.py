from sqlalchemy import Column, Integer, String, DateTime, Float, Text, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

from app.core.database import Base

class Student(Base):
    __tablename__ = "students"
    
    id = Column(String, primary_key=True)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    class_id = Column(String, nullable=False)
    grade_level = Column(String)
    parent_email = Column(String)
    enrollment_date = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    
    # Relationships
    attendance_records = relationship("AttendanceRecord", back_populates="student")
    face_templates = relationship("FaceTemplate", back_populates="student")

class AttendanceRecord(Base):
    __tablename__ = "attendance_records"
    
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, ForeignKey("students.id"), nullable=False)
    teacher_id = Column(String, nullable=False)
    scan_time = Column(DateTime, default=datetime.utcnow)
    confidence = Column(Float, nullable=False)
    location = Column(String)
    status = Column(String, default="present")  # present, absent, late
    
    # Relationships
    student = relationship("Student", back_populates="attendance_records")

class FaceTemplate(Base):
    __tablename__ = "face_templates"
    
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, ForeignKey("students.id"), nullable=False)
    embedding_data = Column(Text, nullable=False)  # Pickled embedding
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    student = relationship("Student", back_populates="face_templates")

class Rotation(Base):
    __tablename__ = "rotations"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    class_id = Column(String, nullable=False)
    teacher_id = Column(String, nullable=False)
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    status = Column(String, default="scheduled")  # scheduled, active, completed
    destination = Column(String)
    
    # Relationships
    rotation_students = relationship("RotationStudent", back_populates="rotation")

class RotationStudent(Base):
    __tablename__ = "rotation_students"
    
    id = Column(Integer, primary_key=True, index=True)
    rotation_id = Column(Integer, ForeignKey("rotations.id"), nullable=False)
    student_id = Column(String, ForeignKey("students.id"), nullable=False)
    assigned_destination = Column(String)
    arrival_time = Column(DateTime)
    status = Column(String, default="assigned")  # assigned, in_transit, arrived
    
    # Relationships
    rotation = relationship("Rotation", back_populates="rotation_students")

class EvidenceMedia(Base):
    __tablename__ = "evidence_media"
    
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, ForeignKey("students.id"), nullable=False)
    teacher_id = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    file_type = Column(String, nullable=False)  # image, video
    redacted_path = Column(String)  # Path to redacted version
    created_at = Column(DateTime, default=datetime.utcnow)
    retention_days = Column(Integer, default=30)
    
    # Relationships
    student = relationship("Student")

class Teacher(Base):
    __tablename__ = "teachers"
    
    id = Column(String, primary_key=True)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    class_id = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class ConsentAudit(Base):
    __tablename__ = "consent_audit"
    
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, ForeignKey("students.id"), nullable=False)
    action = Column(String, nullable=False)  # enrolled, updated, withdrawn
    consent_type = Column(String, nullable=False)  # face_template, evidence_capture, location_tracking
    granted_by = Column(String)  # Parent/guardian email or ID
    granted_at = Column(DateTime, default=datetime.utcnow)
    notes = Column(Text)
    
    # Relationships
    student = relationship("Student")

