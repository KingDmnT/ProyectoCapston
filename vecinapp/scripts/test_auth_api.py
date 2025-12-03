import requests
import os
from dotenv import load_dotenv
from pathlib import Path

# Configurar rutas
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / '.env'
load_dotenv(dotenv_path=ENV_PATH)

API_KEY = os.getenv("FIREBASE_WEB_API_KEY")
AUTH_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
BACKEND_URL = "http://localhost:8000"

def get_id_token(email, password):
    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    response = requests.post(AUTH_URL, json=payload)
    if response.status_code == 200:
        return response.json()['idToken']
    else:
        print(f"Error login: {response.text}")
        return None

def test_protected_endpoint(token):
    headers = {
        "Authorization": f"Bearer {token}"
    }
    # Probamos el endpoint /auth/me que acabamos de crear
    response = requests.get(f"{BACKEND_URL}/auth/me", headers=headers)
    
    print(f"\nStatus Code: {response.status_code}")
    if response.status_code == 200:
        print("✅ Acceso autorizado!")
        print("Respuesta del backend:", response.json())
    else:
        print("❌ Acceso denegado:", response.text)

if __name__ == "__main__":
    print("--- Test de Integración Auth Backend ---")
    
    # 1. Obtener token (Login)
    email = "caravenav1989@gmail.com"
    password = "password123"
    print(f"Logueando usuario {email}...")
    token = get_id_token(email, password)
    
    if token:
        # 2. Usar token en Backend
        print("\nProbando endpoint protegido en FastAPI...")
        try:
            test_protected_endpoint(token)
        except requests.exceptions.ConnectionError:
            print("❌ No se pudo conectar al backend. Asegúrate de que esté corriendo (uvicorn app.main:app --reload)")
