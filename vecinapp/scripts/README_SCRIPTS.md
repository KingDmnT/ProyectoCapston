# Scripts de Base de Datos

Este directorio contiene scripts para gestionar los datos de prueba en Firebase.

## 📋 Scripts Disponibles

### 1. `cleanup_database.py` - Limpieza Completa ⚠️
**Propósito**: Elimina TODOS los datos de Firebase (Auth + Firestore)

**Uso**:
```bash
python scripts/cleanup_database.py
```

**Importante**:
- ⚠️ Este script es **DESTRUCTIVO** - elimina TODO
- Requiere confirmación manual (escribir 'SI')
- Elimina:
  - Todos los usuarios de Authentication
  - Todas las comunidades y subcollections
  - Todos los perfiles de usuario
  - Todas las mantenciones
  - Todos los gastos comunes

### 2. `seed_data.py` - Datos Originales
**Propósito**: Genera datos de prueba para las comunidades originales

**Contenido**:
- 2 comunidades: "Edificio Las Condes" y "Condominio Conecta Huechuraba"
- 3 administradores (1 super admin + 2 admins de comunidad)
- 10 residentes (5 por comunidad)
- Mantenciones básicas
- Gastos comunes de ejemplo

**Características**:
- ⚠️ Incluye función `cleanup_data()` que limpia antes de poblar
- Auto-ejecuta la limpieza al inicio

**Uso**:
```bash
python scripts/seed_data.py
```

### 3. `seed_data_palmas.py` - Condominio Las Palmas
**Propósito**: Genera datos completos para "Condominio Las Palmas"

**Contenido**:
- 1 comunidad: "Condominio Las Palmas"
- 1 administrador
- 54 departamentos (6 pisos × 9 unidades)
- 20 estacionamientos
- 15 bodegas
- 54 residentes
- 13 meses de mantenciones (Nov 2024 - Nov 2025)
- 13 períodos de gastos comunes con 15% morosidad

**Características**:
- ✅ NO limpia datos existentes
- Se puede ejecutar junto con otros seeds
- Datos históricos completos para pruebas

**Uso**:
```bash
python scripts/seed_data_palmas.py
```

## 🔄 Flujos de Trabajo Recomendados

### Opción A: Base Limpia + Datos Originales
```bash
# 1. Limpiar base de datos
python scripts/cleanup_database.py
# Confirmar con 'SI'

# 2. Cargar datos originales
python scripts/seed_data.py
```

### Opción B: Base Limpia + Solo Condominio Las Palmas
```bash
# 1. Limpiar base de datos
python scripts/cleanup_database.py
# Confirmar con 'SI'

# 2. Cargar datos de Las Palmas
python scripts/seed_data_palmas.py
```

### Opción C: Base Limpia + Ambos Datasets
```bash
# 1. Limpiar base de datos
python scripts/cleanup_database.py
# Confirmar con 'SI'

# 2. Cargar datos originales (sin cleanup interno)
# Modificar seed_data.py para comentar cleanup_data()
python scripts/seed_data.py

# 3. Agregar datos de Las Palmas
python scripts/seed_data_palmas.py
```

### Opción D: Agregar Las Palmas a Datos Existentes
```bash
# Solo ejecutar (SIN limpiar primero)
python scripts/seed_data_palmas.py
```

## 🐳 Ejecución en Docker

Si estás usando Docker, debes ejecutar los scripts dentro del contenedor:

```bash
# 1. Copiar script al contenedor (si no está montado)
docker cp scripts/cleanup_database.py vecinapp_backend:/app/../scripts/

# 2. Ejecutar dentro del contenedor
docker-compose exec backend python /app/../scripts/cleanup_database.py
docker-compose exec backend python /app/../scripts/seed_data_palmas.py
```

**O con modo interactivo** para confirmar la limpieza:
```bash
docker-compose exec backend python -u /app/../scripts/cleanup_database.py
```

## ⚠️ Advertencias Importantes

1. **No ejecutar `seed_data.py` sin modificar si ya tienes datos**
   - Este script incluye `cleanup_data()` que borra todo
   - Comentar la línea `cleanup_data()` si quieres preservar datos existentes

2. **`seed_data_palmas.py` es aditivo**
   - Solo agrega la comunidad "Condominio Las Palmas"
   - NO borra datos existentes
   - Se puede ejecutar múltiples veces (duplicará datos)

3. **`cleanup_database.py` es destructivo**
   - Requiere confirmación manual
   - Borra TODO sin posibilidad de deshacer
   - Solo usar cuando quieras empezar de cero

## 📝 Credenciales Generadas

### seed_data.py
```
Super Admin:
  Email: admin@vecinapp.cl
  Password: Admin123!

Admins:
  admin.lascondes@vecinapp.cl / Admin123!
  admin.huechuraba@vecinapp.cl / Admin123!

Residentes:
  Password: Test123!
  Ejemplos: ana.torres@test.cl, juan.lopez@test.cl
```

### seed_data_palmas.py
```
Administrador:
  Email: admin.palmas@vecinapp.cl
  Password: Admin123!

Residentes:
  Password: Test123!
  Ejemplos: maria.gonzalez1@test.cl, juan.munoz2@test.cl
```

## 🔍 Verificación

Después de ejecutar cualquier script, verifica en Firebase Console:
- Authentication: usuarios creados
- Firestore: colecciones `users` y `communities`
- Subcollections: `units`, `maintenances`, `common_expenses`

## 📚 Documentación Adicional

- [README_SEED.md](./README_SEED.md) - Documentación del seed original
- [README_SEED_PALMAS.md](./README_SEED_PALMAS.md) - Documentación detallada de Las Palmas
