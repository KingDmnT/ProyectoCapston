from pydantic import BaseModel, EmailStr
from typing import Optional

# Base: Campos compartidos al crear y leer
class ResidentBase(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    apartment_unit: str  # Ej: "101", "Torre A - 505"
    phone: Optional[str] = None

# Create: Lo que recibimos del Frontend
class ResidentCreate(ResidentBase):
    pass

# Response: Lo que enviamos de vuelta (incluye ID)
class Resident(ResidentBase):
    id: str
    is_active: bool = True

    class Config:
        from_attributes = True