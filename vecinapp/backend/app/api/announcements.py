from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from app.core.security import get_current_user
from app.repositories.announcement_repo import AnnouncementRepository
from app.repositories.user_repo import UserRepository
from app.repositories.notification_repo import NotificationRepository
from app.schemas.announcement import (
    Announcement,
    AnnouncementCreate,
    AnnouncementUpdate
)
from app.schemas.notification import NotificationCreate, NotificationType

router = APIRouter()
announcement_repo = AnnouncementRepository()
user_repo = UserRepository()
notif_repo = NotificationRepository()

@router.post("/", response_model=Announcement, status_code=status.HTTP_201_CREATED)
def create_announcement(
    announcement: AnnouncementCreate,
    community_id: str = Query(...),
    current_user: dict = Depends(get_current_user)
):
    """
    Crea un nuevo anuncio y notifica a todos los residentes activos.
    """
    try:
        # Obtener info del usuario
        user = user_repo.get_by_id(current_user['uid'])
        user_dict = user.model_dump() if user else current_user
        
        # Crear anuncio
        new_announcement = announcement_repo.create(community_id, announcement, user_dict)
        
        # Enviar notificaciones a todos los residentes activos
        active_residents = user_repo.get_all(
            community_id=community_id,
            is_active=True
        )
        
        # Filtrar solo residentes (excluir admins y al creador)
        resident_ids = [
            u.id for u in active_residents 
            if 'resident' in str(u.memberships) and u.id != current_user['uid']
        ]
        
        if resident_ids:
            # Determinar tipo de notificación según prioridad
            notif_type = NotificationType.ANNOUNCEMENT
            title_prefix = {
                'info': '📢',
                'warning': '⚠️',
                'urgent': '🚨'
            }.get(announcement.priority.value, '📢')
            
            notification = NotificationCreate(
                type=notif_type,
                title=f"{title_prefix} {announcement.title}",
                message=announcement.message[:200],  # Limitar longitud
                community_id=community_id,
                related_entity_id=new_announcement.id,
                related_entity_type="announcement",
                target_user_ids=resident_ids
            )
            notif_repo.create_bulk(notification)
        
        return new_announcement
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al crear anuncio: {str(e)}"
        )

@router.get("/", response_model=List[Announcement])
def list_announcements(
    community_id: str = Query(...),
    is_active: Optional[bool] = Query(None),
    show_in_banner: Optional[bool] = Query(None),
    current_user: dict = Depends(get_current_user)
):
    """
    Lista todos los anuncios de una comunidad con filtros opcionales.
    """
    try:
        return announcement_repo.get_all(
            community_id=community_id,
            is_active=is_active,
            show_in_banner=show_in_banner
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al listar anuncios: {str(e)}"
        )

@router.get("/active-banners", response_model=List[Announcement])
def get_active_banners(
    community_id: str = Query(...),
):
    """
    Obtiene anuncios activos que deben mostrarse en el carousel/banner.
    Endpoint público - no requiere autenticación.
    """
    try:
        return announcement_repo.get_active_banners(community_id)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al obtener banners: {str(e)}"
        )

@router.get("/{announcement_id}", response_model=Announcement)
def get_announcement(
    community_id: str,
    announcement_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene un anuncio específico por ID.
    """
    announcement = announcement_repo.get_by_id(community_id, announcement_id)
    
    if not announcement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Anuncio no encontrado"
        )
    
    return announcement

@router.patch("/{announcement_id}", response_model=Announcement)
def update_announcement(
    community_id: str,
    announcement_id: str,
    announcement_update: AnnouncementUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Actualiza un anuncio existente.
    """
    try:
        updated = announcement_repo.update(community_id, announcement_id, announcement_update)
        
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Anuncio no encontrado"
            )
        
        return updated
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al actualizar anuncio: {str(e)}"
        )

@router.delete("/{announcement_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_announcement(
    community_id: str,
    announcement_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Elimina un anuncio (soft delete).
    """
    success = announcement_repo.delete(community_id, announcement_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Anuncio no encontrado"
        )
    
    return None
