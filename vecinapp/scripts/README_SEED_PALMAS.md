# Seed Data - Condominio Las Palmas

Este script genera datos de prueba completos para la comunidad "Condominio Las Palmas" con un año completo de operaciones simuladas (Noviembre 2024 - Noviembre 2025).

## 📋 Datos Generados

### Comunidad
- **Nombre**: Condominio Las Palmas
- **Ubicación**: Av. Las Palmas 1234, Ñuñoa, Región Metropolitana
- **Total Unidades**: 89 (54 deptos + 20 estacionamientos + 15 bodegas)

### Unidades
- **54 Departamentos**: Distribuidos en 6 pisos (101-109, 201-209, ..., 601-609)
  - 18 departamentos de 45 m²
  - 18 departamentos de 55 m²
  - 18 departamentos de 65 m²
- **20 Estacionamientos**: E-01 a E-20 (piso -1)
- **15 Bodegas**: B-01 a B-15 (piso -2)

### Alícuotas
Las alícuotas están calculadas para sumar exactamente **100%** entre las 89 unidades:
- Departamentos: ~80% del total (distribuido según m²)
- Estacionamientos: ~15% del total
- Bodegas: ~5% del total

### Residentes
- **54 Residentes** (uno por cada departamento)
- **Distribución de unidades adicionales**:
  - ~70% tiene estacionamiento
  - ~50% tiene bodega
- Todos los residentes tienen **al menos 1 departamento**

### Datos Históricos

#### Mantenciones
Mantenciones recurrentes generadas para 13 meses (Nov 2024 - Nov 2025):
- Mantenimiento de Piscina (semanal) - $200.000/mes
- Mantenimiento de Jardines (semanal) - $450.000/mes
- Control de Plagas (mensual) - $180.000/mes
- Mantenimiento Ascensores (mensual) - $350.000/mes
- Limpieza Áreas Comunes (semanal) - $280.000/mes

**Estados**: Mantenciones pasadas mayormente completadas, futuras pendientes.

#### Gastos Comunes
13 períodos mensuales generados (Nov 2024 - Nov 2025):
- **Categorías**:
  - Remuneraciones (conserje, administrador)
  - Mantenciones (piscina, jardines, ascensores)
  - Servicios comunes (electricidad, agua)
  - Gastos extraordinarios (variables)
- **Estados**:
  - Nov 2024 - Oct 2025: NOTIFICADO (con pagos y morosidad)
  - Nov 2025: CERRADO (listo para notificar)
- **Morosidad**: ~15% de los residentes con pagos atrasados

## 🚀 Uso

### Requisitos Previos
1. Tener configurado el archivo `.env` con las credenciales de Firebase
2. Tener instaladas las dependencias de Python (ver `requirements.txt`)

### Ejecutar el Script

```powershell
# Desde la raíz del proyecto backend
cd c:\Repos\ProyectoCapston\vecinapp

# Ejecutar el script
python scripts/seed_data_palmas.py
```

### Importante
⚠️ **Este script NO elimina datos existentes**. Solo agrega la nueva comunidad "Condominio Las Palmas" sin afectar otras comunidades.

Si deseas limpiar todos los datos antes de ejecutar, puedes usar el script original `seed_data.py` que incluye la función `cleanup_data()`.

## 🔐 Credenciales

### Administrador
- **Email**: admin.palmas@vecinapp.cl
- **Password**: Admin123!

### Residentes
- **Password**: Test123! (para todos)
- **Ejemplos de emails**:
  - maria.gonzalez1@test.cl
  - juan.munoz2@test.cl
  - carla.rojas3@test.cl
  - (y así sucesivamente para los 54 residentes)

## 📊 Verificación

Después de ejecutar el script, verifica en Firebase Console:

1. **Communities**: Debe aparecer "Condominio Las Palmas"
2. **Units subcollection**: 89 unidades (54 deptos + 20 estac + 15 bodegas)
3. **Users**: 55 usuarios (1 admin + 54 residentes)
4. **Maintenances subcollection**: ~65 mantenciones
5. **Common_expenses subcollection**: 13 períodos

### Suma de Alícuotas
El script verifica automáticamente que las alícuotas sumen 100%. Busca en la salida del script:
```
✅ VERIFICACIÓN: Suma de alícuotas = 100.00%
```

### Morosidad
Aproximadamente 8 residentes (15% de 54) tendrán algunos períodos sin pagar. Esto simula morosidad realista en el sistema.

## 🎯 Características Especiales

1. **Asignación Realista**: No todos los residentes tienen estacionamiento o bodega
2. **Variedad de M²**: Los departamentos tienen 3 tamaños diferentes (45, 55, 65 m²)
3. **Alícuotas Proporcionales**: Los departamentos más grandes tienen mayor alícuota
4. **Historial Completo**: Un año completo de datos para pruebas
5. **Morosidad Simulada**: Casos reales de gastos comunes sin pagar
6. **Estados Variados**: Mantenciones completadas y pendientes, gastos notificados y cerrados
