import csv
import uuid
from datetime import datetime
from typing import List, Dict
from sqlalchemy.orm import Session

from app.models.attendance import Student, Teacher
from app.core.database import SessionLocal

class OneRosterImporter:
    def __init__(self):
        self.db = SessionLocal()
    
    def import_students(self, csv_file_path: str) -> Dict[str, int]:
        """Import students from OneRoster CSV format"""
        imported_count = 0
        error_count = 0
        
        try:
            with open(csv_file_path, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                
                for row in reader:
                    try:
                        student = Student(
                            id=str(uuid.uuid4()),
                            first_name=row.get('givenName', ''),
                            last_name=row.get('familyName', ''),
                            class_id=row.get('classId', ''),
                            grade_level=row.get('grade', ''),
                            parent_email=row.get('parentEmail', ''),
                            enrollment_date=datetime.utcnow(),
                            is_active=True
                        )
                        self.db.add(student)
                        imported_count += 1
                    except Exception as e:
                        print(f"Error importing student {row}: {e}")
                        error_count += 1
                
                self.db.commit()
        except Exception as e:
            print(f"Error reading CSV file: {e}")
            self.db.rollback()
        
        return {"imported": imported_count, "errors": error_count, "total": imported_count + error_count}
    
    def import_teachers(self, csv_file_path: str) -> Dict[str, int]:
        """Import teachers from OneRoster CSV format"""
        imported_count = 0
        error_count = 0
        
        try:
            with open(csv_file_path, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                
                for row in reader:
                    try:
                        teacher = Teacher(
                            id=str(uuid.uuid4()),
                            first_name=row.get('givenName', ''),
                            last_name=row.get('familyName', ''),
                            email=row.get('email', ''),
                            class_id=row.get('classId', ''),
                            is_active=True,
                            created_at=datetime.utcnow()
                        )
                        self.db.add(teacher)
                        imported_count += 1
                    except Exception as e:
                        print(f"Error importing teacher {row}: {e}")
                        error_count += 1
                
                self.db.commit()
        except Exception as e:
            print(f"Error reading CSV file: {e}")
            self.db.rollback()
        
        return {"imported": imported_count, "errors": error_count, "total": imported_count + error_count}
    
    def close(self):
        self.db.close()
