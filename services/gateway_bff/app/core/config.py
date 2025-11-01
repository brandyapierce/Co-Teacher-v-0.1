from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/coteacher"
    REDIS_URL: str = "redis://localhost:6379"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080"]
    
    # CV Configuration
    FACE_DETECTION_CONFIDENCE: float = 0.7
    FACE_RECOGNITION_THRESHOLD: float = 0.6
    MAX_FACE_TEMPLATES: int = 5
    
    # Location Configuration
    GEOFENCE_RADIUS: float = 100.0
    LOCATION_UPDATE_INTERVAL: int = 30
    
    # Attendance Configuration
    ATTENDANCE_SCAN_TIMEOUT: int = 120
    ATTENDANCE_CONFIDENCE_THRESHOLD: float = 0.8
    
    # File Storage
    UPLOAD_DIR: str = "uploads"
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    
    model_config = {
        "env_file": ".env",
        "case_sensitive": True
    }

settings = Settings()

