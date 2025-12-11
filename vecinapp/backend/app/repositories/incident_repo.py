from google.cloud import firestore
from app.core.firebase import get_db
from app.schemas.incident import (
    IncidentCreate, 
    IncidentUpdate, 
    Incident, 
    IncidentStatus
)
from typing import List, Optional
from datetime import datetime

class IncidentRepository:
    def __init__(self):
        self.db = get_db()
    
    def _get_collection(self, community_id: str):
        """Obtiene la colección de incidentes de una comunidad"""
        return self.db.collection('communities').document(community_id).collection('incidents')
    
    def create(self, incident: IncidentCreate) -> Incident:
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
        
        # Convertir enums a valores string
        incident_data['category'] = incident.category.value
        incident_data['priority'] = incident.priority.value
        
        # Crear documento
        doc_ref = collection.document()
        incident_data['id'] = doc_ref.id
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
        
        # Ordenar por fecha de creación descendente
        query = query.order_by('created_at', direction=firestore.Query.DESCENDING)
        
        # Ejecutar query
        docs = query.stream()
        incidents = []
        
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            incidents.append(Incident(**data))
        
        return incidents
    
    def get_by_id(self, community_id: str, incident_id: str) -> Optional[Incident]:
        """Obtiene un incidente por su ID"""
        doc = self._get_collection(community_id).document(incident_id).get()
        
        if doc.exists:
            data = doc.to_dict()
            data['id'] = doc.id
            return Incident(**data)
        
        return None
    
    def update(
        self, 
        community_id: str, 
        incident_id: str, 
        incident_update: IncidentUpdate
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
