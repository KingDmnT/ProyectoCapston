import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv
from pathlib import Path

# Configuración
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

print("=" * 80)
print("🔍 VERIFICACIÓN: Ana Torres")
print("=" * 80)

# Buscar Ana Torres
users_ref = db.collection('users')
docs = users_ref.where('email', '==', 'ana.torres@test.cl').stream()

for doc in docs:
    user_data = doc.to_dict()
    print(f"\n✅ Usuario encontrado: {user_data.get('name')}")
    print(f"   Email: {user_data.get('email')}")
    print(f"   ID: {doc.id}")
    print(f"   Role: {user_data.get('role')}")
    
    memberships = user_data.get('memberships', [])
    print(f"\n📋 MEMBERSHIPS ({len(memberships)}):")
    
    for i, m in enumerate(memberships):
        print(f"\n   Membership {i}:")
        print(f"      community_id: {m.get('community_id')}")
        print(f"      community_name: {m.get('community_name')}")
        print(f"      unit_id: {m.get('unit_id')}")  # ← CRÍTICO
        print(f"      unit_number: {m.get('unit_number')}")  # ← CRÍTICO
        print(f"      roles: {m.get('roles')}")
        print(f"      is_active: {m.get('is_active')}")

print("\n" + "=" * 80)
