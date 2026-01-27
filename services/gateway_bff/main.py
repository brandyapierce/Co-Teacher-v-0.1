from fastapi import FastAPI, Depends, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
import uvicorn
import os
from dotenv import load_dotenv
from contextlib import asynccontextmanager

from app.core.config import settings
from app.core.database import init_db
from app.api.v1 import auth, attendance, rotations, evidence, insights, messaging, consent_audit, enrollment, classes, reports
from app.core.websocket import ConnectionManager
# Import all models to register them with SQLAlchemy Base
from app.models import (
    Student, AttendanceRecord, FaceTemplate, Rotation, RotationStudent,
    EvidenceMedia, Teacher, ConsentAudit, Class
)

load_dotenv()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db()
    yield
    # Shutdown
    pass

app = FastAPI(
    title="My AI CoTeacher API",
    description="Privacy-first classroom management system",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# WebSocket connection manager
manager = ConnectionManager()

# Include routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(attendance.router, prefix="/api/v1/attendance", tags=["attendance"])
app.include_router(enrollment.router, prefix="/api/v1/enrollment", tags=["enrollment"])
app.include_router(classes.router, prefix="/api/v1/classes", tags=["classes"])
app.include_router(rotations.router, prefix="/api/v1/rotations", tags=["rotations"])
app.include_router(evidence.router, prefix="/api/v1/evidence", tags=["evidence"])
app.include_router(insights.router, prefix="/api/v1/insights", tags=["insights"])
app.include_router(messaging.router, prefix="/api/v1/messaging", tags=["messaging"])
app.include_router(consent_audit.router, prefix="/api/v1/consent", tags=["consent"])
app.include_router(reports.router, tags=["reports"])

@app.get("/")
async def root():
    return {"message": "My AI CoTeacher API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0"}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(data)
    except WebSocketDisconnect:
        manager.disconnect(websocket)

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )

