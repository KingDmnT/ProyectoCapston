from app.repositories.user_repo import UserRepository
from app.schemas.incident import (
    Incident, 
    IncidentCreate, 
    IncidentUpdate,
    IncidentCategory
)
from app.schemas.incident_comment import IncidentComment, IncidentCommentCreate

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from app.core.security import get_current_user
from app.repositories.incident_repo import IncidentRepository
from app.repositories.notification_repo import NotificationRepository

router = APIRouter()
incident_repo = IncidentRepository()
notif_repo = NotificationRepository()
user_repo = UserRepository()

@router.post("/", response_model=Incident, status_code=status.HTTP_201_CREATED)
def create_incident(
    incident: IncidentCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Crea un nuevo incidente y notifica a todos los administradores.
    Si es de SEGURIDAD, notifica a TODOS los residentes activos.
    """
    try:
        # Obtener info completa del usuario para guardar en incidente
        user = user_repo.get_by_id(current_user['uid'])
        user_dict = user.model_dump() if user else current_user
        
        # Crear incidente
        new_incident = incident_repo.create(incident, user_dict)
        
        # Notificaciones
        if incident.category == IncidentCategory.SEGURIDAD:
            # Notificar a TODOS los residentes activos de la comunidad
            active_residents = user_repo.get_all(
                community_id=incident.community_id, 
                is_active=True
            )
            target_ids = [u.id for u in active_residents if u.id != current_user['uid']]
            
            if target_ids:
                notification = NotificationCreate(
                    type=NotificationType.SECURITY_ALERT, # Asumiendo que existe o usar INCIDENT_CREATED
                    title="🚨 ALERTA DE SEGURIDAD",
                    message=f"Nuevo reporte de seguridad: {incident.title}",
                    community_id=incident.community_id,
                    related_entity_id=new_incident.id,
                    related_entity_type="incident",
                    target_user_ids=target_ids
                )
                notif_repo.create_bulk(notification)
        
        # Siempre notificar a administradores (si no es seguridad, o tambien si es seguridad)
        # Para evitar doble notificación a admins si son residentes, filtramos
        admin_ids = notif_repo.get_community_admins(incident.community_id)
        # Si ya se notificó por seguridad, no duplicar, pero el mensaje es distinto.
        # Simplificación: Notificamos a admins como admins.
        
        if admin_ids:
            notification = NotificationCreate(
                type=NotificationType.INCIDENT_CREATED,
                title="Nuevo Incidente Reportado",
                message=f"Se ha reportado un incidente: {incident.title}",
                community_id=incident.community_id,
                related_entity_id=new_incident.id,
                related_entity_type="incident",
                target_user_ids=[uid for uid in admin_ids if uid != current_user['uid']]
            )
            notif_repo.create_bulk(notification)
        
        return new_incident
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al crear incidente: {str(e)}"
        )

# ... (list_incidents stays mostly same, update get_incident to fetch comments)

@router.get("/{incident_id}", response_model=Incident)
def get_incident(
    community_id: str,
    incident_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene el detalle de un incidente específico incluyendo comentarios.
    """
    incident = incident_repo.get_by_id(community_id, incident_id)
    
    if not incident:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Incidente no encontrado"
        )
    
    # Cargar comentarios
    incident.comments = incident_repo.get_comments(community_id, incident_id)
    
    return incident

@router.patch("/{incident_id}", response_model=Incident)
def update_incident(
    community_id: str,
    incident_id: str,
    incident_update: IncidentUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Actualiza un incidente.
    """
    # Verificar que sea admin (o el creador? por ahora solo admin)
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden actualizar incidentes"
        )
    
    try:
        user = user_repo.get_by_id(current_user['uid'])
        user_dict = user.model_dump() if user else current_user
        
        updated_incident = incident_repo.update(
            community_id, 
            incident_id, 
            incident_update,
            user_info=user_dict
        )
        
        if not updated_incident:
             raise HTTPException(status_code=404, detail="Incidente no encontrado")

        # Notificar al creador si cambió estado
        # ... (logica existente)
        
        return updated_incident
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al actualizar incidente: {str(e)}"
        )

@router.post("/{incident_id}/comments", response_model=IncidentComment)
def add_incident_comment(
    community_id: str,
    incident_id: str,
    comment: IncidentCommentCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Agrega un comentario al incidente.
    """
    try:
        # Verificar incidente
        incident = incident_repo.get_by_id(community_id, incident_id)
        if not incident:
            raise HTTPException(status_code=404, detail="Incidente no encontrado")
            
        user = user_repo.get_by_id(current_user['uid'])
        user_dict = user.model_dump() if user else current_user
        
        # Validar que comment.incident_id coincida (REMOVED: schema doesn't have this field)
        # comment.incident_id = incident_id
        
        new_comment = incident_repo.add_comment(
            community_id=community_id,
            incident_id=incident_id,
            comment=comment,
            user_info=user_dict
        )
        
        return new_comment
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al agregar comentario: {str(e)}"
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
