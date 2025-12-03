from pydantic import BaseModel
from typing import Optional
from enum import Enum

# Enums en Español
class TipoUnidad(str, Enum):
    DEPARTAMENTO = "Departamento"
    CASA = "Casa"
    BODEGA = "Bodega"
    ESTACIONAMIENTO = "Estacionamiento"
    ESPACIO_COMUN = "Espacio Común"

class EstadoUnidad(str, Enum):
    DISPONIBLE = "Disponible"
    ASIGNADO = "Asignado"

class UnitBase(BaseModel):
    name: str  # Ej: "101", "12B"
    floor: int
    type: TipoUnidad = TipoUnidad.DEPARTAMENTO
    status: EstadoUnidad = EstadoUnidad.DISPONIBLE
    
    # Datos Financieros / Técnicos
    alicuota: float = 0.0 # Porcentaje de participación en gastos comunes
    m2: float = 0.0       # Metros cuadrados
    
    description: Optional[str] = None
    community_id: str

class UnitCreate(UnitBase):
    pass

class Unit(UnitBase):
    id: str
    
    class Config:
        from_attributes = True
