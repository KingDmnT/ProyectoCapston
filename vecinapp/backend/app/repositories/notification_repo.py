from google.cloud import firestore
from app.core.firebase import get_db
from app.schemas.notification import (
    NotificationCreate, 
    Notification
)
from typing import List, Optional
from datetime import datetime

class NotificationRepository:
    def __init__(self):
        self.db = get_db()
    
    def _get_collection(self, community_id: str):
        """Obtiene la colección de notificaciones de una comunidad"""
        return self.db.collection('communities').document(community_id).collection('notifications')
    
    def get_community_admins(self, community_id: str) -> List[str]:
        """
        Obtiene los IDs de todos los administradores de una comunidad.
        """
        # Buscar usuarios con membresía de admin en esta comunidad
        users_ref = self.db.collection('users')
        
        # Query para usuarios con rol admin en la comunidad
        query = users_ref.where('memberships', 'array_contains', {
            'communityId': community_id,
            'role': 'admin'
        })
        
        # Como Firestore no soporta queries complejas en arrays, 
        # hacemos la búsqueda filtrando en memoria
        all_users = users_ref.stream()
        admin_ids = []
        
        for user_doc in all_users:
            user_data = user_doc.to_dict()
            memberships = user_data.get('memberships', [])
            
            for membership in memberships:
                if (membership.get('communityId') == community_id and 
                    membership.get('role') == 'admin'):
                    admin_ids.append(user_doc.id)
                    break
        
        return admin_ids
    
    def create_bulk(self, notification: NotificationCreate) -> List[Notification]:
        """
        Crea múltiples notificaciones (una para cada usuario en target_user_ids).
        """
        collection = self._get_collection(notification.community_id)
        
        notifications = []
        
        for user_id in notification.target_user_ids:
            # Preparar datos para cada usuario
            notif_data = {
                'type': notification.type.value,
                'title': notification.title,
                'message': notification.message,
                'community_id': notification.community_id,
                'related_entity_id': notification.related_entity_id,
                'related_entity_type': notification.related_entity_type,
                'user_id': user_id,
                'is_read': False,
                'created_at': datetime.now()
            }
            
            # Crear documento
            doc_ref = collection.document()
            notif_data['id'] = doc_ref.id
            doc_ref.set(notif_data)
            
            notifications.append(Notification(**notif_data))
        
        return notifications
    
    def get_user_notifications(
        self,
        community_id: str,
        user_id: str,
        is_read: Optional[bool] = None,
        limit: int = 50
    ) -> List[Notification]:
        """
        Obtiene las notificaciones de un usuario específico.
        """
        query = self._get_collection(community_id).where('user_id', '==', user_id)
        
        if is_read is not None:
            query = query.where('is_read', '==', is_read)
        
        # Ordenar por fecha de creación descendente
        query = query.order_by('created_at', direction=firestore.Query.DESCENDING)
        
        # Limitar resultados
        query = query.limit(limit)
        
        # Ejecutar query
        docs = query.stream()
        notifications = []
        
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            notifications.append(Notification(**data))
        
        return notifications
    
    def mark_as_read(
        self, 
        community_id: str, 
        notification_id: str
    ) -> Optional[Notification]:
        """
        Marca una notificación como leída.
        """
        doc_ref = self._get_collection(community_id).document(notification_id)
        
        if not doc_ref.get().exists:
            return None
        
        doc_ref.update({'is_read': True})
        
        # Retornar notificación actualizada
        doc = doc_ref.get()
        if doc.exists:
            data = doc.to_dict()
            data['id'] = doc.id
            return Notification(**data)
        
        return None
    
    def get_unread_count(self, community_id: str, user_id: str) -> int:
        """
        Obtiene el número de notificaciones no leídas de un usuario.
        """
        query = self._get_collection(community_id) \
            .where('user_id', '==', user_id) \
            .where('is_read', '==', False)
        
        docs = list(query.stream())
        return len(docs)
