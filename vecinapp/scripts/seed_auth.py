import firebase_admin
from firebase_admin import credentials
from firebase_admin import auth
import os
from dotenv import load_dotenv
from pathlib import Path

# Configurar rutas
# BASE_DIR apunta a la carpeta raíz 'vecinapp'
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / '.env'

# Cargar variables de entorno
load_dotenv(dotenv_path=ENV_PATH)

# Obtener ruta de credenciales
# Por defecto busca en credentials/serviceAccountKey.json
cred_path_env = os.getenv('FIREBASE_SERVICE_ACCOUNT_KEY', 'credentials/serviceAccountKey.json')

# Aseguramos que la ruta sea relativa quitando barras iniciales para que funcione con pathlib
cred_path_env = cred_path_env.lstrip('/\\')

cred_path = BASE_DIR / cred_path_env

if not firebase_admin._apps:
    try:
        # Convertir a string para firebase_admin
        cred = credentials.Certificate(str(cred_path))
        firebase_admin.initialize_app(cred)
        print(f"Firebase Admin inicializado con {cred_path}")
    except Exception as e:
        print(f"Error inicializando Firebase Admin: {e}")
        print(f"Ruta intentada: {cred_path}")
        print("Asegúrate de que 'serviceAccountKey.json' esté en la carpeta 'credentials' de 'vecinapp' o configura FIREBASE_SERVICE_ACCOUNT_KEY correctamente en .env")
        exit(1)

def create_user(email, password, phone_number=None, display_name=None):
    try:
        user = auth.create_user(
            email=email,
            email_verified=False,
            password=password,
            display_name=display_name,
            phone_number=phone_number,
            disabled=False
        )
        print(f"Successfully created user: {user.uid} ({email})")
        return user.uid
    except auth.EmailAlreadyExistsError:
        print(f"User with email {email} already exists.")
        # Optional: Get the existing user
        user = auth.get_user_by_email(email)
        return user.uid
    except Exception as e:
        print(f"Error creating user {email}: {e}")
        return None

def seed_users():
    print("Starting user seeding...")
    
    # Example users to seed
    users_to_seed = [
        {
            "email": "caravenav1989@gmail.com",
            "password": "password123",
            "display_name": "Admin User",
            "phone_number": "+56982182455" 
        },
        {
            "email": "carl.aravena@duocuc.cl",
            "password": "password123",
            "display_name": "Vecino User",
            "phone_number": "+56982182456"
        }
    ]

    for user_data in users_to_seed:
        create_user(
            email=user_data["email"],
            password=user_data["password"],
            display_name=user_data.get("display_name"),
            phone_number=user_data.get("phone_number")
        )

    print("User seeding completed.")

if __name__ == "__main__":
    seed_users()
