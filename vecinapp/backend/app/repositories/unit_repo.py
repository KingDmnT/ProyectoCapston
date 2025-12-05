from google.cloud import firestore
from app.core.firebase import get_db
from app.schemas.unit import UnitCreate, Unit
from typing import List, Optional

class UnitRepository:
    def __init__(self):
        self.db = get_db()
        self.collection = self.db.collection('units')

    def create(self, unit: UnitCreate) -> Unit:
        """Crea una nueva unidad en Firestore"""
        doc_ref = self.collection.document()
        
        unit_data = unit.model_dump()
        unit_data['id'] = doc_ref.id
        # Convertimos Enums a string para guardarlos
        unit_data['type'] = unit.type.value
        unit_data['status'] = unit.status.value
        
        doc_ref.set(unit_data)
        
        return Unit(**unit_data)

    def get_by_community(self, community_id: str) -> List[Unit]:
        """Obtiene todas las unidades de una comunidad específica"""
        docs = self.collection.where('community_id', '==', community_id).stream()
        return [Unit(**doc.to_dict()) for doc in docs]

    def get_by_id(self, unit_id: str) -> Optional[Unit]:
        """Busca una unidad por su ID"""
        doc = self.collection.document(unit_id).get()
        if doc.exists:
            return Unit(**doc.to_dict())
        return None

    def update(self, unit_id: str, unit_update: dict) -> Optional[Unit]:
        """Actualiza una unidad existente"""
        doc_ref = self.collection.document(unit_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return None
            
        # Actualizamos solo los campos proporcionados
        doc_ref.update(unit_update)
        
        # Obtenemos el documento actualizado
        updated_doc = doc_ref.get()
        return Unit(**updated_doc.to_dict())

    def delete(self, unit_id: str) -> bool:
        """Elimina una unidad (Hard delete por ahora, o soft si agregamos isActive)"""
        # Como Unit no tiene isActive en el schema, haremos hard delete por simplicidad
        # o podemos agregar isActive al schema. Por ahora hard delete.
        doc_ref = self.collection.document(unit_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return False
            
        doc_ref.delete()
        return True
