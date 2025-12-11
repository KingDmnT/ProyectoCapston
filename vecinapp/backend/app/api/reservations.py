from fastapi import APIRouter, HTTPException, status, Depends, Query
from typing import List, Optional
from datetime import date
from app.schemas.reservation import (
    Reservation, 
    ReservationCreate, 
    ReservationUpdate
)
from app.schemas.notification import NotificationCreate, NotificationType
from app.repositories.reservation_repo import ReservationRepository
from app.repositories.notification_repo import NotificationRepository
from app.core.security import get_current_user

router = APIRouter()
reservation_repo = ReservationRepository()
notif_repo = NotificationRepository()

@router.post("/", response_model=Reservation, status_code=status.HTTP_201_CREATED)
def create_reservation(
    reservation: ReservationCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Crea una nueva reserva y notifica a todos los administradores.
    """
    try:
        # Verificar disponibilidad
        is_available = reservation_repo.check_availability(
            community_id=reservation.community_id,
            space_type=reservation.space_type.value,
            reservation_date=reservation.date,
            start_time=reservation.start_time.isoformat(),
            end_time=reservation.end_time.isoformat()
        )
        
        if not is_available:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El espacio no está disponible en el horario seleccionado"
            )
        
        # Crear reserva
        new_reservation = reservation_repo.create(reservation)
        
        # Obtener administradores de la comunidad
        admin_ids = notif_repo.get_community_admins(reservation.community_id)
        
        # Crear notificaciones para administradores
        if admin_ids:
            notification = NotificationCreate(
                type=NotificationType.RESERVATION_CREATED,
                title="Nueva Reserva Pendiente",
                message=f"Nueva reserva de {reservation.space_type.value} para el {reservation.date}",
                community_id=reservation.community_id,
                related_entity_id=new_reservation.id,
                related_entity_type="reservation",
                target_user_ids=admin_ids
            )
            notif_repo.create_bulk(notification)
        
        return new_reservation
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al crear reserva: {str(e)}"
        )

@router.get("/", response_model=List[Reservation])
def list_reservations(
    community_id: str,
    space_type: Optional[str] = None,
    status: Optional[str] = None,
    created_by: Optional[str] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Lista todas las reservas de una comunidad con filtros opcionales.
    """
    try:
        return reservation_repo.get_all(
            community_id=community_id,
            space_type=space_type,
            status=status,
            created_by=created_by,
            start_date=start_date,
            end_date=end_date
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al obtener reservas: {str(e)}"
        )

@router.get("/{reservation_id}", response_model=Reservation)
def get_reservation(
    community_id: str,
    reservation_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene el detalle de una reserva específica.
    """
    reservation = reservation_repo.get_by_id(community_id, reservation_id)
    
    if not reservation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada"
        )
    
    return reservation

@router.patch("/{reservation_id}", response_model=Reservation)
def update_reservation(
    community_id: str,
    reservation_id: str,
    reservation_update: ReservationUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Actualiza una reserva y notifica al creador si se cambió el estado.
    Solo administradores pueden actualizar reservas.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden actualizar reservas"
        )
    
    try:
        # Obtener reserva original
        original_reservation = reservation_repo.get_by_id(community_id, reservation_id)
        if not original_reservation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reserva no encontrada"
            )
        
        # Actualizar reserva
        updated_reservation = reservation_repo.update(community_id, reservation_id, reservation_update)
        
        # Si se actualizó el estado, notificar al creador
        if reservation_update.status and reservation_update.status != original_reservation.status:
            status_messages = {
                "aprobada": "ha sido aprobada",
                "rechazada": "ha sido rechazada",
                "cancelada": "ha sido cancelada"
            }
            message = f"Tu reserva de {original_reservation.space_type} {status_messages.get(reservation_update.status.value, 'ha sido actualizada')}"
            
            notification = NotificationCreate(
                type=NotificationType.RESERVATION_UPDATED,
                title="Actualización de Reserva",
                message=message,
                community_id=community_id,
                related_entity_id=reservation_id,
                related_entity_type="reservation",
                target_user_ids=[original_reservation.created_by]
            )
            notif_repo.create_bulk(notification)
        
        return updated_reservation
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al actualizar reserva: {str(e)}"
        )

@router.delete("/{reservation_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_reservation(
    community_id: str,
    reservation_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Elimina/cancela una reserva.
    """
    # Obtener reserva para verificar permisos
    reservation = reservation_repo.get_by_id(community_id, reservation_id)
    
    if not reservation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada"
        )
    
    # Permitir si es admin o si es el creador
    if (current_user.get("role") != "administrator" and 
        current_user.get("uid") != reservation.created_by):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para eliminar esta reserva"
        )
    
    success = reservation_repo.delete(community_id, reservation_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reserva no encontrada"
        )
