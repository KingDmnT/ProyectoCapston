from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class AccessType(str, Enum):
    ENTRADA = "Entrada"
    SALIDA = "Salida"

class AccessLog(BaseModel):
    timestamp: datetime = Field(default_factory=datetime.now)
    type: AccessType
    guard_id: str # ID del guardia que registró el acceso

class VisitBase(BaseModel):
    # Datos del Visitante
    visitor_first_name: str
    visitor_last_name: str
    visitor_rut: str # Obligatorio
    vehicle_plate: Optional[str] = None
    
    # Datos del Anfitrión
    host_unit_id: str      # Unidad que invita
    host_user_id: str      # Residente que invita
    community_id: str
    
    # Vigencia
    valid_from: datetime
    valid_to: datetime     # Máximo 6 horas
    
    # Control
    qr_code_data: Optional[str] = None 
    access_logs: List[AccessLog] = [] # Historial de entradas y salidas

class VisitCreate(VisitBase):
    pass

class Visit(VisitBase):
    id: str
    created_at: datetime = Field(default_factory=datetime.now)

    class Config:
        from_attributes = True
