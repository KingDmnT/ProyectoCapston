import os
from dotenv import load_dotenv
from pathlib import Path

# Cargamos variables de entorno
load_dotenv()

class Settings:
    PROJECT_NAME: str = "VecinAPP"
    
    # Calculamos la ruta raíz del proyecto (vecinapp)
    # backend/app/core/config.py -> .parent(core) -> .parent(app) -> .parent(backend) -> .parent(vecinapp)
    _project_root = Path(__file__).resolve().parent.parent.parent.parent
    
    # Ruta por defecto si no hay variable de entorno
    _local_cred_path = _project_root / "credentials" / "serviceAccountKey.json"
    _docker_cred_path = "/app/credentials/serviceAccountKey.json"

    # Obtenemos la variable de entorno solicitada
    _env_val = os.getenv("FIREBASE_SERVICE_ACCOUNT_KEY")

    if _env_val:
        # Si existe la variable, verificamos si es absoluta o relativa
        _path_obj = Path(_env_val)
        if not _path_obj.is_absolute():
            # Si es relativa (ej: "credentials/serviceAccountKey.json"), la unimos al root del proyecto
            # Quitamos barras iniciales por si acaso
            _clean_path = _env_val.lstrip('/\\')
            FIREBASE_CREDENTIALS_PATH = str(_project_root / _clean_path)
        else:
            FIREBASE_CREDENTIALS_PATH = _env_val
    else:
        # Fallback: Intentamos ruta local autodetectada, sino Docker
        FIREBASE_CREDENTIALS_PATH = str(_local_cred_path) if _local_cred_path.exists() else _docker_cred_path

settings = Settings()