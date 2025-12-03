from fastapi import APIRouter, HTTPException, status, Depends, Query
from typing import List, Optional
from app.schemas.unit import Unit, UnitCreate
from app.repositories.unit_repo import UnitRepository
from app.core.security import get_current_user

router = APIRouter()
repo = UnitRepository()

@router.post("/", response_model=Unit, status_code=status.HTTP_201_CREATED)
def create_unit(
    unit: UnitCreate, 
    current_user: dict = Depends(get_current_user)
):
    """
    Crea una nueva unidad (Departamento, Casa, etc.).
    """
    return repo.create(unit)

@router.get("/", response_model=List[Unit])
def list_units(
    community_id: Optional[str] = Query(None, description="Filtrar por ID de comunidad"),
    current_user: dict = Depends(get_current_user)
):
    """
    Lista unidades. Si se provee 'community_id', filtra por esa comunidad.
    """
    if community_id:
        return repo.get_by_community(community_id)
    
    # Si no se filtra, por seguridad/performance podríamos retornar lista vacía o todas
    # Por ahora retornamos error pidiendo el filtro para evitar listar TODAS las unidades de todas las comunidades
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Debes especificar el community_id para listar unidades."
    )

@router.get("/{unit_id}", response_model=Unit)
def get_unit(
    unit_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene el detalle de una unidad específica.
    """
    unit = repo.get_by_id(unit_id)
    if not unit:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Unidad no encontrada"
        )
    return unit
