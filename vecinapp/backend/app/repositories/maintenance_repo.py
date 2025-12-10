from google.cloud import firestore
from app.core.firebase import get_db
from app.schemas.maintenance import (
    MaintenanceCreate, 
    MaintenanceUpdate, 
    Maintenance, 
    MaintenanceStatus,
    ChecklistItem
)
from typing import List, Optional
from datetime import datetime

class MaintenanceRepository:
    def __init__(self):
        self.db = get_db()
    
    def _get_collection(self, community_id: str):
        """Obtiene la colección de mantenimientos de una comunidad"""
        return self.db.collection('communities').document(community_id).collection('maintenances')
    
    def create(self, maintenance: MaintenanceCreate) -> Maintenance:
        """
        Crea una nueva orden de mantenimiento en Firestore.
        """
        collection = self._get_collection(maintenance.community_id)
        
        # Preparar datos
        maintenance_data = maintenance.model_dump()
        maintenance_data['status'] = MaintenanceStatus.PENDIENTE.value
        maintenance_data['completed_date'] = None
        maintenance_data['approved_by'] = None
        maintenance_data['approval_date'] = None
        maintenance_data['created_at'] = datetime.now()
        maintenance_data['updated_at'] = datetime.now()
        
        # Convertir enums a valores string
        maintenance_data['type'] = maintenance.type.value
        maintenance_data['frequency'] = maintenance.frequency.value
        
        # Serializar fechas
        maintenance_data['scheduled_date'] = maintenance.scheduled_date
        
        # Serializar checklist
        maintenance_data['checklist_items'] = [
            item.model_dump() for item in maintenance.checklist_items
        ]
        
        # Crear documento
        doc_ref = collection.document()
        maintenance_data['id'] = doc_ref.id
        doc_ref.set(maintenance_data)
        
        return Maintenance(**maintenance_data)
    
    def get_all(
        self,
        community_id: str,
        type: Optional[str] = None,
        status: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> List[Maintenance]:
        """
        Obtiene todos los mantenimientos de una comunidad con filtros opcionales.
        """
        query = self._get_collection(community_id)
        
        # Aplicar filtros
        if type:
            query = query.where('type', '==', type)
        
        if status:
            query = query.where('status', '==', status)
        
        if start_date:
            query = query.where('scheduled_date', '>=', start_date)
        
        if end_date:
            query = query.where('scheduled_date', '<=', end_date)
        
        # Ordenar por fecha programada descendente
        query = query.order_by('scheduled_date', direction=firestore.Query.DESCENDING)
        
        # Ejecutar query
        docs = query.stream()
        maintenances = []
        
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            maintenances.append(Maintenance(**data))
        
        return maintenances
    
    def get_by_id(self, community_id: str, maintenance_id: str) -> Optional[Maintenance]:
        """Obtiene un mantenimiento por su ID"""
        doc = self._get_collection(community_id).document(maintenance_id).get()
        
        if doc.exists:
            data = doc.to_dict()
            data['id'] = doc.id
            return Maintenance(**data)
        
        return None
    
    def update(
        self, 
        community_id: str, 
        maintenance_id: str, 
        maintenance_update: MaintenanceUpdate
    ) -> Optional[Maintenance]:
        """
        Actualiza los datos de un mantenimiento existente.
        """
        doc_ref = self._get_collection(community_id).document(maintenance_id)
        
        if not doc_ref.get().exists:
            return None
        
        # Preparar datos de actualización
        update_data = maintenance_update.model_dump(exclude_none=True)
        update_data['updated_at'] = datetime.now()
        
        # Convertir enums si existen
        if maintenance_update.type:
            update_data['type'] = maintenance_update.type.value
        
        if maintenance_update.frequency:
            update_data['frequency'] = maintenance_update.frequency.value
        
        if maintenance_update.status:
            update_data['status'] = maintenance_update.status.value
            # Si el estado es completado, registrar fecha
            if maintenance_update.status == MaintenanceStatus.COMPLETADO:
                update_data['completed_date'] = datetime.now()
        
        # Serializar checklist si existe
        if maintenance_update.checklist_items:
            update_data['checklist_items'] = [
                item.model_dump() for item in maintenance_update.checklist_items
            ]
        
        # Actualizar en Firestore
        doc_ref.update(update_data)
        
        # Retornar mantenimiento actualizado
        return self.get_by_id(community_id, maintenance_id)
    
    def update_status(
        self, 
        community_id: str, 
        maintenance_id: str, 
        status: MaintenanceStatus
    ) -> Optional[Maintenance]:
        """
        Actualiza el estado de un mantenimiento.
        """
        doc_ref = self._get_collection(community_id).document(maintenance_id)
        
        if not doc_ref.get().exists:
            return None
        
        update_data = {
            'status': status.value,
            'updated_at': datetime.now()
        }
        
        # Si el estado es completado, registrar fecha
        if status == MaintenanceStatus.COMPLETADO:
            update_data['completed_date'] = datetime.now()
        
        doc_ref.update(update_data)
        
        return self.get_by_id(community_id, maintenance_id)
    
    def approve(
        self, 
        community_id: str, 
        maintenance_id: str, 
        approved_by: str
    ) -> Optional[Maintenance]:
        """
        Aprueba un mantenimiento.
        """
        doc_ref = self._get_collection(community_id).document(maintenance_id)
        
        if not doc_ref.get().exists:
            return None
        
        doc_ref.update({
            'status': MaintenanceStatus.APROBADO.value,
            'approved_by': approved_by,
            'approval_date': datetime.now(),
            'updated_at': datetime.now()
        })
        
        return self.get_by_id(community_id, maintenance_id)
    
    def reject(
        self, 
        community_id: str, 
        maintenance_id: str, 
        rejected_by: str
    ) -> Optional[Maintenance]:
        """
        Rechaza un mantenimiento.
        """
        doc_ref = self._get_collection(community_id).document(maintenance_id)
        
        if not doc_ref.get().exists:
            return None
        
        doc_ref.update({
            'status': MaintenanceStatus.RECHAZADO.value,
            'approved_by': rejected_by,  # Guardamos quién rechazó
            'approval_date': datetime.now(),
            'updated_at': datetime.now()
        })
        
        return self.get_by_id(community_id, maintenance_id)
    
    def update_checklist(
        self, 
        community_id: str, 
        maintenance_id: str, 
        checklist_items: List[ChecklistItem]
    ) -> Optional[Maintenance]:
        """
        Actualiza el checklist de un mantenimiento.
        """
        doc_ref = self._get_collection(community_id).document(maintenance_id)
        
        if not doc_ref.get().exists:
            return None
        
        doc_ref.update({
            'checklist_items': [item.model_dump() for item in checklist_items],
            'updated_at': datetime.now()
        })
        
        return self.get_by_id(community_id, maintenance_id)
    
    def delete(self, community_id: str, maintenance_id: str) -> bool:
        """
        Elimina un mantenimiento (hard delete).
        """
        doc_ref = self._get_collection(community_id).document(maintenance_id)
        
        if not doc_ref.get().exists:
            return False
        
        doc_ref.delete()
        return True
