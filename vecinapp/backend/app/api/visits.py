from fastapi import APIRouter, HTTPException, status, Depends, Body
from typing import List
from app.schemas.visit import Visit, VisitCreate, AccessType
from app.repositories.visit_repo import VisitRepository
from app.core.security import get_current_user
from app.schemas.user import UserRole

router = APIRouter()
repo = VisitRepository()

@router.post("/", response_model=Visit, status_code=status.HTTP_201_CREATED)
def create_visit(
    visit: VisitCreate, 
    current_user: dict = Depends(get_current_user)
):
    """
    Crea una nueva invitación de visita.
    Genera un código QR único.
    """
    # TODO: Validar que current_user.uid coincida con visit.host_user_id o sea Admin
    return repo.create(visit)

@router.get("/my-visits", response_model=List[Visit])
def list_my_visits(
    current_user: dict = Depends(get_current_user)
):
    """
    Lista las visitas creadas por el usuario actual.
    """
    return repo.get_by_resident(current_user['uid'])

@router.post("/validate")
def validate_visit_access(
    qr_data: str = Body(..., embed=True),
    access_type: AccessType = Body(..., embed=True),
    current_user: dict = Depends(get_current_user)
):
    """
    Endpoint para Guardias. Valida un QR y registra el acceso.
    """
    # TODO: Validar que current_user tenga rol GUARDIA o CONSERJE
    
    is_valid, message, visit = repo.validate_access(
        qr_data=qr_data, 
        guard_id=current_user['uid'],
        access_type=access_type
    )
    
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=message
        )
        
    # Simulación de Notificación al Host
    if access_type == AccessType.ENTRADA:
        print(f"🔔 NOTIFICACIÓN: Estimado residente, su visita {visit.visitor_first_name} ha ingresado.")
        
    return {
        "status": "success",
        "message": message,
        "visitor": f"{visit.visitor_first_name} {visit.visitor_last_name}",
        "plate": visit.vehicle_plate
    }
