from app.core.firebase import get_db
from app.schemas.resident import ResidentCreate, Resident

class ResidentRepository:
    def __init__(self):
        self.collection_name = "residents"
    
    def get_collection(self):
        # Obtiene la referencia a la colección en Firestore
        db = get_db()
        return db.collection(self.collection_name)

    def create_resident(self, resident: ResidentCreate) -> Resident:
        collection = self.get_collection()
        
        # .add() crea un documento con ID automático
        update_time, doc_ref = collection.add(resident.model_dump())
        
        # Retornamos el objeto con el nuevo ID
        return Resident(id=doc_ref.id, **resident.model_dump())

    def get_all_residents(self):
        collection = self.get_collection()
        docs = collection.stream()
        
        residents = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            residents.append(data)
        return residents
    
    def get_resident_by_email(self, email: str):
        collection = self.get_collection()
        # Buscamos si ya existe alguien con ese email
        query = collection.where("email", "==", email).limit(1).stream()
        for doc in query:
            data = doc.to_dict()
            data['id'] = doc.id
            return data
        return None