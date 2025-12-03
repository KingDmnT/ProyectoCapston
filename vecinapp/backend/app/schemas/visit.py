from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class VisitBase(BaseModel):
    visitor_name: str
    visitor_rut: Optional[str] = None
    host_unit_id: str      # Unidad que invita (Depto 101)
    host_user_id: str      # Residente que genera la invitación
    community_id: str
    
    valid_from: datetime
    valid_to: datetime     # Máximo 6 horas desde valid_from
    
    qr_code_data: Optional[str] = None # Hash o token del QR
    is_used: bool = False  # Si ya ingresó
    entry_time: Optional[datetime] = None

class VisitCreate(VisitBase):
    pass

class Visit(VisitBase):
    id: str
    created_at: datetime = datetime.now()

    class Config:
        from_attributes = True
