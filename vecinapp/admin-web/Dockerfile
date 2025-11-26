# --- Etapa 1: Build de Flutter ---
# Usamos una imagen base de Linux para instalar Flutter
FROM ubuntu:20.04 AS build-env

# Instalar dependencias necesarias para Flutter
RUN apt-get update && \
    apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 python3 && \
    apt-get clean

# Clonar Flutter SDK (rama stable)
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Habilitar soporte web
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# Crear directorio de trabajo y copiar archivos del proyecto
WORKDIR /app
COPY . .

# Obtener dependencias y construir la versión web
RUN flutter pub get
RUN flutter build web --release

# --- Etapa 2: Servidor Nginx ---
# Usamos una imagen minúscula de Nginx para servir los archivos
FROM nginx:alpine

# Copiamos los archivos compilados de la etapa anterior (build-env) a la carpeta de Nginx
COPY --from=build-env /app/build/web /usr/share/nginx/html

# (Opcional) Copiar configuración personalizada de Nginx si se necesita
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]