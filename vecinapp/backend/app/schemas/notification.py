from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum

class NotificationType(str, Enum):
    INCIDENT_CREATED = "incident_created"
    INCIDENT_UPDATED = "incident_updated"
    RESERVATION_CREATED = "reservation_created"
    RESERVATION_UPDATED = "reservation_updated"

class NotificationBase(BaseModel):
    type: NotificationType
    title: str
    message: str
    community_id: str
    related_entity_id: str  # ID del incidente o reserva
    related_entity_type: str  # "incident" or "reservation"

class NotificationCreate(NotificationBase):
    target_user_ids: List[str]  # Lista de IDs de usuarios a notificar

class Notification(NotificationBase):
    id: str
    user_id: str  # Usuario que recibe la notificación
    is_read: bool = False
    created_at: datetime = Field(default_factory=datetime.now)

    class Config:
        from_attributes = True
