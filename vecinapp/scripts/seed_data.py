import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
from dotenv import load_dotenv
from pathlib import Path
from datetime import datetime

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
# NOTA: Usando DB predeterminada porque Flutter Web tiene problemas con DBs nombradas
from google.cloud import firestore as google_firestore
db = google_firestore.Client(
    credentials=cred.get_credential(), 
    project=cred.project_id
)

# === FUNCIÓN DE LIMPIEZA ===
def cleanup_data():
    """
    Elimina todos los datos de Firestore y usuarios de Auth.
    ⚠️ CUIDADO: Esta función borra TODOS los datos.
    """
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
        print(f"✅ Usuario Auth creado: {email} (UID: {user_auth.uid})")
        return user_auth.uid
    except auth.EmailAlreadyExistsError:
        user_auth = auth.get_user_by_email(email)
        print(f"ℹ️  Usuario Auth ya existe: {email} (UID: {user_auth.uid})")
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
    
    # Crear unidades (edificio con pisos y departamentos)
    units = []
    unit_number = 1
    
    for floor in range(1, floors + 1):
        for dept in range(1, units_per_floor + 1):
            # Formato: Piso-Depto (ej: 101, 102, ..., 201, 202, etc.)
            unit_code = f"{floor}{dept:02d}"
            
            unit_data = {
                "unit_number": unit_code,
                "floor": floor,
                "type": "apartment",  # departamento
                "is_occupied": False,
                "created_at": datetime.now()
            }
            
            # Guardar en subcollection 'units' de la comunidad
            unit_ref = community_ref.collection('units').document()
            unit_ref.set(unit_data)
            
            units.append({
                "id": unit_ref.id,
                "unit_number": unit_code,
                "floor": floor
            })
            
            unit_number += 1
    
    print(f"   └─ {len(units)} unidades creadas ({floors} pisos × {units_per_floor} deptos/piso)")
    
    return community_id, community_data, units

def create_user_profile(uid, first_name, last_name, email, role, community_memberships):
    """
    Crea el perfil de usuario en Firestore
    
    Args:
        uid: UID del usuario en Firebase Auth
        role: 'administrator' o 'resident'
        community_memberships: Lista de diccionarios con info de comunidades
    """
    user_ref = db.collection('users').document(uid)
    
    user_data = {
        "id": uid,
        "name": f"{first_name} {last_name}",
        "email": email,
        "role": role,
        "photoUrl": None,
        "communityId": community_memberships[0]['community_id'] if community_memberships else None,
        "memberships": community_memberships,
        "is_active": True,
        "created_at": datetime.now()
    }
    
    user_ref.set(user_data, merge=True)
    print(f"✅ Perfil de {role} guardado: {first_name} {last_name}")
    
    return user_data

def seed_complete_data():
    """Pobla Firebase con datos completos de prueba"""
    print("\n" + "="*60)
    print("🌱 POBLAMIENTO COMPLETO DE FIREBASE")
    print("="*60 + "\n")
    
    # LIMPIAR DATOS EXISTENTES
    cleanup_data()
    
    # ========================================
    # 1. CREAR COMUNIDADES CON UNIDADES
    # ========================================
    print("📍 Creando comunidades...\n")
    
    # Comunidad 1: Edificio Las Condes
    comm1_id, comm1_data, comm1_units = create_community_with_units(
        name="Edificio Las Condes",
        address="Av. Apoquindo 4500",
        comuna="Las Condes",
        region="Metropolitana",
        floors=4,
        units_per_floor=6
    )
    
    # Comunidad 2: Condominio Huechuraba
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
    # 2. CREAR USUARIOS EN FIREBASE AUTH
    # ========================================
    print("👤 Creando usuarios en Firebase Auth...\n")
    
    # Usuario Administrador
    admin_uid = create_auth_user(
        email="caravenav1989@gmail.com",
        password="Admin123!",
        display_name="Carlos Aravena"
    )
    
    # Usuario Residente
    resident_uid = create_auth_user(
        email="residente@vecinapp.cl",
        password="Residente123!",
        display_name="María González"
    )
    
    print()
    
    # ========================================
    # 3. CREAR PERFILES EN FIRESTORE
    # ========================================
    print("📝 Creando perfiles en Firestore...\n")
    
    # Perfil del Administrador (asignado a ambas comunidades)
    if admin_uid:
        admin_memberships = [
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
            uid=admin_uid,
            first_name="Carlos",
            last_name="Aravena",
            email="caravenav1989@gmail.com",
            role="administrator",
            community_memberships=admin_memberships
        )
    
    # Perfil del Residente (asignado a Edificio Las Condes, depto 301)
    if resident_uid:
        # Asignar al departamento 301 (piso 3, depto 01)
        assigned_unit = next((u for u in comm1_units if u['unit_number'] == '301'), None)
        
        resident_memberships = [
            {
                "community_id": comm1_id,
                "community_name": comm1_data['name'],
                "unit_id": assigned_unit['id'] if assigned_unit else None,
                "unit_number": assigned_unit['unit_number'] if assigned_unit else None,
                "roles": ["resident"],
                "start_date": datetime.now(),
                "is_active": True
            }
        ]
        
        create_user_profile(
            uid=resident_uid,
            first_name="María",
            last_name="González",
            email="residente@vecinapp.cl",
            role="resident",
            community_memberships=resident_memberships
        )
        
        # Marcar la unidad como ocupada
        if assigned_unit:
            unit_ref = db.collection('communities').document(comm1_id).collection('units').document(assigned_unit['id'])
            unit_ref.update({
                "is_occupied": True,
                "resident_uid": resident_uid,
                "resident_name": "María González"
            })
            print(f"   └─ Unidad {assigned_unit['unit_number']} asignada a María González")
    
    # ========================================
    # RESUMEN FINAL
    # ========================================
    print("\n" + "="*60)
    print("🎉 ¡DATOS CARGADOS EXITOSAMENTE!")
    print("="*60)
    
    print("\n📊 RESUMEN:")
    print(f"   • Comunidades creadas: 2")
    print(f"   • Unidades por comunidad: 24 (4 pisos × 6 deptos)")
    print(f"   • Usuarios creados: 2")
    
    print("\n🔐 CREDENCIALES DE ACCESO:")
    print("\n   👨‍💼 ADMINISTRADOR:")
    print(f"      Email: caravenav1989@gmail.com")
    print(f"      Password: Admin123!")
    print(f"      Acceso: Ambas comunidades")
    
    print("\n   👤 RESIDENTE:")
    print(f"      Email: residente@vecinapp.cl")
    print(f"      Password: Residente123!")
    print(f"      Comunidad: {comm1_data['name']}")
    print(f"      Unidad: 301")
    
    print("\n📍 COMUNIDADES:")
    print(f"   1. {comm1_data['name']}")
    print(f"      📍 {comm1_data['address']}, {comm1_data['comuna']}")
    print(f"      🏢 24 unidades (101-106, 201-206, 301-306, 401-406)")
    
    print(f"\n   2. {comm2_data['name']}")
    print(f"      📍 {comm2_data['address']}, {comm2_data['comuna']}")
    print(f"      🏢 24 unidades (101-106, 201-206, 301-306, 401-406)")
    
    print("\n" + "="*60)
    print("✅ Listo para usar con: cd frontend && flutter run -d chrome")
    print("="*60 + "\n")

if __name__ == "__main__":
    seed_complete_data()
