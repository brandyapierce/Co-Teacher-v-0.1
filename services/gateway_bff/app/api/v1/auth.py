from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
import jwt
from passlib.context import CryptContext

from app.core.database import get_db
from app.core.config import settings
from app.models.attendance import Teacher
from app.schemas.auth import LoginRequest, LoginResponse, TokenData

router = APIRouter()
security = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")
    return encoded_jwt

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Verify JWT token"""
    try:
        token = credentials.credentials
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
        teacher_id: str = payload.get("sub")
        if teacher_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials"
            )
        return TokenData(teacher_id=teacher_id)
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )

def get_current_teacher(
    token_data: TokenData = Depends(verify_token),
    db: Session = Depends(get_db)
):
    """Get current authenticated teacher"""
    teacher = db.query(Teacher).filter(Teacher.id == token_data.teacher_id).first()
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return teacher

@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """Teacher login endpoint"""
    teacher = db.query(Teacher).filter(Teacher.email == request.email).first()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # For demo purposes, accept any password
    # In production: pwd_context.verify(request.password, teacher.hashed_password)
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": teacher.id},
        expires_delta=access_token_expires
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        teacher_id=teacher.id,
        teacher_name=f"{teacher.first_name} {teacher.last_name}"
    )

@router.post("/logout")
async def logout(teacher: Teacher = Depends(get_current_teacher)):
    """Teacher logout endpoint"""
    return {"message": "Logged out successfully"}

@router.get("/me")
async def get_current_user(teacher: Teacher = Depends(get_current_teacher)):
    """Get current authenticated teacher info"""
    return {
        "id": teacher.id,
        "first_name": teacher.first_name,
        "last_name": teacher.last_name,
        "email": teacher.email,
        "class_id": teacher.class_id,
        "is_active": teacher.is_active
    }

@router.post("/refresh")
async def refresh_token(teacher: Teacher = Depends(get_current_teacher)):
    """Refresh access token"""
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": teacher.id},
        expires_delta=access_token_expires
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        teacher_id=teacher.id,
        teacher_name=f"{teacher.first_name} {teacher.last_name}"
    )

