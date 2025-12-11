from fastapi import APIRouter, HTTPException, status, Depends, Query
from typing import List, Optional
from datetime import datetime
from app.schemas.incident import (
    Incident, 
    IncidentCreate, 
    IncidentUpdate
)
from app.schemas.notification import NotificationCreate, NotificationType
from app.repositories.incident_repo import IncidentRepository
from app.repositories.notification_repo import NotificationRepository
from app.core.security import get_current_user

router = APIRouter()
incident_repo = IncidentRepository()
notif_repo = NotificationRepository()

@router.post("/", response_model=Incident, status_code=status.HTTP_201_CREATED)
def create_incident(
    incident: IncidentCreate,
   current_user: dict = Depends(get_current_user)
):
    """
    Crea un nuevo incidente y notifica a todos los administradores.
    """
    try:
        # Crear incidente
        new_incident = incident_repo.create(incident)
        
        # Obtener administradores de la comunidad
        admin_ids = notif_repo.get_community_admins(incident.community_id)
        
        # Crear notificaciones para administradores
        if admin_ids:
            notification = NotificationCreate(
                type=NotificationType.INCIDENT_CREATED,
                title="Nuevo Incidente Reportado",
                message=f"Se ha reportado un incidente: {incident.title}",
                community_id=incident.community_id,
                related_entity_id=new_incident.id,
                related_entity_type="incident",
                target_user_ids=admin_ids
            )
            notif_repo.create_bulk(notification)
        
        return new_incident
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al crear incidente: {str(e)}"
        )

@router.get("/", response_model=List[Incident])
def list_incidents(
    community_id: str,
    category: Optional[str] = None,
    incident_status: Optional[str] = None,
    created_by: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Lista todos los incidentes de una comunidad con filtros opcionales.
    """
    try:
        return incident_repo.get_all(
            community_id=community_id,
            category=category,
            status=incident_status,
            created_by=created_by
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al obtener incidentes: {str(e)}"
        )

@router.get("/{incident_id}", response_model=Incident)
def get_incident(
    community_id: str,
    incident_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene el detalle de un incidente específico.
    """
    incident = incident_repo.get_by_id(community_id, incident_id)
    
    if not incident:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Incidente no encontrado"
        )
    
    return incident

@router.patch("/{incident_id}", response_model=Incident)
def update_incident(
    community_id: str,
    incident_id: str,
    incident_update: IncidentUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Actualiza un incidente y notifica al creador si se cambió el estado.
    Solo administradores pueden actualizar incidentes.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden actualizar incidentes"
        )
    
    try:
        # Obtener incidente original para comparar
        original_incident = incident_repo.get_by_id(community_id, incident_id)
        if not original_incident:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Incidente no encontrado"
            )
        
        # Actualizar incidente
        updated_incident = incident_repo.update(community_id, incident_id, incident_update)
        
        # Si se actualizó el estado, notificar al creador
        if incident_update.status and incident_update.status != original_incident.status:
            notification = NotificationCreate(
                type=NotificationType.INCIDENT_UPDATED,
                title="Actualización de Incidente",
                message=f"Tu incidente '{original_incident.title}' ha sido actualizado a: {incident_update.status.value}",
                community_id=community_id,
                related_entity_id=incident_id,
                related_entity_type="incident",
                target_user_ids=[original_incident.created_by]
            )
            notif_repo.create_bulk(notification)
        
        return updated_incident
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al actualizar incidente: {str(e)}"
        )

@router.delete("/{incident_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_incident(
    community_id: str,
    incident_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Elimina un incidente.
    Solo administradores pueden eliminar incidentes.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden eliminar incidentes"
        )
    
    success = incident_repo.delete(community_id, incident_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Incidente no encontrado"
        )
