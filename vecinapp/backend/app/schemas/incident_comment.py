from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class IncidentCommentCreate(BaseModel):
    """Schema para crear un comentario"""
    comment_text: str

class IncidentComment(BaseModel):
    """Schema completo de un comentario de incidente"""
    id: Optional[str] = None
    incident_id: Optional[str] = None  # Opcional porque se infiere del path
    user_id: Optional[str] = None      # Opcional porque se obtiene del auth
    user_name: str
    user_role: str
    comment_text: str
    created_at: datetime
    
    class Config:
        from_attributes = True
