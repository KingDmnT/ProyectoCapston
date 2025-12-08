# Etapa 1: Construcción
FROM python:3.12-slim

# Establecer directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema (si son necesarias)
# RUN apt-get update && apt-get install -y gcc

# Copiar archivos de dependencias
COPY requirements.txt .

# Instalar dependencias de Python
# Agregamos --no-cache-dir para mantener la imagen ligera
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY . .

# Exponer el puerto
EXPOSE 8000

# Comando para ejecutar la aplicación
# Usamos --host 0.0.0.0 para que sea accesible desde fuera del contenedor
# --reload para desarrollo (hot-reload automático)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]