from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.core.database import get_db
from app.models.attendance import Rotation, RotationStudent
from app.schemas.rotations import RotationCreateRequest, RotationResponse

router = APIRouter()

@router.post("/", response_model=RotationResponse)
async def create_rotation(
    request: RotationCreateRequest,
    db: Session = Depends(get_db)
):
    """Create a new rotation"""
    rotation = Rotation(
        name=request.name,
        class_id=request.class_id,
        teacher_id=request.teacher_id,
        start_time=request.start_time,
        end_time=request.end_time,
        destination=request.destination,
        status="scheduled"
    )
    db.add(rotation)
    db.commit()
    db.refresh(rotation)
    return RotationResponse(**{
        "id": rotation.id,
        "name": rotation.name,
        "class_id": rotation.class_id,
        "teacher_id": rotation.teacher_id,
        "start_time": rotation.start_time,
        "end_time": rotation.end_time,
        "status": rotation.status,
        "destination": rotation.destination
    })

@router.get("/", response_model=List[RotationResponse])
async def get_rotations(
    class_id: str,
    db: Session = Depends(get_db)
):
    """Get rotations for a class"""
    rotations = db.query(Rotation).filter(Rotation.class_id == class_id).all()
    return [RotationResponse(**{
        "id": r.id,
        "name": r.name,
        "class_id": r.class_id,
        "teacher_id": r.teacher_id,
        "start_time": r.start_time,
        "end_time": r.end_time,
        "status": r.status,
        "destination": r.destination
    }) for r in rotations]
