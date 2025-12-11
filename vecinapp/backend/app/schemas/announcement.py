from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class AnnouncementPriority(str, Enum):
    INFO = "info"
    WARNING = "warning"
    URGENT = "urgent"

class AnnouncementBase(BaseModel):
    title: str
    message: str
    priority: AnnouncementPriority = AnnouncementPriority.INFO
    show_in_banner: bool = False
    expires_at: Optional[datetime] = None

class AnnouncementCreate(AnnouncementBase):
    pass

class AnnouncementUpdate(BaseModel):
    title: Optional[str] = None
    message: Optional[str] = None
    priority: Optional[AnnouncementPriority] = None
    show_in_banner: Optional[bool] = None
    expires_at: Optional[datetime] = None
    is_active: Optional[bool] = None

class Announcement(AnnouncementBase):
    id: str
    community_id: str
    created_by: str
    created_by_name: str
    created_at: datetime
    updated_at: datetime
    is_active: bool = True
    
    class Config:
        from_attributes = True
