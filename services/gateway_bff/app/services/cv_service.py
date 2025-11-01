import cv2
import numpy as np
from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
import pickle
from datetime import datetime

from app.models.attendance import Student, FaceTemplate
from app.core.config import settings

class CVService:
    def __init__(self):
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.confidence_threshold = settings.FACE_RECOGNITION_THRESHOLD
        
    def detect_faces(self, image: np.ndarray) -> List[dict]:
        """Detect faces in image"""
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        faces = self.face_cascade.detectMultiScale(
            gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30)
        )
        
        detected_faces = []
        for (x, y, w, h) in faces:
            face_region = image[y:y+h, x:x+w]
            detected_faces.append({
                "image": face_region,
                "box": (x, y, w, h),
                "confidence": 0.9
            })
        return detected_faces
    
    def extract_embedding(self, face_data: dict) -> np.ndarray:
        """Extract face embedding (placeholder - use real model in production)"""
        face_image = face_data["image"]
        face_image = cv2.resize(face_image, (112, 112))
        face_image = face_image.astype(np.float32) / 255.0
        embedding = np.random.rand(512).astype(np.float32)
        return embedding
    
    def match_student(self, embedding: np.ndarray, db: Session) -> Optional[dict]:
        """Match face embedding against stored templates"""
        templates = db.query(FaceTemplate).all()
        best_match = None
        best_confidence = 0.0
        
        for template in templates:
            stored_embedding = pickle.loads(template.embedding_data.encode('latin1'))
            similarity = self._cosine_similarity(embedding, stored_embedding)
            
            if similarity > self.confidence_threshold and similarity > best_confidence:
                best_confidence = similarity
                best_match = {"id": template.student_id, "confidence": similarity}
        
        return best_match
    
    def store_face_template(self, student_id: str, embedding: np.ndarray, db: Session):
        """Store face template for student"""
        existing = db.query(FaceTemplate).filter(FaceTemplate.student_id == student_id).first()
        
        if existing:
            existing.embedding_data = pickle.dumps(embedding).decode('latin1')
            existing.updated_at = datetime.utcnow()
        else:
            template = FaceTemplate(
                student_id=student_id,
                embedding_data=pickle.dumps(embedding).decode('latin1'),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.add(template)
        db.commit()
    
    def _cosine_similarity(self, a: np.ndarray, b: np.ndarray) -> float:
        """Calculate cosine similarity"""
        dot_product = np.dot(a, b)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        if norm_a == 0 or norm_b == 0:
            return 0.0
        return dot_product / (norm_a * norm_b)

