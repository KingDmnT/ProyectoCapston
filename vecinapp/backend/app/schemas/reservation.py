from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, date, time
from enum import Enum

class SpaceType(str, Enum):
    SALON = "salon"
    PISCINA = "piscina"
    CANCHA = "cancha"
    QUINCHO = "quincho"

class ReservationStatus(str, Enum):
    PENDIENTE = "pendiente"
    APROBADA = "aprobada"
    RECHAZADA = "rechazada"
    CANCELADA = "cancelada"

class ReservationBase(BaseModel):
    space_type: SpaceType
    date: date
    start_time: time
    end_time: time
    purpose: str
    attendees: int
    community_id: str
    created_by: str  # User ID

class ReservationCreate(ReservationBase):
    pass

class ReservationUpdate(BaseModel):
    status: Optional[ReservationStatus] = None
    admin_notes: Optional[str] = None

class Reservation(ReservationBase):
    id: str
    status: ReservationStatus = ReservationStatus.PENDIENTE
    admin_notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)

    class Config:
        from_attributes = True
