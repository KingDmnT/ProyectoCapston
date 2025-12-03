# 🏢 VecinApp - Plataforma de Gestión de Condominios

Bienvenido a **VecinApp**, la solución integral para la administración inteligente de comunidades y edificios. Este proyecto utiliza una arquitectura moderna basada en microservicios contenerizados, separando claramente la lógica de negocio de la interfaz de usuario.

## 🚀 Arquitectura del Proyecto

El sistema está compuesto por dos servicios principales que se ejecutan en contenedores Docker independientes, orquestados mediante Docker Compose:

| Servicio | Tecnología | Puerto | Descripción |
|----------|------------|--------|-------------|
| **Backend** | Python (FastAPI) | `8000` | API RESTful que maneja la lógica de negocio, autenticación y conexión con Firebase. |
| **Admin Web** | Flutter Web | `3000` | Panel de administración (Backoffice) para la gestión de residentes y comunidad. |

---

## 🛠️ Requisitos Previos

Asegúrate de tener instalado lo siguiente antes de comenzar:
*   [Docker Desktop](https://www.docker.com/products/docker-desktop/) (corriendo).
*   [Git](https://git-scm.com/).
*   Un proyecto de **Firebase** activo.

---

## ⚙️ Configuración de Entorno

Para que los contenedores funcionen correctamente, es necesario configurar las credenciales y variables de entorno en cada módulo.

### 1. Backend (`/vecinapp`)
El backend requiere acceso a las credenciales de servicio de Firebase para administrar usuarios y base de datos.

*   **Credenciales**: Coloca tu archivo `serviceAccountKey.json` descargado de Firebase en la carpeta:
    ```
    vecinapp/credentials/serviceAccountKey.json
    ```
    *El contenedor montará esta carpeta automáticamente.*

### 2. Admin Web (`/vecinapp/admin_web`)
El frontend necesita las credenciales públicas de Firebase para inicializar la app en el navegador.

1.  Navega a la carpeta del frontend:
    ```bash
    cd vecinapp/admin_web
    ```
2.  Crea un archivo `.env` (puedes copiar el ejemplo):
    ```bash
    cp .env.example .env
    ```
3.  Edita el archivo `.env` con tus datos de **Firebase Console -> Project Settings -> General -> Web App**:
    ```env
    FIREBASE_API_KEY=Tu_API_Key
    FIREBASE_APP_ID=Tu_App_ID
    FIREBASE_MESSAGING_SENDER_ID=Tu_Sender_ID
    FIREBASE_PROJECT_ID=Tu_Project_ID
    FIREBASE_AUTH_DOMAIN=Tu_Project_ID.firebaseapp.com
    FIREBASE_STORAGE_BUCKET=Tu_Project_ID.appspot.com
    BACKEND_URL=http://localhost:8000
    ```
    > **Nota**: Este archivo es necesario *antes* de construir la imagen Docker, ya que Flutter lo empaqueta durante el build.

---

## 🐳 Despliegue (Paso a Paso)

Una vez configurados los archivos anteriores, levantar la arquitectura es muy sencillo.

1.  Abre una terminal en la raíz del proyecto (`vecinapp/`).
2.  Ejecuta el comando de orquestación:
    ```bash
    docker-compose up --build
    ```
3.  Espera a que finalice la construcción de las imágenes. Verás logs indicando que los servicios están listos.

### Acceso a los Servicios
*   🖥️ **Admin Web**: Abre [http://localhost:3000](http://localhost:3000) en tu navegador.
*   ⚙️ **Backend API**: Accesible en [http://localhost:8000](http://localhost:8000).

---

## 📚 Documentación de API (Swagger UI)

El backend cuenta con documentación automática e interactiva generada con **Swagger/OpenAPI**. Esta herramienta es fundamental para entender y probar los endpoints disponibles sin escribir código.

Para acceder, asegúrate de que el backend esté corriendo y visita:

👉 **[http://localhost:8000/docs](http://localhost:8000/docs)**

### ¿Qué puedes hacer en Swagger?
*   **Explorar Endpoints**: Ver lista completa de rutas.
*   **Probar Peticiones**: Ejecutar `GET`, `POST`, etc. directamente desde el navegador (botón "Try it out").
*   **Ver Esquemas**: Consultar los modelos de datos (JSON) que espera y retorna cada servicio.
*   **Autenticación**: Usar el botón "Authorize" para probar endpoints protegidos (requiere Token Bearer).

---

## 🧪 Comandos Útiles

*   **Detener contenedores**: `Ctrl + C` en la terminal o `docker-compose down`.
*   **Reconstruir imágenes** (si cambiaste el `.env` o código): `docker-compose up --build`.
*   **Ver logs**: `docker-compose logs -f`.

---
*Proyecto Capstone - VecinApp*