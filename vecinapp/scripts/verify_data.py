import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
from dotenv import load_dotenv
from pathlib import Path

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

from google.cloud import firestore as google_firestore
db = google_firestore.Client(
    credentials=cred.get_credential(), 
    project=cred.project_id
)

print("\n" + "="*60)
print("🔍 VERIFICANDO DATOS DE FIREBASE")
print("="*60 + "\n")

# Verificar comunidades
print("📍 Comunidades:")
communities = list(db.collection('communities').stream())
print(f"   Total: {len(communities)}")
for comm in communities:
    data = comm.to_dict()
    print(f"   • {data.get('name')} (ID: {comm.id})")
    
    # Contar unidades
    units = list(comm.reference.collection('units').stream())
    print(f"     └─ Unidades: {len(units)}")

print("\n👥 Usuarios:")
users = list(db.collection('users').stream())
print(f"   Total: {len(users)}")
for user in users:
    data = user.to_dict()
    print(f"   • {data.get('name')} ({data.get('email')})")
    print(f"     └─ Rol: {data.get('role')}")
    print(f"     └─ Membresías: {len(data.get('memberships', []))}")

print("\n🔐 Usuarios en Auth:")
auth_users = auth.list_users().users
print(f"   Total: {len(auth_users)}")
for user in auth_users:
    print(f"   • {user.display_name} ({user.email})")

print("\n" + "="*60)
print("✅ Verificación completada")
print("="*60 + "\n")
