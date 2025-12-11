from google.cloud import firestore
from app.core.firebase import get_db
from app.schemas.announcement import (
    Announcement,
    AnnouncementCreate,
    AnnouncementUpdate,
    AnnouncementPriority
)
from typing import List, Optional
from datetime import datetime

class AnnouncementRepository:
    def __init__(self):
        self.db = get_db()
    
    def _get_collection(self, community_id: str):
        """Obtiene la colección de anuncios de una comunidad"""
        return self.db.collection('communities').document(community_id).collection('announcements')
    
    def create(self, community_id: str, announcement: AnnouncementCreate, user_info: dict) -> Announcement:
        """Crea un nuevo anuncio"""
        collection = self._get_collection(community_id)
        
        # Preparar datos
        announcement_data = announcement.model_dump()
        announcement_data['community_id'] = community_id
        announcement_data['created_by'] = user_info.get('id')
        announcement_data['created_by_name'] = f"{user_info.get('first_name', '')} {user_info.get('last_name', '')}".strip() or user_info.get('name', 'Admin')
        announcement_data['created_at'] = datetime.now()
        announcement_data['updated_at'] = datetime.now()
        announcement_data['is_active'] = True
        
        # Convertir enum a string
        if isinstance(announcement_data.get('priority'), AnnouncementPriority):
            announcement_data['priority'] = announcement_data['priority'].value
        
        # Convertir datetime a Firestore timestamp si existe expires_at
        if announcement_data.get('expires_at'):
            announcement_data['expires_at'] = announcement_data['expires_at']
        
        # Crear documento
        doc_ref = collection.document()
        announcement_data['id'] = doc_ref.id
        doc_ref.set(announcement_data)
        
        return Announcement(**announcement_data)
    
    def get_all(
        self,
        community_id: str,
        is_active: Optional[bool] = None,
        show_in_banner: Optional[bool] = None
    ) -> List[Announcement]:
        """Obtiene todos los anuncios de una comunidad con filtros opcionales"""
        query = self._get_collection(community_id)
        
        # Aplicar filtros
        if is_active is not None:
            query = query.where('is_active', '==', is_active)
        
        if show_in_banner is not None:
            query = query.where('show_in_banner', '==', show_in_banner)
        
        # Ordenar por fecha de creación descendente
        query = query.order_by('created_at', direction=firestore.Query.DESCENDING)
        
        # Ejecutar query
        docs = query.stream()
        announcements = []
        
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            
            # Filtrar anuncios expirados si is_active es True
            if is_active:
                expires_at = data.get('expires_at')
                if expires_at and datetime.now() > expires_at:
                    # Marcar como inactivo si expiró
                    doc.reference.update({'is_active': False})
                    continue
            
            announcements.append(Announcement(**data))
        
        return announcements
    
    def get_by_id(self, community_id: str, announcement_id: str) -> Optional[Announcement]:
        """Obtiene un anuncio por su ID"""
        doc = self._get_collection(community_id).document(announcement_id).get()
        
        if doc.exists:
            data = doc.to_dict()
            data['id'] = doc.id
            return Announcement(**data)
        
        return None
    
    def update(
        self,
        community_id: str,
        announcement_id: str,
        announcement_update: AnnouncementUpdate
    ) -> Optional[Announcement]:
        """Actualiza un anuncio"""
        doc_ref = self._get_collection(community_id).document(announcement_id)
        
        if not doc_ref.get().exists:
            return None
        
        # Preparar datos de actualización (solo campos no nulos)
        update_data = announcement_update.model_dump(exclude_unset=True)
        update_data['updated_at'] = datetime.now()
        
        # Convertir enum a string si existe
        if 'priority' in update_data and isinstance(update_data['priority'], AnnouncementPriority):
            update_data['priority'] = update_data['priority'].value
        
        # Actualizar documento
        doc_ref.update(update_data)
        
        # Retornar anuncio actualizado
        doc = doc_ref.get()
        if doc.exists:
            data = doc.to_dict()
            data['id'] = doc.id
            return Announcement(**data)
        
        return None
    
    def delete(self, community_id: str, announcement_id: str) -> bool:
        """Elimina un anuncio (soft delete marcando como inactivo)"""
        doc_ref = self._get_collection(community_id).document(announcement_id)
        
        if not doc_ref.get().exists:
            return False
        
        # Soft delete
        doc_ref.update({
            'is_active': False,
            'updated_at': datetime.now()
        })
        
        return True
    
    def get_active_banners(self, community_id: str) -> List[Announcement]:
        """Obtiene anuncios activos que deben mostrarse en el banner"""
        return self.get_all(
            community_id=community_id,
            is_active=True,
            show_in_banner=True
        )
