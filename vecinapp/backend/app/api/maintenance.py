from fastapi import APIRouter, HTTPException, status, Depends, Query
from typing import List, Optional
from datetime import datetime
from app.schemas.maintenance import (
    Maintenance, 
    MaintenanceCreate, 
    MaintenanceUpdate, 
    MaintenanceStatus,
    ChecklistItem
)
from app.repositories.maintenance_repo import MaintenanceRepository
from app.core.security import get_current_user

router = APIRouter()
repo = MaintenanceRepository()

@router.post("/", response_model=Maintenance, status_code=status.HTTP_201_CREATED)
def create_maintenance(
    maintenance: MaintenanceCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Crea una nueva orden de mantenimiento.
    Solo administradores pueden crear mantenimientos.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden crear órdenes de mantenimiento"
        )
    
    try:
        return repo.create(maintenance)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al crear mantenimiento: {str(e)}"
        )

@router.get("/", response_model=List[Maintenance])
def list_maintenances(
    community_id: str,
    type: Optional[str] = None,
    status: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Lista todos los mantenimientos de una comunidad con filtros opcionales.
    Solo administradores pueden ver mantenimientos.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden ver mantenimientos"
        )
    
    try:
        return repo.get_all(
            community_id=community_id,
            type=type,
            status=status,
            start_date=start_date,
            end_date=end_date
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al obtener mantenimientos: {str(e)}"
        )

@router.get("/{maintenance_id}", response_model=Maintenance)
def get_maintenance(
    community_id: str,
    maintenance_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene el detalle de un mantenimiento específico.
    Solo administradores pueden ver detalles.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden ver detalles de mantenimientos"
        )
    
    maintenance = repo.get_by_id(community_id, maintenance_id)
    
    if not maintenance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mantenimiento no encontrado"
        )
    
    return maintenance

@router.put("/{maintenance_id}", response_model=Maintenance)
def update_maintenance(
    community_id: str,
    maintenance_id: str,
    maintenance_update: MaintenanceUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Actualiza la información de un mantenimiento.
    Solo administradores pueden actualizar mantenimientos.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden actualizar mantenimientos"
        )
    
    try:
        updated_maintenance = repo.update(community_id, maintenance_id, maintenance_update)
        
        if not updated_maintenance:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Mantenimiento no encontrado"
            )
        
        return updated_maintenance
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al actualizar mantenimiento: {str(e)}"
        )

@router.put("/{maintenance_id}/status", response_model=Maintenance)
def update_maintenance_status(
    community_id: str,
    maintenance_id: str,
    new_status: MaintenanceStatus,
    current_user: dict = Depends(get_current_user)
):
    """
    Actualiza el estado de un mantenimiento.
    Solo administradores pueden cambiar estados.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden cambiar estados"
        )
    
    try:
        updated_maintenance = repo.update_status(community_id, maintenance_id, new_status)
        
        if not updated_maintenance:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Mantenimiento no encontrado"
            )
        
        return updated_maintenance
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al actualizar estado: {str(e)}"
        )

@router.post("/{maintenance_id}/approve", response_model=Maintenance)
def approve_maintenance(
    community_id: str,
    maintenance_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Aprueba un mantenimiento.
    Solo administradores pueden aprobar mantenimientos.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden aprobar mantenimientos"
        )
    
    try:
        approved_maintenance = repo.approve(
            community_id, 
            maintenance_id, 
            current_user.get("uid")
        )
        
        if not approved_maintenance:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Mantenimiento no encontrado"
            )
        
        return approved_maintenance
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al aprobar mantenimiento: {str(e)}"
        )

@router.post("/{maintenance_id}/reject", response_model=Maintenance)
def reject_maintenance(
    community_id: str,
    maintenance_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Rechaza un mantenimiento.
    Solo administradores pueden rechazar mantenimientos.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden rechazar mantenimientos"
        )
    
    try:
        rejected_maintenance = repo.reject(
            community_id, 
            maintenance_id, 
            current_user.get("uid")
        )
        
        if not rejected_maintenance:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Mantenimiento no encontrado"
            )
        
        return rejected_maintenance
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al rechazar mantenimiento: {str(e)}"
        )

@router.put("/{maintenance_id}/checklist", response_model=Maintenance)
def update_checklist(
    community_id: str,
    maintenance_id: str,
    checklist_items: List[ChecklistItem],
    current_user: dict = Depends(get_current_user)
):
    """
    Actualiza el checklist de un mantenimiento.
    Solo administradores pueden actualizar checklists.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden actualizar checklists"
        )
    
    try:
        updated_maintenance = repo.update_checklist(
            community_id, 
            maintenance_id, 
            checklist_items
        )
        
        if not updated_maintenance:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Mantenimiento no encontrado"
            )
        
        return updated_maintenance
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al actualizar checklist: {str(e)}"
        )

@router.delete("/{maintenance_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_maintenance(
    community_id: str,
    maintenance_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Elimina un mantenimiento.
    Solo administradores pueden eliminar mantenimientos.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden eliminar mantenimientos"
        )
    
    success = repo.delete(community_id, maintenance_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mantenimiento no encontrado"
        )
