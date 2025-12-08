import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
from dotenv import load_dotenv
from pathlib import Path
from datetime import datetime
import random

# --- Configuración ---
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / '.env'
load_dotenv(dotenv_path=ENV_PATH)

cred_path_env = os.getenv('FIREBASE_SERVICE_ACCOUNT_KEY', 'credentials/serviceAccountKey.json')
cred_path_env = cred_path_env.lstrip('/\\')
cred_path = BASE_DIR / cred_path_env

if not firebase_admin._apps:
    cred = credentials.Certificate(str(cred_path))
    firebase_admin.initialize_app(cred)
    print(f"✅ Firebase Admin inicializado con {cred_path}")

# Conectar a la base de datos predeterminada de Firestore
from google.cloud import firestore as google_firestore
db = google_firestore.Client(
    credentials=cred.get_credential(), 
    project=cred.project_id
)

# === FUNCIÓN DE LIMPIEZA ===
def cleanup_data():
    """Elimina todos los datos de Firestore y usuarios de Auth."""
    print("\n🧹 LIMPIANDO DATOS EXISTENTES...")
    
    # 1. Eliminar usuarios de Firebase Auth
    print("🗑️  Eliminando usuarios de Authentication...")
    try:
        users = auth.list_users().users
        for user in users:
            auth.delete_user(user.uid)
            print(f"   ✓ Usuario eliminado: {user.email}")
    except Exception as e:
        print(f"   ⚠️  Error eliminando usuarios: {e}")
    
    # 2. Eliminar colección 'users'
    print("🗑️  Eliminando colección 'users'...")
    try:
        users_ref = db.collection('users')
        docs = users_ref.stream()
        deleted = 0
        for doc in docs:
            doc.reference.delete()
            deleted += 1
        print(f"   ✓ {deleted} documentos eliminados de 'users'")
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
    
    # 3. Eliminar colección 'communities' (incluyendo subcollections)
    print("🗑️  Eliminando colección 'communities'...")
    try:
        communities_ref = db.collection('communities')
        docs = communities_ref.stream()
        deleted = 0
        for doc in docs:
            # Eliminar subcollection 'units'
            units_ref = doc.reference.collection('units')
            for unit in units_ref.stream():
                unit.reference.delete()
            # Eliminar documento de comunidad
            doc.reference.delete()
            deleted += 1
        print(f"   ✓ {deleted} comunidades eliminadas")
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
    
    print("✅ Limpieza completada\n")

def create_auth_user(email, password, display_name):
    """Crea un usuario en Firebase Auth"""
    try:
        user_auth = auth.create_user(
            email=email,
            password=password,
            display_name=display_name,
            email_verified=True
        )
        print(f"✅ Usuario Auth creado: {email}")
        return user_auth.uid
    except auth.EmailAlreadyExistsError:
        user_auth = auth.get_user_by_email(email)
        print(f"ℹ️  Usuario Auth ya existe: {email}")
        return user_auth.uid
    except Exception as e:
        print(f"❌ Error creando usuario {email}: {e}")
        return None

def create_community_with_units(name, address, comuna, region, floors=4, units_per_floor=6):
    """Crea una comunidad con un edificio y unidades"""
    
    # Crear comunidad
    community_ref = db.collection('communities').document()
    community_id = community_ref.id
    
    community_data = {
        "id": community_id,
        "name": name,
        "address": address,
        "comuna": comuna,
        "region": region,
        "is_active": True,
        "created_at": datetime.now()
    }
    community_ref.set(community_data)
    print(f"✅ Comunidad creada: {name} (ID: {community_id})")
    
    # Crear unidades
    units = []
    for floor in range(1, floors + 1):
        for dept in range(1, units_per_floor + 1):
            unit_code = f"{floor}{dept:02d}"
            
            unit_data = {
                "name": unit_code,
                "floor": floor,
                "type": "Departamento",
                "status": "Disponible",
                "community_id": community_id,
                "alicuota": round(100.0 / (floors * units_per_floor), 2),
                "m2": 45.0,
                "description": f"Departamento {unit_code}",
            }
            
            unit_ref = community_ref.collection('units').document()
            unit_data["id"] = unit_ref.id
            unit_ref.set(unit_data)
            
            units.append({
                "id": unit_ref.id,
                "name": unit_code,
                "floor": floor
            })
    
    print(f"   └─ {len(units)} unidades creadas")
    return community_id, community_data, units

def create_user_profile(uid, first_name, last_name, email, role, rut, community_memberships):
    """Crea el perfil de usuario en Firestore"""
    user_ref = db.collection('users').document(uid)
    
    user_data = {
        "id": uid,
        "first_name": first_name,
        "last_name": last_name,
        "name": f"{first_name} {last_name}",
        "email": email,
        "role": role,
        "rut": rut,
        "photoUrl": None,
        "communityId": community_memberships[0]['community_id'] if community_memberships else None,
        "memberships": community_memberships,
        "is_active": True,
        "created_at": datetime.now()
    }
    
    user_ref.set(user_data, merge=True)
    return user_data

def seed_complete_data():
    """Pobla Firebase con datos completos de prueba"""
    print("\n" + "="*60)
    print("🌱 POBLAMIENTO COMPLETO DE FIREBASE")
    print("="*60 + "\n")
    
    cleanup_data()
    
    # ========================================
    # 1. CREAR COMUNIDADES CON UNIDADES
    # ========================================
    print("📍 Creando comunidades...\n")
    
    comm1_id, comm1_data, comm1_units = create_community_with_units(
        name="Edificio Las Condes",
        address="Av. Apoquindo 4500",
        comuna="Las Condes",
        region="Metropolitana",
        floors=4,
        units_per_floor=6
    )
    
    comm2_id, comm2_data, comm2_units = create_community_with_units(
        name="Condominio Conecta Huechuraba",
        address="Av. Pedro Fontova 5200",
        comuna="Huechuraba",
        region="Metropolitana",
        floors=4,
        units_per_floor=6
    )
    
    print()
    
    # ========================================
    # 2. CREAR SUPER ADMIN Y ADMINS
    # ========================================
    print("👑 Creando Super Admin y Administradores...\n")
    
    # Super Admin (ve todas las comunidades)
    super_admin_uid = create_auth_user(
        email="admin@vecinapp.cl",
        password="Admin123!",
        display_name="Admin Sistema"
    )
    
    if super_admin_uid:
        super_admin_memberships = [
            {
                "community_id": comm1_id,
                "community_name": comm1_data['name'],
                "roles": ["administrator"],
                "start_date": datetime.now(),
                "is_active": True
            },
            {
                "community_id": comm2_id,
                "community_name": comm2_data['name'],
                "roles": ["administrator"],
                "start_date": datetime.now(),
                "is_active": True
            }
        ]
        
        create_user_profile(
            uid=super_admin_uid,
            first_name="Admin",
            last_name="Sistema",
            email="admin@vecinapp.cl",
            role="administrator",
            rut="11111111-1",
            community_memberships=super_admin_memberships
        )
        print("✅ Super Admin creado")
    
    # Admin Edificio Las Condes
    admin1_uid = create_auth_user(
        email="admin.lascondes@vecinapp.cl",
        password="Admin123!",
        display_name="Pedro Administrador"
    )
    
    if admin1_uid:
        admin1_memberships = [{
            "community_id": comm1_id,
            "community_name": comm1_data['name'],
            "roles": ["administrator"],
            "start_date": datetime.now(),
            "is_active": True
        }]
        
        create_user_profile(
            uid=admin1_uid,
            first_name="Pedro",
            last_name="Administrador",
            email="admin.lascondes@vecinapp.cl",
            role="administrator",
            rut="22222222-2",
            community_memberships=admin1_memberships
        )
        print("✅ Admin Las Condes creado")
    
    # Admin Condominio Huechuraba
    admin2_uid = create_auth_user(
        email="admin.huechuraba@vecinapp.cl",
        password="Admin123!",
        display_name="Laura Administradora"
    )
    
    if admin2_uid:
        admin2_memberships = [{
            "community_id": comm2_id,
            "community_name": comm2_data['name'],
            "roles": ["administrator"],
            "start_date": datetime.now(),
            "is_active": True
        }]
        
        create_user_profile(
            uid=admin2_uid,
            first_name="Laura",
            last_name="Administradora",
            email="admin.huechuraba@vecinapp.cl",
            role="administrator",
            rut="33333333-3",
            community_memberships=admin2_memberships
        )
        print("✅ Admin Huechuraba creado")
    
    print()
    
    # ========================================
    # 3. CREAR 10 RESIDENTES (5 POR COMUNIDAD)
    # ========================================
    print("👥 Creando 10 residentes de prueba...\n")
    
    # Nombres para testing (reducidos a 10)
    resident_names = [
        ("Ana", "Torres"), ("Juan", "López"), ("María", "Rojas"), ("Carlos", "Silva"),
        ("Sofía", "Muñoz"), ("Diego", "Vega"), ("Francisca", "Castro"), ("Matías", "Soto"),
        ("Valentina", "Mora"), ("Sebastián", "Paz")
    ]
    
    rut_base = 15000000
    
    # Distribuir: 5 en cada comunidad
    for i, (first_name, last_name) in enumerate(resident_names):
        # Alternar entre comunidades: primeros 5 en comm1, siguientes 5 en comm2
        if i < 5:
            community_id = comm1_id
            community_name = comm1_data['name']
            units = comm1_units
        else:
            community_id = comm2_id
            community_name = comm2_data['name']
            units = comm2_units
        
        email = f"{first_name.lower()}.{last_name.lower()}@test.cl"
        
        # Crear usuario en Auth
        resident_uid = create_auth_user(
            email=email,
            password="Test123!",
            display_name=f"{first_name} {last_name}"
        )
        
        if resident_uid:
            # Asignar 1-2 unidades al azar
            num_units = random.randint(1, 2)
            assigned_units = random.sample(units, num_units)
            
            # Crear memberships con unidades (una membership por unidad)
            memberships = []
            for unit in assigned_units:
                membership = {
                    "community_id": community_id,
                    "community_name": community_name,
                    "unit_id": unit['id'],
                    "unit_number": unit['name'],  # Usar 'name' en field 'unit_number'
                    "roles": ["resident"],
                    "start_date": datetime.now(),
                    "is_active": True
                }
                memberships.append(membership)
            
            # Crear perfil en Firestore
            create_user_profile(
                uid=resident_uid,
                first_name=first_name,
                last_name=last_name,
                email=email,
                role="resident",
                rut=f"{rut_base + i}-{random.randint(0, 9)}",
                community_memberships=memberships
            )
            
            # Actualizar estado de las unidades asignadas
            for assigned_unit in assigned_units:
                unit_ref = db.collection('communities').document(community_id).collection('units').document(assigned_unit['id'])
                unit_ref.update({
                    'status': 'Asignado',
                    'is_occupied': True,
                    'resident_uid': resident_uid,
                    'resident_name': f"{first_name} {last_name}",
                    'updated_at': datetime.now()
                })
            
            unit_names = ', '.join([u['name'] for u in assigned_units])
            print(f"✅ {first_name} {last_name} ({community_name}) - Unidades: {unit_names}")
    
    print(f"\n🎉 ¡Seed completado! 3 administradores + 10 residentes creados.")
    
    print("\n" + "="*60)
    print("🔐 CREDENCIALES:")
    print("\n   👑 SUPER ADMIN:")
    print(f"      Email: admin@vecinapp.cl")
    print(f"      Password: Admin123!")
    
    print("\n   👨‍💼 ADMINS DE COMUNIDAD:")
    print(f"      admin.lascondes@vecinapp.cl / Admin123!")
    print(f"      admin.huechuraba@vecinapp.cl / Admin123!")
    
    print("\n   👤 RESIDENTES (todos):") 
    print(f"      Password: Test123!")
    print(f"      Ejemplos: ana.torres@test.cl, juan.lopez@test.cl")
    
    print("\n" + "="*60)
    print("✅ Listo para usar")
    print("="*60 + "\n")

if __name__ == "__main__":
    seed_complete_data()
