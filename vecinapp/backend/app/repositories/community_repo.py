from google.cloud import firestore
from app.core.firebase import get_db
from app.schemas.community import CommunityCreate, Community
from typing import List, Optional

class CommunityRepository:
    def __init__(self):
        self.db = get_db()
        self.collection = self.db.collection('communities')

    def create(self, community: CommunityCreate) -> Community:
        """Crea una nueva comunidad en Firestore"""
        # Generamos un ID automático o usamos uno basado en el nombre (opcional)
        doc_ref = self.collection.document()
        
        # Convertimos el modelo Pydantic a diccionario
        community_data = community.model_dump()
        
        # FIX: Firestore no soporta datetime.date, convertimos a datetime
        from datetime import datetime, date
        if community_data.get('fecha_entrega_inicial') and isinstance(community_data['fecha_entrega_inicial'], date):
             # Convertir a datetime a medianoche
             d = community_data['fecha_entrega_inicial']
             community_data['fecha_entrega_inicial'] = datetime(d.year, d.month, d.day)

        # Agregamos metadatos del sistema
        community_data['id'] = doc_ref.id
        # Usamos datetime.now() para que sea compatible con Pydantic inmediatamente
        now = datetime.now()
        community_data['created_at'] = now
        community_data['is_active'] = True
        
        # Guardamos en BD
        doc_ref.set(community_data)
        
        # Retornamos el objeto con el ID generado
        return Community(**community_data)

    def get_all(self) -> List[Community]:
        """Obtiene todas las comunidades activas"""
        docs = self.collection.where('is_active', '==', True).stream()
        return [Community(**doc.to_dict()) for doc in docs]

    def get_by_id(self, community_id: str) -> Optional[Community]:
        """Busca una comunidad por su ID"""
        doc = self.collection.document(community_id).get()
        if doc.exists:
            return Community(**doc.to_dict())
        return None

    def update(self, community_id: str, community_update: dict) -> Optional[Community]:
        """Actualiza una comunidad existente"""
        doc_ref = self.collection.document(community_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return None
            
        # FIX: Firestore no soporta datetime.date, convertimos a datetime
        from datetime import datetime, date
        if community_update.get('fecha_entrega_inicial') and isinstance(community_update['fecha_entrega_inicial'], date):
             # Convertir a datetime a medianoche
             d = community_update['fecha_entrega_inicial']
             community_update['fecha_entrega_inicial'] = datetime(d.year, d.month, d.day)

        # Actualizamos solo los campos proporcionados
        doc_ref.update(community_update)
        
        # Obtenemos el documento actualizado
        updated_doc = doc_ref.get()
        return Community(**updated_doc.to_dict())

    def delete(self, community_id: str) -> bool:
        """Desactiva (soft delete) una comunidad"""
        doc_ref = self.collection.document(community_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return False
            
        doc_ref.update({'is_active': False})
        return True
