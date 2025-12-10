from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class MaintenanceType(str, Enum):
    PREVENTIVO = "preventivo"
    CORRECTIVO = "correctivo"
    EXTRAORDINARIO = "extraordinario"

class MaintenanceStatus(str, Enum):
    PENDIENTE = "pendiente"
    EN_PROGRESO = "en_progreso"
    COMPLETADO = "completado"
    APROBADO = "aprobado"
    RECHAZADO = "rechazado"

class MaintenanceFrequency(str, Enum):
    UNICA_VEZ = "unica_vez"
    DIARIA = "diaria"
    SEMANAL = "semanal"
    MENSUAL = "mensual"
    TRIMESTRAL = "trimestral"
    SEMESTRAL = "semestral"
    ANUAL = "anual"

class ChecklistItem(BaseModel):
    title: str
    is_completed: bool = False

class MaintenanceBase(BaseModel):
    title: str
    description: str
    type: MaintenanceType
    frequency: MaintenanceFrequency = MaintenanceFrequency.UNICA_VEZ
    provider_name: str
    provider_contact: Optional[str] = None
    cost: float = 0.0
    scheduled_date: datetime
    community_id: str
    assigned_to: Optional[str] = None  # ID del usuario asignado
    notes: Optional[str] = None
    checklist_items: List[ChecklistItem] = []

class MaintenanceCreate(MaintenanceBase):
    pass

class MaintenanceUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    type: Optional[MaintenanceType] = None
    frequency: Optional[MaintenanceFrequency] = None
    provider_name: Optional[str] = None
    provider_contact: Optional[str] = None
    cost: Optional[float] = None
    scheduled_date: Optional[datetime] = None
    assigned_to: Optional[str] = None
    notes: Optional[str] = None
    checklist_items: Optional[List[ChecklistItem]] = None
    status: Optional[MaintenanceStatus] = None  # AGREGADO

class Maintenance(MaintenanceBase):
    id: str
    status: MaintenanceStatus = MaintenanceStatus.PENDIENTE
    completed_date: Optional[datetime] = None
    approved_by: Optional[str] = None  # ID del usuario que aprobó
    approval_date: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)

    class Config:
        from_attributes = True
