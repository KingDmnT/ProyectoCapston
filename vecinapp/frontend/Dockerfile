# Etapa 1: Construcción
# Flutter 3.24+ incluye Dart 3.5+ requerido por pubspec.yaml
FROM instrumentisto/flutter:3.24 AS build

WORKDIR /app

# Copiar archivos de configuración de dependencias
COPY pubspec.yaml ./

# Obtener dependencias
RUN flutter pub get

# Copiar el código fuente
COPY . .

# Construir la aplicación para web
# --release genera una build optimizada
RUN flutter build web --release

# Etapa 2: Servidor Web (Nginx)
FROM nginx:alpine

# Copiar los archivos construidos desde la etapa anterior
COPY --from=build /app/build/web /usr/share/nginx/html

# Exponer el puerto 80
EXPOSE 80

# Iniciar Nginx
CMD ["nginx", "-g", "daemon off;"]
