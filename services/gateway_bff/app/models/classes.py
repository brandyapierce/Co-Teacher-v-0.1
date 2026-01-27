"""Class model for database"""

from sqlalchemy import Column, String, DateTime, Boolean, Text, ForeignKey, Integer
from sqlalchemy.orm import relationship
from datetime import datetime

from app.core.database import Base


class Class(Base):
    """Class model"""
    __tablename__ = "classes"
    
    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    grade_level = Column(String, nullable=False)
    room_number = Column(String)
    teacher_id = Column(String, nullable=False, index=True)
    school_id = Column(String)
    description = Column(Text)
    schedule = Column(Text)  # JSON string with schedule info
    capacity = Column(Integer)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    students = relationship("Student", foreign_keys="Student.class_id", back_populates="class_obj")
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            "id": self.id,
            "name": self.name,
            "grade_level": self.grade_level,
            "room_number": self.room_number,
            "teacher_id": self.teacher_id,
            "school_id": self.school_id,
            "description": self.description,
            "schedule": self.schedule,
            "capacity": self.capacity,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
