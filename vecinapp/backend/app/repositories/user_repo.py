from google.cloud import firestore
from firebase_admin import auth
from app.core.firebase import get_db
from app.schemas.user import UserCreate, User, CommunityMembershipBase
from typing import List, Optional

class UserRepository:
    def __init__(self):
        self.db = get_db()
        self.collection = self.db.collection('users')

    def create(self, user: UserCreate) -> User:
        """
        Crea un usuario en Firebase Auth y guarda sus datos en Firestore.
        """
        # 1. Crear usuario en Firebase Authentication
        try:
            auth_user = auth.create_user(
                email=user.email,
                password=user.password,
                display_name=f"{user.first_name} {user.last_name}",
                phone_number=user.phone
            )
        except auth.EmailAlreadyExistsError:
            # Si ya existe en Auth, buscamos si existe en Firestore
            # Esto permite "reparar" usuarios o manejar duplicados
            try:
                auth_user = auth.get_user_by_email(user.email)
            except Exception as e:
                raise ValueError(f"Error al obtener usuario existente: {str(e)}")
        except Exception as e:
            raise ValueError(f"Error al crear usuario en Auth: {str(e)}")

        # 2. Preparar datos para Firestore (excluyendo password)
        user_data = user.model_dump(exclude={'password'})
        user_data['id'] = auth_user.uid
        
        # Convertir Enums y Fechas para Firestore
        if user.gender:
            user_data['gender'] = user.gender.value
        if user.category:
            user_data['category'] = user.category.value
        if user.birth_date:
            user_data['birth_date'] = user.birth_date.isoformat()
            
        # Serializar vehículos
        user_data['vehicles'] = [v.model_dump() for v in user.vehicles]
        
        # Serializar membresías (aunque al crear suele estar vacío)
        user_data['memberships'] = [] 

        # 3. Guardar en Firestore
        self.collection.document(auth_user.uid).set(user_data)
        
        return User(**user_data)

    def get_all(self) -> List[User]:
        """Obtiene todos los usuarios registrados en Firestore"""
        docs = self.collection.stream()
        return [User(**doc.to_dict()) for doc in docs]

    def get_by_id(self, uid: str) -> Optional[User]:
        """Busca un usuario por su UID"""
        doc = self.collection.document(uid).get()
        if doc.exists:
            return User(**doc.to_dict())
        return None

    def add_membership(self, uid: str, membership: CommunityMembershipBase):
        """Agrega una membresía a un usuario existente"""
        user_ref = self.collection.document(uid)
        
        # Usamos array_union para agregar sin duplicar
        membership_data = membership.model_dump()
        
        # Convertir Enums y Fechas
        membership_data['roles'] = [r.value for r in membership.roles]
        membership_data['start_date'] = membership.start_date.isoformat()
        if membership.end_date:
            membership_data['end_date'] = membership.end_date.isoformat()
            
        user_ref.update({
            'memberships': firestore.ArrayUnion([membership_data])
        })
