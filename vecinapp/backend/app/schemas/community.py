from pydantic import BaseModel
from typing import Optional
from datetime import datetime, date

class CommunityBase(BaseModel):
    name: str
    address: str
    
    # Ubicación Geográfica
    comuna: str
    region: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    
    # Datos Inmobiliarios
    constructora: Optional[str] = None
    inmobiliaria: Optional[str] = None
    fecha_entrega_inicial: Optional[date] = None
    
    description: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None

class CommunityCreate(CommunityBase):
    pass

class Community(CommunityBase):
    id: str
    created_at: datetime = datetime.now()
    is_active: bool = True

    class Config:
        from_attributes = True
