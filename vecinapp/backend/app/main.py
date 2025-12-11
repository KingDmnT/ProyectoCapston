from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Importamos nuestros módulos locales
from app.core.firebase import initialize_firebase
from app.api import residents
from app.api import auth
from app.api import communities
from app.api import units
from app.api import users
from app.api import visits
from app.api import maintenance
from app.api import common_expense
from app.api import incidents
from app.api import reservations
from app.api import notifications

app = FastAPI(
    title="Condominio System API",
    description="API para gestión de administración de edificios",
    version="1.0.0"
)

# --- Configuración de CORS ---
# Permite la comunicación entre el frontend (Flutter Web) y este backend.
# En producción, se debe restringir 'origins' a los dominios específicos.

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permitir todas las origins en desarrollo
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

# Módulo de Usuarios
app.include_router(users.router, prefix="/users", tags=["Users"])

# Módulo de Visitas
app.include_router(visits.router, prefix="/visits", tags=["Visits"])

# Módulo de Autenticación
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# Módulo de Mantenimiento
app.include_router(maintenance.router, prefix="/maintenance", tags=["Maintenance"])

# Módulo de Gastos Comunes
app.include_router(common_expense.router, prefix="/common-expenses", tags=["Common Expenses"])

# Módulo de Incidentes
app.include_router(incidents.router, prefix="/incidents", tags=["Incidents"])

# Módulo de Reservas
app.include_router(reservations.router, prefix="/reservations", tags=["Reservations"])

# Módulo de Notificaciones
app.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])

# --- Health Check ---
@app.get("/")
async def root():
    return {
        "status": "ok", 
        "message": "Condominio System API funcionando correctamente",
        "docs_url": "http://localhost:8000/docs"
    }