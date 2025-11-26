from fastapi import APIRouter, HTTPException
from typing import List
from app.schemas.resident import Resident, ResidentCreate
from app.repositories.resident_repo import ResidentRepository

router = APIRouter()
repo = ResidentRepository()

@router.post("/", response_model=Resident, status_code=201)
def create_resident(resident: ResidentCreate):
    # 1. Validar reglas de negocio (ej: email único)
    existing = repo.get_resident_by_email(resident.email)
    if existing:
        raise HTTPException(status_code=400, detail="Ya existe un residente con este email")
    
    # 2. Guardar en base de datos
    return repo.create_resident(resident)

@router.get("/", response_model=List[Resident])
def read_residents():
    # Obtener lista completa
    return repo.get_all_residents()