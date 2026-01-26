import cv2
import numpy as np
from typing import List, Optional, Tuple, Dict
from sqlalchemy.orm import Session
import pickle
from datetime import datetime
import base64
from io import BytesIO
from PIL import Image
import mediapipe as mp

from app.models.attendance import Student, FaceTemplate, AttendanceRecord
from app.core.config import settings

class CVService:
    """Computer Vision Service for face detection, embedding extraction, and matching"""
    
    def __init__(self):
        # Initialize MediaPipe for face detection
        self.mp_face_detection = mp.solutions.face_detection
        self.face_detector = self.mp_face_detection.FaceDetection(
            model_selection=1,  # 1 = full range, 0 = short range
            min_detection_confidence=0.5
        )
        
        # Fallback cascade classifier
        self.face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        )
        
        self.confidence_threshold = getattr(settings, 'FACE_RECOGNITION_THRESHOLD', 0.6)
        self.embedding_dim = 128
    
    def detect_faces(self, image: np.ndarray) -> List[Dict]:
        """Detect faces in image using MediaPipe"""
        # Convert BGR to RGB for MediaPipe
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        results = self.face_detector.process(image_rgb)
        
        detected_faces = []
        if results.detections:
            h, w, _ = image.shape
            for detection in results.detections:
                bbox = detection.location_data.relative_bounding_box
                
                # Convert relative coordinates to absolute
                x = int(bbox.xmin * w)
                y = int(bbox.ymin * h)
                width = int(bbox.width * w)
                height = int(bbox.height * h)
                
                # Ensure bounds are valid
                x = max(0, x)
                y = max(0, y)
                width = min(width, w - x)
                height = min(height, h - y)
                
                face_region = image[y:y+height, x:x+width]
                confidence = detection.score[0] if detection.score else 0.5
                
                detected_faces.append({
                    "image": face_region,
                    "box": (x, y, width, height),
                    "confidence": float(confidence)
                })
        
        return detected_faces
    
    def extract_embedding(self, face_data: Dict) -> np.ndarray:
        """
        Extract face embedding from face image.
        
        Phase 1: Simple feature extraction (histogram-based)
        Phase 2: Upgrade to MobileFaceNet TFLite model
        """
        face_image = face_data.get("image")
        if face_image is None or face_image.size == 0:
            return np.zeros(self.embedding_dim, dtype=np.float32)
        
        # Normalize image
        face_image = cv2.resize(face_image, (128, 128))
        face_image_normalized = face_image.astype(np.float32) / 255.0
        
        # Phase 1: Simple feature extraction
        # Combine multiple features for robustness
        embedding = self._extract_simple_features(face_image_normalized)
        
        # Normalize embedding to unit vector
        norm = np.linalg.norm(embedding)
        if norm > 0:
            embedding = embedding / norm
        
        return embedding.astype(np.float32)
    
    def _extract_simple_features(self, image: np.ndarray) -> np.ndarray:
        """Extract simple features from normalized image"""
        features = []
        
        # Convert to grayscale if color
        if len(image.shape) == 3:
            gray = cv2.cvtColor((image * 255).astype(np.uint8), cv2.COLOR_BGR2GRAY).astype(np.float32) / 255.0
        else:
            gray = image
        
        # 1. Histogram of grayscale (32 bins)
        hist, _ = np.histogram(gray, bins=32, range=(0, 1))
        features.extend(hist)
        
        # 2. Edge features using Sobel (16 values)
        sobelx = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
        sobely = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)
        edge_features = [
            np.mean(sobelx), np.std(sobelx),
            np.mean(sobely), np.std(sobely),
            np.mean(np.sqrt(sobelx**2 + sobely**2)),
            np.max(sobelx), np.max(sobely),
            np.percentile(gray, 25), np.percentile(gray, 50),
            np.percentile(gray, 75),
            np.var(gray), np.mean(gray),
            np.max(gray), np.min(gray),
            np.std(gray),
            np.sum(sobelx > 0.1) / sobelx.size
        ]
        features.extend(edge_features)
        
        # 3. Color statistics if color image (8 values)
        if len(image.shape) == 3:
            for channel in range(3):
                features.append(np.mean(image[:, :, channel]))
                features.append(np.std(image[:, :, channel]))
        
        # Pad or trim to exact embedding dimension
        features = np.array(features, dtype=np.float32)
        if len(features) > self.embedding_dim:
            features = features[:self.embedding_dim]
        else:
            features = np.pad(features, (0, self.embedding_dim - len(features)), mode='constant')
        
        return features
    
    def match_student(self, embedding: np.ndarray, db: Session) -> Optional[Dict]:
        """Match face embedding against stored templates with temporal smoothing"""
        templates = db.query(FaceTemplate).all()
        
        if not templates:
            return None
        
        best_match = None
        best_confidence = 0.0
        
        for template in templates:
            try:
                stored_embedding = pickle.loads(
                    template.embedding_data.encode('latin1')
                )
            except Exception:
                continue
            
            similarity = self._cosine_similarity(embedding, stored_embedding)
            
            if similarity > self.confidence_threshold and similarity > best_confidence:
                best_confidence = similarity
                best_match = {
                    "student_id": template.student_id,
                    "confidence": float(similarity)
                }
        
        return best_match
    
    def store_face_template(
        self, 
        student_id: str, 
        embedding: np.ndarray, 
        db: Session,
        overwrite: bool = False
    ) -> FaceTemplate:
        """Store or update face template for student"""
        existing = db.query(FaceTemplate).filter(
            FaceTemplate.student_id == student_id
        ).first()
        
        embedding_pickled = pickle.dumps(embedding).decode('latin1')
        
        if existing and not overwrite:
            # Average with existing embedding for better robustness
            existing_emb = pickle.loads(existing.embedding_data.encode('latin1'))
            averaged_emb = (existing_emb + embedding) / 2.0
            norm = np.linalg.norm(averaged_emb)
            if norm > 0:
                averaged_emb = averaged_emb / norm
            existing.embedding_data = pickle.dumps(averaged_emb).decode('latin1')
            existing.updated_at = datetime.utcnow()
            template = existing
        else:
            template = FaceTemplate(
                student_id=student_id,
                embedding_data=embedding_pickled,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            if existing:
                db.delete(existing)
            db.add(template)
        
        db.commit()
        db.refresh(template)
        return template
    
    def get_face_template(self, student_id: str, db: Session) -> Optional[FaceTemplate]:
        """Retrieve face template for student"""
        return db.query(FaceTemplate).filter(
            FaceTemplate.student_id == student_id
        ).first()
    
    def delete_face_template(self, student_id: str, db: Session) -> bool:
        """Delete face template for student"""
        template = db.query(FaceTemplate).filter(
            FaceTemplate.student_id == student_id
        ).first()
        
        if template:
            db.delete(template)
            db.commit()
            return True
        return False
    
    def record_attendance(
        self,
        student_id: str,
        teacher_id: str,
        confidence: float,
        location: Optional[str] = None,
        db: Session = None
    ) -> AttendanceRecord:
        """Record attendance for matched student"""
        if db is None:
            raise ValueError("Database session required")
        
        # Determine status based on time (TODO: implement proper time-based logic)
        status = "present"
        
        record = AttendanceRecord(
            student_id=student_id,
            teacher_id=teacher_id,
            confidence=confidence,
            location=location,
            status=status,
            scan_time=datetime.utcnow()
        )
        
        db.add(record)
        db.commit()
        db.refresh(record)
        return record
    
    def _cosine_similarity(self, a: np.ndarray, b: np.ndarray) -> float:
        """Calculate cosine similarity between two embeddings"""
        # Ensure proper data types
        a = np.asarray(a, dtype=np.float32).flatten()
        b = np.asarray(b, dtype=np.float32).flatten()
        
        dot_product = np.dot(a, b)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        
        if norm_a < 1e-6 or norm_b < 1e-6:
            return 0.0
        
        similarity = dot_product / (norm_a * norm_b)
        # Clamp to [-1, 1] range
        return float(np.clip(similarity, -1.0, 1.0))
    
    def decode_image_from_base64(self, image_data: str) -> np.ndarray:
        """Decode image from base64 string"""
        try:
            image_bytes = base64.b64decode(image_data)
            image_pil = Image.open(BytesIO(image_bytes))
            image_np = cv2.cvtColor(np.array(image_pil), cv2.COLOR_RGB2BGR)
            return image_np
        except Exception as e:
            raise ValueError(f"Failed to decode image: {str(e)}")
    
    def encode_image_to_base64(self, image: np.ndarray) -> str:
        """Encode image to base64 string"""
        _, buffer = cv2.imencode('.jpg', image)
        image_base64 = base64.b64encode(buffer).decode('utf-8')
        return image_base64
    
    def get_statistics(self, db: Session) -> Dict:
        """Get CV system statistics"""
        total_students_enrolled = db.query(FaceTemplate).distinct(
            FaceTemplate.student_id
        ).count()
        total_attendance_records = db.query(AttendanceRecord).count()
        
        return {
            "enrolled_students": total_students_enrolled,
            "total_attendance_records": total_attendance_records,
            "confidence_threshold": self.confidence_threshold,
            "embedding_dimension": self.embedding_dim
        }

