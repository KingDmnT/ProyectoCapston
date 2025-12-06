from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from enum import Enum
from datetime import datetime, date

class UserRole(str, Enum):
    SUPER_ADMIN = "Super Admin"          # Admin de la plataforma
    ADMINISTRADOR = "Administrador"      # Admin de la comunidad
    CONSERJE = "Conserje"                # Encargado de recepción/mantención
    GUARDIA = "Guardia"                  # Seguridad perimetral/accesos
    PROPIETARIO = "Propietario"          # Dueño legal de la unidad
    RESIDENTE = "Residente"              # Quien vive en la unidad (arrendatario/familiar)
    VISITA = "Visita"                    # Visitante

class Gender(str, Enum):
    MASCULINO = "Masculino"
    FEMENINO = "Femenino"
    OTRO = "Otro"
    NO_BINARIO = "No Binario"
    PREFIERO_NO_DECIRLO = "Prefiero no decirlo"

class PersonCategory(str, Enum):
    NINO = "Niño"
    ADOLESCENTE = "Adolescente"
    ADULTO = "Adulto"
    ADULTO_MAYOR = "Adulto Mayor"

class Vehicle(BaseModel):
    license_plate: str  # Patente
    brand: str          # Marca
    model: str          # Modelo
    color: str          # Color
    has_parking: bool = False # ¿Tiene estacionamiento asignado?
    parking_unit_id: Optional[str] = None # ID de la unidad de estacionamiento (si aplica)

class CommunityMembershipBase(BaseModel):
    community_id: str
    community_name: Optional[str] = None
    # Un usuario puede ser Propietario Y Residente al mismo tiempo
    roles: List[UserRole] = [UserRole.RESIDENTE]
    unit_ids: List[str] = [] # Unidades asociadas
    
    # Vigencia de la membresía (Historial)
    start_date: datetime = Field(default_factory=datetime.now)
    end_date: Optional[datetime] = None
    is_active: bool = True

class UserBase(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    rut: str # Obligatorio (validación comentada para DEV)
    phone: Optional[str] = None
    
    # Datos para Analítica y Demografía
    gender: Optional[Gender] = None
    birth_date: Optional[date] = None
    category: PersonCategory = PersonCategory.ADULTO # Categoría etaria (puede calcularse o asignarse)
    
    # Plan de Emergencia / Discapacidad
    has_disability: bool = False
    disability_details: Optional[str] = None
    requires_assistance: bool = False # Si necesita ayuda para evacuar (movilidad reducida, etc.)
    
    # Registro Vehicular
    vehicles: List[Vehicle] = []
    
class UserCreate(UserBase):
    password: str # Necesario para crear la cuenta en Auth

class User(UserBase):
    id: str # Firebase UID (o generado para visitas sin cuenta)
    is_active: bool = True
    memberships: List[CommunityMembershipBase] = []
    photoUrl: Optional[str] = None  # URL de foto de perfil (Firebase Storage cuando esté disponible)

    class Config:
        from_attributes = True

# Schema para actualización de usuario
class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    rut: Optional[str] = None  # Validación comentada para DEV
    gender: Optional[Gender] = None
    birth_date: Optional[date] = None
    category: Optional[PersonCategory] = None
    has_disability: Optional[bool] = None
    disability_details: Optional[str] = None
    requires_assistance: Optional[bool] = None
    vehicles: Optional[List[Vehicle]] = None

# Schema para asignación de unidad
class UserAssignUnit(BaseModel):
    community_id: str
    unit_id: str
    roles: List[UserRole] = [UserRole.RESIDENTE]
