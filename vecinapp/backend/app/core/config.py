import os
from dotenv import load_dotenv

# Cargamos variables de entorno
load_dotenv()

class Settings:
    PROJECT_NAME: str = "VecinAPP"
    # Ruta al archivo JSON de credenciales dentro del contenedor
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "/app/credentials/serviceAccountKey.json")

settings = Settings()