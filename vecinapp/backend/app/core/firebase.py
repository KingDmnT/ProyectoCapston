import firebase_admin
from firebase_admin import credentials, firestore
from app.core.config import settings
import os

# Variable global para el cliente de base de datos
db = None

def initialize_firebase():
    global db
    
    # Evitar inicializar dos veces
    if not firebase_admin._apps:
        try:
            # Verificamos si el archivo existe
            if os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                firebase_admin.initialize_app(cred)
                # db = firestore.client(database='vecinappdb')
                # Usamos el cliente directo de Google Cloud para especificar la base de datos
                from google.cloud import firestore as google_firestore
                db = google_firestore.Client(credentials=cred.get_credential(), project=cred.project_id, database='vecinappdb')
                print(f"✅ Firebase conectado usando: {settings.FIREBASE_CREDENTIALS_PATH}")
            else:
                print(f"⚠️ ERROR CRÍTICO: No se encontró el archivo de credenciales en {settings.FIREBASE_CREDENTIALS_PATH}")
                print("   Asegúrate de haber puesto serviceAccountKey.json en la carpeta 'credentials' y reiniciado Docker.")
        except Exception as e:
            print(f"❌ Error inicializando Firebase: {e}")
    else:
        # db = firestore.client(database='vecinappdb')
        from google.cloud import firestore as google_firestore
        app = firebase_admin.get_app()
        cred = app.credential
        db = google_firestore.Client(credentials=cred.get_credential(), project=cred.project_id, database='vecinappdb')

def get_db():
    if db is None:
        initialize_firebase()
    return db