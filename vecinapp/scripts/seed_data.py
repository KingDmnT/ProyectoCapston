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

# Conectar a la base de datos específica 'vecinappdb' usando el constructor directo de Client
# firestore.client() es un wrapper que a veces no expone todos los argumentos en versiones antiguas
from google.cloud import firestore as google_firestore
db = google_firestore.Client(credentials=cred.get_credential(), project=cred.project_id, database='vecinappdb')

def seed_data():
    print("🌱 Iniciando poblamiento de datos...")

    # 1. Crear Comunidad Demo
    community_ref = db.collection('communities').document()
    community_id = community_ref.id
    community_data = {
        "id": community_id,
        "name": "Comunidad Demo",
        "address": "Av. Siempre Viva 742",
        "comuna": "Springfield",
        "region": "Metropolitana",
        "is_active": True,
        "created_at": datetime.now()
    }
    community_ref.set(community_data)
    print(f"✅ Comunidad creada: {community_data['name']} (ID: {community_id})")

    # 2. Crear Usuario Super Admin
    email = "admin@vecinapp.cl"
    password = "password123"
    rut = "11.111.111-1"
    
    try:
        user_auth = auth.create_user(
            email=email,
            password=password,
            display_name="Super Admin"
        )
        uid = user_auth.uid
        print(f"✅ Usuario Auth creado: {email} (UID: {uid})")
    except auth.EmailAlreadyExistsError:
        user_auth = auth.get_user_by_email(email)
        uid = user_auth.uid
        print(f"ℹ️ Usuario Auth ya existe: {email} (UID: {uid})")

    # 3. Guardar datos en Firestore (Perfil + Membresía)
    user_ref = db.collection('users').document(uid)
    user_data = {
        "id": uid,
        "first_name": "Super",
        "last_name": "Admin",
        "email": email,
        "rut": rut,
        "is_active": True,
        "memberships": [
            {
                "community_id": community_id,
                "community_name": community_data['name'],
                "roles": ["Super Admin"],
                "start_date": datetime.now(),
                "is_active": True
            }
        ],
        "created_at": datetime.now()
    }
    user_ref.set(user_data, merge=True)
    print(f"✅ Perfil de Super Admin guardado en Firestore")

    print("\n🎉 ¡Datos iniciales cargados correctamente!")
    print(f"👉 Usuario: {email}")
    print(f"👉 Contraseña: {password}")

if __name__ == "__main__":
    seed_data()
