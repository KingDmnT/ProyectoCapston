import requests
import os
import json
from dotenv import load_dotenv
from pathlib import Path

# Configurar rutas
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / '.env'

# Cargar variables de entorno
load_dotenv(dotenv_path=ENV_PATH)

# URL de la API REST de Firebase Auth
# Documentación: https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password
FIREBASE_AUTH_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"

def test_login(email, password, api_key):
    if not api_key:
        print("❌ Error: FIREBASE_WEB_API_KEY no encontrada.")
        print("Por favor, configura la variable de entorno FIREBASE_WEB_API_KEY en tu archivo .env")
        print("O pásala como argumento al script.")
        return None

    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    
    params = {
        "key": api_key
    }

    try:
        response = requests.post(FIREBASE_AUTH_URL, params=params, json=payload)
        response.raise_for_status() # Lanza excepción para códigos de error 4xx/5xx
        
        data = response.json()
        print(f"✅ Login exitoso para: {email}")
        print(f"   UID: {data['localId']}")
        print(f"   ID Token (truncado): {data['idToken'][:50]}...")
        return data['idToken']
        
    except requests.exceptions.HTTPError as e:
        print(f"❌ Error en login para {email}: {e}")
        try:
            error_details = response.json()
            print(f"   Detalle: {json.dumps(error_details, indent=2)}")
        except:
            print(f"   Respuesta: {response.text}")
        return None
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        return None

if __name__ == "__main__":
    print("--- Test de Login de Usuarios Seed ---")
    
    # Intentar obtener API Key de variable de entorno
    api_key = os.getenv("FIREBASE_WEB_API_KEY")
    
    if not api_key:
        api_key = input("Ingresa tu Firebase Web API Key: ").strip()
    
    if not api_key:
        print("No se proporcionó API Key. Saliendo.")
        exit(1)

    # Usuarios definidos en seed_auth.py
    users_to_test = [
        {
            "email": "caravenav1989@gmail.com",
            "password": "password123"
        },
        {
            "email": "carl.aravena@duocuc.cl",
            "password": "password123"
        }
    ]

    for user in users_to_test:
        print(f"\nProbando usuario: {user['email']}")
        test_login(user['email'], user['password'], api_key)
