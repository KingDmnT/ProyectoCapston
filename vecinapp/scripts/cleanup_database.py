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
from google.cloud import firestore as google_firestore
db = google_firestore.Client(
    credentials=cred.get_credential(), 
    project=cred.project_id
)

def delete_collection(collection_ref, batch_size=100):
    """Elimina una colección completa incluyendo subcollections"""
    deleted = 0
    docs = collection_ref.limit(batch_size).stream()
    
    for doc in docs:
        # Eliminar subcollections conocidas
        subcollections = ['units', 'maintenances', 'common_expenses']
        for subcoll_name in subcollections:
            subcoll_ref = doc.reference.collection(subcoll_name)
            delete_collection(subcoll_ref, batch_size)
        
        # Eliminar el documento
        doc.reference.delete()
        deleted += 1
    
    if deleted >= batch_size:
        # Recursión para eliminar más documentos
        return deleted + delete_collection(collection_ref, batch_size)
    
    return deleted

def cleanup_database():
    """Elimina todos los datos de Firestore y usuarios de Auth"""
    print("\n" + "="*70)
    print("🧹 LIMPIEZA COMPLETA DE BASE DE DATOS")
    print("="*70)
    print("\n⚠️  ADVERTENCIA: Esta operación eliminará TODOS los datos de Firebase")
    print("   - Todos los usuarios de Authentication")
    print("   - Todas las comunidades y sus datos")
    print("   - Todos los perfiles de usuario")
    print("   - Todas las mantenciones")
    print("   - Todos los gastos comunes")
    print("\n❓ ¿Estás seguro de continuar? (escribe 'SI' para confirmar): ", end='')
    
    confirmation = input().strip()
    
    if confirmation != 'SI':
        print("\n❌ Operación cancelada por el usuario")
        return
    
    print("\n🗑️  Iniciando limpieza...\n")
    
    # 1. Eliminar usuarios de Firebase Auth
    print("1️⃣  Eliminando usuarios de Authentication...")
    try:
        page = auth.list_users()
        deleted_users = 0
        while page:
            for user in page.users:
                auth.delete_user(user.uid)
                deleted_users += 1
                print(f"   ✓ Usuario eliminado: {user.email}")
            
            # Obtener siguiente página
            page = page.get_next_page()
        
        print(f"\n   ✅ Total usuarios eliminados: {deleted_users}")
    except Exception as e:
        print(f"   ⚠️  Error eliminando usuarios: {e}")
    
    # 2. Eliminar colección 'users'
    print("\n2️⃣  Eliminando colección 'users'...")
    try:
        users_ref = db.collection('users')
        deleted = delete_collection(users_ref)
        print(f"   ✅ {deleted} documentos eliminados de 'users'")
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
    
    # 3. Eliminar colección 'communities' (incluyendo subcollections)
    print("\n3️⃣  Eliminando colección 'communities' (con subcollections)...")
    try:
        communities_ref = db.collection('communities')
        deleted = delete_collection(communities_ref)
        print(f"   ✅ {deleted} comunidades y todos sus datos eliminados")
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
    
    # 4. Eliminar otras colecciones si existen
    print("\n4️⃣  Limpiando colecciones adicionales...")
    additional_collections = ['notifications', 'settings', 'logs']
    for coll_name in additional_collections:
        try:
            coll_ref = db.collection(coll_name)
            deleted = delete_collection(coll_ref)
            if deleted > 0:
                print(f"   ✅ {deleted} documentos eliminados de '{coll_name}'")
        except Exception as e:
            print(f"   ℹ️  Colección '{coll_name}' no existe o ya está vacía")
    
    print("\n" + "="*70)
    print("✅ LIMPIEZA COMPLETADA")
    print("="*70)
    print("\n📊 Base de datos completamente limpia y lista para seed data")
    print("\n💡 Ahora puedes ejecutar:")
    print("   - python scripts/seed_data.py (datos originales)")
    print("   - python scripts/seed_data_palmas.py (Condominio Las Palmas)")
    print("="*70 + "\n")

if __name__ == "__main__":
    cleanup_database()
