from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Importamos nuestros módulos locales
from app.core.firebase import initialize_firebase
from app.api import residents
from app.api import auth
from app.api import communities
from app.api import units

app = FastAPI(
    title="Condominio System API",
    description="API para gestión de administración de edificios",
    version="1.0.0"
)

# --- Configuración de CORS ---
# Permite la comunicación entre el frontend (Flutter Web) y este backend.
# En producción, se debe restringir 'origins' a los dominios específicos.
origins = [
    "http://localhost",
    "http://localhost:3000", 
    "*"                      
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Inicialización ---
@app.on_event("startup")
async def startup_event():
    print("🚀 Iniciando servidor...")
    initialize_firebase()

# --- Rutas ---
# Módulo de Residentes
app.include_router(residents.router, prefix="/residents", tags=["Residents"])

# Módulo de Comunidades
app.include_router(communities.router, prefix="/communities", tags=["Communities"])

# Módulo de Unidades
app.include_router(units.router, prefix="/units", tags=["Units"])

# Módulo de Autenticación
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# --- Health Check ---
@app.get("/")
async def root():
    return {
        "status": "ok", 
        "message": "Condominio System API funcionando correctamente",
        "docs_url": "http://localhost:8000/docs"
    }