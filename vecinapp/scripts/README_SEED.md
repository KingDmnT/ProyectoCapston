# Script de población de Firebase para VecinApp

## Descripción
Este script puebla Firebase con datos de prueba completos para el sistema VecinApp.

## Datos que crea:

### 👤 Usuarios (2)
1. **Administrador**
   - Email: `caravenav1989@gmail.com`
   - Password: `Admin123!`
   - Rol: `administrator`
   - Acceso: Ambas comunidades

2. **Residente**
   - Email: `residente@vecinapp.cl`
   - Password: `Residente123!`
   - Rol: `resident`
   - Comunidad: Edificio Las Condes
   - Unidad: 301

### 🏢 Comunidades (2)

1. **Edificio Las Condes**
   - Dirección: Av. Apoquindo 4500, Las Condes
   - 4 pisos
   - 6 departamentos por piso
   - Total: 24 unidades (101-106, 201-206, 301-306, 401-406)

2. **Condominio Conecta Huechuraba**
   - Dirección: Av. Pedro Fontova 5200, Huechuraba
   - 4 pisos
   - 6 departamentos por piso
   - Total: 24 unidades (101-106, 201-206, 301-306, 401-406)

## Cómo usar

### 1. Asegúrate de tener las credenciales de Firebase

El archivo `serviceAccountKey.json` debe estar en `vecinapp/credentials/`

### 2. Ejecuta el script

```bash
# Desde la carpeta vecinapp/scripts
python seed_data.py
```

### 3. Verifica en Firebase Console

- Ir a Firebase Console → Authentication → Users
- Ir a Firestore → Database **(default)** → Colecciones `users` y `communities`

> **Nota**: El script usa la base de datos **predeterminada (default)** de Firestore para compatibilidad con Flutter Web.

## Estructura de Firestore

### Colección: `users` (en base de datos default)
```
users/
  └── {uid}/
      ├── id: string (UID)
      ├── name: string
      ├── email: string
      ├── role: string ("administrator" | "resident")
      ├── photoUrl: string | null
      ├── communityId: string (ID de comunidad principal)
      ├── memberships: array
      │   └── {
      │       community_id: string,
      │       community_name: string,
      │       unit_id: string (solo para residentes),
      │       unit_number: string (solo para residentes),
      │       roles: array,
      │       start_date: timestamp,
      │       is_active: boolean
      │   }
      └── created_at: timestamp
```

### Colección: `communities` (en base de datos default)
```
communities/
  └── {community_id}/
      ├── id: string
      ├── name: string
      ├── address: string
      ├── comuna: string
      ├── region: string
      ├── is_active: boolean
      ├── created_at: timestamp
      └── units/ (subcollection)
          └── {unit_id}/
              ├── unit_number: string (101, 102, etc.)
              ├── floor: number
              ├── type: string ("apartment")
              ├── is_occupied: boolean
              ├── resident_uid: string (si está ocupada)
              ├── resident_name: string (si está ocupada)
              └── created_at: timestamp
```

## Notas

- El script es idempotente para usuarios (si ya existe, lo reutiliza)
- Las contraseñas cumplen con los requisitos de Firebase (mínimo 6 caracteres)
- El administrador tiene acceso a ambas comunidades
- El residente está asignado al departamento 301 del Edificio Las Condes
- **Importante**: Se usa la base de datos **(default)** de Firestore, no una base nombrada
