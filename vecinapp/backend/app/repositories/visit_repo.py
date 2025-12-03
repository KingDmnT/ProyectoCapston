from google.cloud import firestore
from app.core.firebase import get_db
from app.schemas.visit import VisitCreate, Visit, AccessLog, AccessType
from typing import List, Optional, Tuple
import uuid
from datetime import datetime
import pytz

class VisitRepository:
    def __init__(self):
        self.db = get_db()
        self.collection = self.db.collection('visits')

    def create(self, visit: VisitCreate) -> Visit:
        """Crea una visita y genera su código QR (Token)"""
        doc_ref = self.collection.document()
        
        visit_data = visit.model_dump()
        visit_data['id'] = doc_ref.id
        
        # Generar Token Seguro para QR si no viene
        if not visit_data.get('qr_code_data'):
            visit_data['qr_code_data'] = str(uuid.uuid4())
            
        # Fechas a ISO format
        visit_data['valid_from'] = visit.valid_from.isoformat()
        visit_data['valid_to'] = visit.valid_to.isoformat()
        visit_data['created_at'] = firestore.SERVER_TIMESTAMP
        
        # Logs vacíos al inicio
        visit_data['access_logs'] = []
        
        doc_ref.set(visit_data)
        
        # Recuperar para devolver con timestamp correcto
        return Visit(**visit_data)

    def validate_access(self, qr_data: str, guard_id: str, access_type: AccessType) -> Tuple[bool, str, Optional[Visit]]:
        """
        Valida el acceso por QR.
        Retorna: (EsValido, Mensaje, ObjetoVisita)
        """
        # Buscar visita por token QR
        docs = self.collection.where('qr_code_data', '==', qr_data).stream()
        visits = [Visit(**doc.to_dict()) for doc in docs]
        
        if not visits:
            return False, "Código QR no válido o no encontrado", None
            
        visit = visits[0]
        now = datetime.now(pytz.utc) # Usar UTC o timezone del servidor
        
        # 1. Validar Rango de Fecha (Naive vs Aware fix puede ser necesario)
        # Asumimos que las fechas guardadas son ISO strings, pydantic las parsea a datetime
        # Asegurarse que ambas sean comparables (offset-naive vs offset-aware)
        
        # Simple check:
        if visit.valid_from.tzinfo is None:
            visit.valid_from = visit.valid_from.replace(tzinfo=pytz.utc)
        if visit.valid_to.tzinfo is None:
            visit.valid_to = visit.valid_to.replace(tzinfo=pytz.utc)
            
        if not (visit.valid_from <= now <= visit.valid_to):
            return False, f"QR fuera de horario. Válido desde {visit.valid_from} hasta {visit.valid_to}", None
            
        # 2. Registrar Acceso
        new_log = AccessLog(
            timestamp=now,
            type=access_type,
            guard_id=guard_id
        )
        
        # Actualizar Firestore
        self.collection.document(visit.id).update({
            'access_logs': firestore.ArrayUnion([new_log.model_dump()])
        })
        
        return True, "Acceso Autorizado", visit

    def get_by_resident(self, user_id: str) -> List[Visit]:
        """Obtiene historial de visitas creadas por un residente"""
        docs = self.collection.where('host_user_id', '==', user_id).stream()
        return [Visit(**doc.to_dict()) for doc in docs]
