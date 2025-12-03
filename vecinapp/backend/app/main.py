from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Importamos nuestros módulos locales
from app.core.firebase import initialize_firebase
from app.api import residents
from app.api import auth

app = FastAPI(
    title="Condominio System API",
    description="API para gestión de administración de edificios",
    version="1.0.0"
)

# --- CONFIGURACIÓN CORS (CRÍTICO) ---
# Esto permite que tu Flutter Web (puerto 3000) pueda hablar con este Backend (puerto 8000)
# Si no configuras esto, el navegador bloqueará las peticiones.
origins = [
    "http://localhost",
    "http://localhost:3000", # Puerto del Docker del backoffice
    "*"                      # Permitir todo (útil para desarrollo rápido)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Eventos de Ciclo de Vida ---
# Este evento se dispara automáticamente cuando FastAPI inicia.
# Aquí conectamos con Firebase usando las credenciales.
@app.on_event("startup")
async def startup_event():
    print("🚀 Iniciando servidor...")
    initialize_firebase()

# --- Registro de Rutas (Routers) ---
# Aquí "pegamos" las rutas de los residentes a la app principal.
# Todas las rutas definidas en residents.py tendrán el prefijo /residents
app.include_router(residents.router, prefix="/residents", tags=["Residents"])

# Importamos y registramos el router de autenticación
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# --- Endpoint de prueba (Health Check) ---
@app.get("/")
async def root():
    return {
        "status": "ok", 
        "message": "Condominio System API funcionando correctamente",
        "docs_url": "http://localhost:8000/docs"
    }