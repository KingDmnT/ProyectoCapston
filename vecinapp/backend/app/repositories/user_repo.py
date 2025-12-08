from google.cloud import firestore
from firebase_admin import auth
from app.core.firebase import get_db
from app.schemas.user import UserCreate, UserUpdate, User, CommunityMembershipBase, UserRole
from typing import List, Optional
from datetime import datetime

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
            try:
                auth_user = auth.get_user_by_email(user.email)
            except Exception as e:
                raise ValueError(f"Error al obtener usuario existente: {str(e)}")
        except Exception as e:
            raise ValueError(f"Error al crear usuario en Auth: {str(e)}")

        # 2. Preparar datos para Firestore (excluyendo password)
        user_data = user.model_dump(exclude={'password'})
        user_data['id'] = auth_user.uid
        user_data['is_active'] = True
        user_data['photoUrl'] = None  # Sin foto inicialmente
        user_data['created_at'] = datetime.now()
        user_data['updated_at'] = datetime.now()
        
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

    def get_all(
        self, 
        community_id: Optional[str] = None,
        role: Optional[str] = None,
        is_active: Optional[bool] = None
    ) -> List[User]:
        """
        Obtiene todos los usuarios registrados en Firestore con filtros opcionales.
        """
        query = self.collection
        
        # Filtrar por estado activo
        if is_active is not None:
            query = query.where('is_active', '==', is_active)
        
        # Obtener documentos
        docs = query.stream()
        users = []
        
        for doc in docs:
            user_data = doc.to_dict()
            
            # Filtrar por comunidad si se especifica
            if community_id:
                memberships = user_data.get('memberships', [])
                has_community = any(
                    m.get('community_id') == community_id and m.get('is_active', True) 
                    for m in memberships
                )
                if not has_community:
                    continue
            
            #  Filtrar por rol si se especifica (buscar en memberships)
            if role:
                memberships = user_data.get('memberships', [])
                has_role = any(
                    role in [r if isinstance(r, str) else r.value for r in m.get('roles', [])]
                    for m in memberships
                )
                if not has_role:
                    continue
                
            users.append(User(**user_data))
        
        return users

    def get_by_id(self, uid: str) -> Optional[User]:
        """Busca un usuario por su UID"""
        doc = self.collection.document(uid).get()
        if doc.exists:
            return User(**doc.to_dict())
        return None

    def update(self, uid: str, user_update: UserUpdate) -> Optional[User]:
        """
        Actualiza los datos de un usuario existente.
        """
        user_ref = self.collection.document(uid)
        
        # Verificar que el usuario existe
        if not user_ref.get().exists:
            return None
        
        # Preparar datos de actualización (solo campos que no sean None)
        update_data = user_update.model_dump(exclude_none=True)
        update_data['updated_at'] = datetime.now()
        
        # Convertir Enums
        if user_update.gender:
            update_data['gender'] = user_update.gender.value
        if user_update.category:
            update_data['category'] = user_update.category.value
        if user_update.birth_date:
            update_data['birth_date'] = user_update.birth_date.isoformat()
        if user_update.vehicles:
            update_data['vehicles'] = [v.model_dump() for v in user_update.vehicles]
        
        # Actualizar en Firestore
        user_ref.update(update_data)
        
        # Retornar usuario actualizado
        return self.get_by_id(uid)

    def delete(self, uid: str) -> bool:
        """
        Soft delete: marca el usuario como inactivo.
        """
        user_ref = self.collection.document(uid)
        
        # Verificar que el usuario existe
        if not user_ref.get().exists:
            return False
        
        # Marcar como inactivo
        user_ref.update({
            'is_active': False,
            'updated_at': datetime.now()
        })
        
        return True

    def assign_to_unit(
        self, 
        user_id: str, 
        community_id: str, 
        unit_id: str,
        roles: List[UserRole]
    ) -> Optional[User]:
        """
        Asigna un usuario a una unidad en una comunidad.
        Crea o actualiza la membresía correspondiente.
        """
        user_ref = self.collection.document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            return None
        
        user_data = user_doc.to_dict()
        
        # Obtener información de la comunidad y unidad
        community_ref = self.db.collection('communities').document(community_id)
        community_doc = community_ref.get()
        
        if not community_doc.exists:
            raise ValueError("Comunidad no encontrada")
        
        community_name = community_doc.to_dict().get('name', '')
        
        # Buscar unidad
        unit_ref = community_ref.collection('units').document(unit_id)
        unit_doc = unit_ref.get()
        
        if not unit_doc.exists:
            raise ValueError("Unidad no encontrada")
        
        # Extraer el nombre de la unidad
        unit_name = unit_doc.to_dict().get('name', '')
        
        # Crear nueva membresía (una por unidad)
        new_membership = {
            'community_id': community_id,
            'community_name': community_name,
            'unit_id': unit_id,
            'unit_number': unit_name,  # Guardar el name de la unidad
            'roles': [r.value if isinstance(r, UserRole) else r for r in roles],
            'start_date': datetime.now(),
            'is_active': True
        }
        
        # Obtener membresías actuales
        memberships = user_data.get('memberships', [])
        
        # Verificar si ya tiene esta UNIDAD específica asignada
        existing_idx = None
        for idx, m in enumerate(memberships):
            if m.get('community_id') == community_id and m.get('unit_id') == unit_id:
                existing_idx = idx
                break
        
        if existing_idx is not None:
            # Actualizar membresía existente de esta unidad
            memberships[existing_idx] = new_membership
        else:
            # Agregar nueva membresía (permite múltiples unidades por comunidad)
            memberships.append(new_membership)
        
        # Actualizar usuario
        user_ref.update({
            'memberships': memberships,
            'updated_at': datetime.now()
        })
        
        # Marcar unidad como ocupada y cambiar estado a Asignado
        unit_ref.update({
            'is_occupied': True,
            'status': 'Asignado',  # Cambiar estado de la unidad
            'resident_uid': user_id,
            'resident_name': f"{user_data.get('first_name', '')} {user_data.get('last_name', '')}",
            'updated_at': datetime.now()
        })
        
        return self.get_by_id(user_id)

    def unassign_from_community(self, user_id: str, community_id: str) -> Optional[User]:
        """
        Desasigna un usuario de una comunidad.
        Marca la membresía como inactiva.
        """
        user_ref = self.collection.document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            return None
        
        user_data = user_doc.to_dict()
        memberships = user_data.get('memberships', [])
        
        # Buscar y desactivar membresía
        unit_id_to_free = None
        for membership in memberships:
            if membership.get('community_id') == community_id and membership.get('is_active', True):
                membership['is_active'] = False
                membership['end_date'] = datetime.now()
                unit_id_to_free = membership.get('unit_id')
        
        # Actualizar usuario
        user_ref.update({
            'memberships': memberships,
            'updated_at': datetime.now()
        })
        
        # Liberar unidad si existía y restaurar estado a Disponible
        if unit_id_to_free:
            community_ref = self.db.collection('communities').document(community_id)
            unit_ref = community_ref.collection('units').document(unit_id_to_free)
            unit_ref.update({
                'is_occupied': False,
                'status': 'Disponible',  # Restaurar estado de la unidad
                'resident_uid': None,
                'resident_name': None,
                'updated_at': datetime.now()
            })
        
        return self.get_by_id(user_id)

    def unassign_from_unit(self, user_id: str, community_id: str, unit_id: str) -> Optional[User]:
        """
        Desasigna un usuario de UNA unidad específica.
        Elimina la membership correspondiente y libera la unidad.
        """
        user_ref = self.collection.document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            return None
        
        user_data = user_doc.to_dict()
        memberships = user_data.get('memberships', [])
        
        # Encontrar y ELIMINAR la membership de esta unidad específica
        new_memberships = []
        unit_found = False
        
        for membership in memberships:
            if (membership.get('community_id') == community_id and 
                membership.get('unit_id') == unit_id):
                # Esta es la que queremos eliminar
                unit_found = True
            else:
                # Mantener las demás
                new_memberships.append(membership)
        
        if not unit_found:
            # No se encontró esa membership
            return self.get_by_id(user_id)
        
        # Actualizar usuario con memberships filtradas
        user_ref.update({
            'memberships': new_memberships,
            'updated_at': datetime.now()
        })
        
        # Liberar la unidad
        community_ref = self.db.collection('communities').document(community_id)
        unit_ref = community_ref.collection('units').document(unit_id)
        unit_ref.update({
            'is_occupied': False,
            'status': 'Disponible',
            'resident_uid': None,
            'resident_name': None,
            'updated_at': datetime.now()
        })
        
        return self.get_by_id(user_id)

    def add_membership(self, uid: str, membership: CommunityMembershipBase):
        """Agrega una membresía a un usuario existente"""
        user_ref = self.collection.document(uid)
        
        # Preparar datos de membresía
        membership_data = membership.model_dump()
        
        # Convertir Enums y Fechas
        membership_data['roles'] = [r.value for r in membership.roles]
        membership_data['start_date'] = membership.start_date.isoformat()
        if membership.end_date:
            membership_data['end_date'] = membership.end_date.isoformat()
            
        user_ref.update({
            'memberships': firestore.ArrayUnion([membership_data])
        })
