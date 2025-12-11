from google.cloud import firestore
from app.core.firebase import get_db
from app.schemas.reservation import (
    ReservationCreate, 
    ReservationUpdate, 
    Reservation, 
    ReservationStatus
)
from typing import List, Optional
from datetime import datetime, date

class ReservationRepository:
    def __init__(self):
        self.db = get_db()
    
    def _get_collection(self, community_id: str):
        """Obtiene la colección de reservas de una comunidad"""
        return self.db.collection('communities').document(community_id).collection('reservations')
    
    def create(self, reservation: ReservationCreate) -> Reservation:
        """
        Crea una nueva reserva en Firestore.
        """
        collection = self._get_collection(reservation.community_id)
        
        # Preparar datos
        reservation_data = reservation.model_dump()
        reservation_data['status'] = ReservationStatus.PENDIENTE.value
        reservation_data['admin_notes'] = None
        reservation_data['created_at'] = datetime.now()
        reservation_data['updated_at'] = datetime.now()
        
        # Convertir enums a valores string
        reservation_data['space_type'] = reservation.space_type.value
        
        # Convertir date y time a formato serializeable
        reservation_data['date'] = reservation.date.isoformat()
        reservation_data['start_time'] = reservation.start_time.isoformat()
        reservation_data['end_time'] = reservation.end_time.isoformat()
        
        # Crear documento
        doc_ref = collection.document()
        reservation_data['id'] = doc_ref.id
        doc_ref.set(reservation_data)
        
        return Reservation(**reservation_data)
    
    def get_all(
        self,
        community_id: str,
        space_type: Optional[str] = None,
        status: Optional[str] = None,
        created_by: Optional[str] = None,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None
    ) -> List[Reservation]:
        """
        Obtiene todas las reservas de una comunidad con filtros opcionales.
        """
        query = self._get_collection(community_id)
        
        # Aplicar filtros
        if space_type:
            query = query.where('space_type', '==', space_type)
        
        if status:
            query = query.where('status', '==', status)
        
        if created_by:
            query = query.where('created_by', '==', created_by)
        
        if start_date:
            query = query.where('date', '>=', start_date.isoformat())
        
        if end_date:
            query = query.where('date', '<=', end_date.isoformat())
        
        # Ordenar por fecha descendente
        query = query.order_by('date', direction=firestore.Query.DESCENDING)
        
        # Ejecutar query
        docs = query.stream()
        reservations = []
        
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            reservations.append(Reservation(**data))
        
        return reservations
    
    def get_by_id(self, community_id: str, reservation_id: str) -> Optional[Reservation]:
        """Obtiene una reserva por su ID"""
        doc = self._get_collection(community_id).document(reservation_id).get()
        
        if doc.exists:
            data = doc.to_dict()
            data['id'] = doc.id
            return Reservation(**data)
        
        return None
    
    def check_availability(
        self, 
        community_id: str, 
        space_type: str, 
        reservation_date: date,
        start_time: str,
        end_time: str,
        exclude_id: Optional[str] = None
    ) -> bool:
        """
        Verifica si un espacio está disponible en la fecha y hora solicitadas.
        Retorna True si está disponible, False si ya está reservado.
        """
        query = self._get_collection(community_id) \
            .where('space_type', '==', space_type) \
            .where('date', '==', reservation_date.isoformat()) \
            .where('status', 'in', [ReservationStatus.PENDIENTE.value, ReservationStatus.APROBADA.value])
        
        docs = query.stream()
        
        for doc in docs:
            # Excluir la reserva actual si estamos editando
            if exclude_id and doc.id == exclude_id:
                continue
            
            data = doc.to_dict()
            existing_start = data['start_time']
            existing_end = data['end_time']
            
            # Verificar si hay solapamiento de horarios
            if (start_time < existing_end and end_time > existing_start):
                return False  # Hay conflicto
        
        return True  # Está disponible
    
    def update(
        self, 
        community_id: str, 
        reservation_id: str, 
        reservation_update: ReservationUpdate
    ) -> Optional[Reservation]:
        """
        Actualiza los datos de una reserva existente.
        """
        doc_ref = self._get_collection(community_id).document(reservation_id)
        
        if not doc_ref.get().exists:
            return None
        
        # Preparar datos de actualización
        update_data = reservation_update.model_dump(exclude_none=True)
        update_data['updated_at'] = datetime.now()
        
        # Convertir enums si existen
        if reservation_update.status:
            update_data['status'] = reservation_update.status.value
        
        # Actualizar en Firestore
        doc_ref.update(update_data)
        
        # Retornar reserva actualizada
        return self.get_by_id(community_id, reservation_id)
    
    def delete(self, community_id: str, reservation_id: str) -> bool:
        """
        Elimina una reserva (hard delete).
        """
        doc_ref = self._get_collection(community_id).document(reservation_id)
        
        if not doc_ref.get().exists:
            return False
        
        doc_ref.delete()
        return True
