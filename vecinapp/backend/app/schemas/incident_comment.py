from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class IncidentCommentBase(BaseModel):
    comment_text: str

class IncidentCommentCreate(IncidentCommentBase):
    pass

class IncidentComment(IncidentCommentBase):
    id: str
    incident_id: str
    user_id: str
    user_name: str
    user_role: str  # 'administrator' or 'resident'
    created_at: datetime = Field(default_factory=datetime.now)
    is_resolution_comment: bool = False

    class Config:
        from_attributes = True
