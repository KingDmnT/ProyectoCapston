from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class IncidentCategory(str, Enum):
    INSTALACIONES = "instalaciones"
    SEGURIDAD = "seguridad"
    LIMPIEZA = "limpieza"
    RUIDO = "ruido"
    OTRO = "otro"

class IncidentPriority(str, Enum):
    BAJA = "baja"
    MEDIA = "media"
    ALTA = "alta"
    CRITICA = "critica"

class IncidentStatus(str, Enum):
    PENDIENTE = "pendiente"
    EN_PROCESO = "en_proceso"
    RESUELTO = "resuelto"

from typing import List
from .incident_comment import IncidentComment

class IncidentBase(BaseModel):
    title: str
    description: str
    category: IncidentCategory
    priority: IncidentPriority = IncidentPriority.MEDIA
    location: Optional[str] = None
    community_id: str
    created_by: str  # User ID

class IncidentCreate(IncidentBase):
    pass

class IncidentUpdate(BaseModel):
    status: Optional[IncidentStatus] = None
    admin_notes: Optional[str] = None

class Incident(IncidentBase):
    id: str
    status: IncidentStatus = IncidentStatus.PENDIENTE
    admin_notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    
    # New Traceability Fields
    reported_by_id: Optional[str] = None  # User ID of reporter
    reported_by_name: Optional[str] = None
    reported_by_unit: Optional[str] = None
    
    resolved_at: Optional[datetime] = None
    resolved_by_id: Optional[str] = None
    resolved_by_name: Optional[str] = None
    
    is_security: bool = False
    comments: List[IncidentComment] = []

    class Config:
        from_attributes = True
