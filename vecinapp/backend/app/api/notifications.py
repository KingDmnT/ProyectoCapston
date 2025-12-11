from fastapi import APIRouter, HTTPException, status, Depends
from typing import List
from app.schemas.notification import Notification
from app.repositories.notification_repo import NotificationRepository
from app.core.security import get_current_user

router = APIRouter()
notif_repo = NotificationRepository()

@router.get("/me", response_model=List[Notification])
def get_my_notifications(
    community_id: str,
    is_read: bool = None,
    limit: int = 50,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene las notificaciones del usuario actual.
    """
    try:
        user_id = current_user.get("uid")
        
        return notif_repo.get_user_notifications(
            community_id=community_id,
            user_id=user_id,
            is_read=is_read,
            limit=limit
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al obtener notificaciones: {str(e)}"
        )

@router.patch("/{notification_id}/read", response_model=Notification)
def mark_notification_as_read(
    community_id: str,
    notification_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Marca una notificación como leída.
    """
    # Obtener notificación para verificar permisos
    notifications = notif_repo.get_user_notifications(
        community_id=community_id,
        user_id=current_user.get("uid"),
        limit=1000
    )
    
    # Verificar que la notificación pertenezca al usuario
    notification_exists = any(n.id == notification_id for n in notifications)
    
    if not notification_exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notificación no encontrada"
        )
    
    try:
        updated_notif = notif_repo.mark_as_read(community_id, notification_id)
        
        if not updated_notif:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notificación no encontrada"
            )
        
        return updated_notif
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al marcar como leída: {str(e)}"
        )

@router.get("/unread-count")
def get_unread_count(
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene el número de notificaciones no leídas del usuario.
    """
    try:
        user_id = current_user.get("uid")
        count = notif_repo.get_unread_count(community_id, user_id)
        
        return {"unread_count": count}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al obtener contador: {str(e)}"
        )
