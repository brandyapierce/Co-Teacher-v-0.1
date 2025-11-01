from pydantic import BaseModel, EmailStr
from typing import Optional

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int
    teacher_id: str
    teacher_name: str

class TokenData(BaseModel):
    teacher_id: str

class TeacherResponse(BaseModel):
    id: str
    first_name: str
    last_name: str
    email: str
    class_id: Optional[str] = None
    is_active: bool
    
    class Config:
        from_attributes = True

