from google.cloud import firestore
from app.core.firebase import get_db
from app.schemas.incident import (
    IncidentCreate, 
    IncidentUpdate, 
    Incident, 
    IncidentStatus,
    IncidentCategory
)
from app.schemas.incident_comment import IncidentComment, IncidentCommentCreate
from typing import List, Optional
from datetime import datetime

class IncidentRepository:
    def __init__(self):
        self.db = get_db()
    
    def _get_collection(self, community_id: str):
        """Obtiene la colección de incidentes de una comunidad"""
        return self.db.collection('communities').document(community_id).collection('incidents')
    
    def create(self, incident: IncidentCreate, user_info: dict) -> Incident:
        """
        Crea un nuevo incidente en Firestore.
        """
        collection = self._get_collection(incident.community_id)
        
        # Preparar datos
        incident_data = incident.model_dump()
        incident_data['status'] = IncidentStatus.PENDIENTE.value
        incident_data['admin_notes'] = None
        incident_data['created_at'] = datetime.now()
        incident_data['updated_at'] = datetime.now()
        
        # Campos de trazabilidad
        incident_data['reported_by_id'] = user_info.get('id')
        incident_data['reported_by_name'] = f"{user_info.get('first_name', '')} {user_info.get('last_name', '')}".strip()
        incident_data['reported_by_unit'] = None # Se podría buscar si es necesario
        
        # Buscar unidad del usuario si existe en sus memberships
        memberships = user_info.get('memberships', [])
        for m in memberships:
            if m.get('community_id') == incident.community_id and m.get('is_active'):
                incident_data['reported_by_unit'] = m.get('unit_number')
                break
        
        # Flag de seguridad
        incident_data['is_security'] = incident.category == IncidentCategory.SEGURIDAD
        
        # Convertir enums a valores string
        incident_data['category'] = incident.category.value
        incident_data['priority'] = incident.priority.value
        
        # Inicializar lista de comentarios vacía (aunque se use subcolección, para el modelo)
        incident_data['comments'] = []
        
        # Crear documento
        doc_ref = collection.document()
        incident_data['id'] = doc_ref.id
        
        # Asegurar que created_by esté presente para filtros
        if 'created_by' not in incident_data or not incident_data['created_by']:
            incident_data['created_by'] = user_info.get('id')
        
        doc_ref.set(incident_data)
        
        return Incident(**incident_data)
    
    def get_all(
        self,
        community_id: str,
        category: Optional[str] = None,
        status: Optional[str] = None,
        created_by: Optional[str] = None
    ) -> List[Incident]:
        """
        Obtiene todos los incidentes de una comunidad con filtros opcionales.
        """
        query = self._get_collection(community_id)
        
        # Aplicar filtros
        if category:
            query = query.where('category', '==', category)
        
        if status:
            query = query.where('status', '==', status)
        
        if created_by:
            query = query.where('created_by', '==', created_by)
        
        # Solo ordenar si no hay filtro de created_by (para evitar índice compuesto)
        # Cuando hay created_by, ordenaremos en memoria después
        if not created_by:
            query = query.order_by('created_at', direction=firestore.Query.DESCENDING)
        
        # Ejecutar query
        docs = query.stream()
        incidents = []
        
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            
            # Cargar comentarios para este incidente
            comments = self.get_comments(community_id, doc.id)
            data['comments'] = [c.model_dump() for c in comments]
            
            incidents.append(Incident(**data))
        
        # Si usamos created_by, ordenar en memoria
        if created_by and incidents:
            incidents.sort(key=lambda x: x.created_at or datetime.min, reverse=True)
        
        return incidents
    
    def get_by_id(self, community_id: str, incident_id: str) -> Optional[Incident]:
        """Obtiene un incidente por su ID"""
        doc = self._get_collection(community_id).document(incident_id).get()
        
        if doc.exists:
            data = doc.to_dict()
            data['id'] = doc.id
            
            # Cargar comentarios para este incidente
            comments = self.get_comments(community_id, doc.id)
            data['comments'] = [c.model_dump() for c in comments]
            
            return Incident(**data)
        
        return None
    
        
    def update(
        self, 
        community_id: str, 
        incident_id: str, 
        incident_update: IncidentUpdate,
        user_info: Optional[dict] = None
    ) -> Optional[Incident]:
        """
        Actualiza los datos de un incidente existente.
        """
        doc_ref = self._get_collection(community_id).document(incident_id)
        
        if not doc_ref.get().exists:
            return None
        
        # Preparar datos de actualización
        update_data = incident_update.model_dump(exclude_none=True)
        update_data['updated_at'] = datetime.now()
        
        # Convertir enums si existen
        if incident_update.status:
            update_data['status'] = incident_update.status.value
            
            # Si se resuelve, guardar quién y cuándo
            if incident_update.status == IncidentStatus.RESUELTO:
                update_data['resolved_at'] = datetime.now()
                if user_info:
                    update_data['resolved_by_id'] = user_info.get('id')
                    update_data['resolved_by_name'] = f"{user_info.get('first_name', '')} {user_info.get('last_name', '')}".strip()
            # Si se reabre, limpiar datos de resolución
            elif incident_update.status == IncidentStatus.EN_PROCESO or incident_update.status == IncidentStatus.PENDIENTE:
                update_data['resolved_at'] = None
                update_data['resolved_by_id'] = None
                update_data['resolved_by_name'] = None
        
        # Actualizar en Firestore
        doc_ref.update(update_data)
        
        # Retornar incidente actualizado
        return self.get_by_id(community_id, incident_id)
    
    def delete(self, community_id: str, incident_id: str) -> bool:
        """
        Elimina un incidente (hard delete).
        """
        doc_ref = self._get_collection(community_id).document(incident_id)
        
        if not doc_ref.get().exists:
            return False
        
        doc_ref.delete()
        return True

    def add_comment(self, community_id: str, incident_id: str, comment: IncidentCommentCreate, user_info: dict) -> IncidentComment:
        """
        Agrega un comentario a un incidente.
        """
        incident_ref = self._get_collection(community_id).document(incident_id)
        if not incident_ref.get().exists:
            raise ValueError("Incidente no encontrado")
            
        comments_ref = incident_ref.collection('comments')
        
        comment_data = {
            'incident_id': incident_id,
            'comment_text': comment.comment_text,
            'user_id': user_info.get('id'),
            'user_name': f"{user_info.get('first_name', '')} {user_info.get('last_name', '')}".strip(),
            'user_role': user_info.get('role', 'resident'),
            'created_at': datetime.now(),
            'is_resolution_comment': False # Por defecto
        }
        
        doc_ref = comments_ref.document()
        comment_data['id'] = doc_ref.id
        doc_ref.set(comment_data)
        
        return IncidentComment(**comment_data)

    def get_comments(self, community_id: str, incident_id: str) -> List[IncidentComment]:
        """
        Obtiene los comentarios de un incidente.
        """
        incident_ref = self._get_collection(community_id).document(incident_id)
        comments_ref = incident_ref.collection('comments').order_by('created_at')
        
        docs = comments_ref.stream()
        comments = []
        
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            comments.append(IncidentComment(**data))
            
        return comments
