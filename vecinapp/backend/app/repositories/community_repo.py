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
        
        # Agregamos metadatos del sistema
        community_data['id'] = doc_ref.id
        community_data['created_at'] = firestore.SERVER_TIMESTAMP
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
