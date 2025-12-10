import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
from dotenv import load_dotenv
from pathlib import Path
from datetime import datetime, timedelta
import random

# --- Configuración ---
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / '.env'
load_dotenv(dotenv_path=ENV_PATH)

cred_path_env = os.getenv('FIREBASE_SERVICE_ACCOUNT_KEY', 'credentials/serviceAccountKey.json')
cred_path_env = cred_path_env.lstrip('/\\')
cred_path = BASE_DIR / cred_path_env

if not firebase_admin._apps:
    cred = credentials.Certificate(str(cred_path))
    firebase_admin.initialize_app(cred)
    print(f"✅ Firebase Admin inicializado con {cred_path}")

# Conectar a la base de datos predeterminada de Firestore
from google.cloud import firestore as google_firestore
db = google_firestore.Client(
    credentials=cred.get_credential(), 
    project=cred.project_id
)

def create_auth_user(email, password, display_name):
    """Crea un usuario en Firebase Auth"""
    try:
        user_auth = auth.create_user(
            email=email,
            password=password,
            display_name=display_name,
            email_verified=True
        )
        print(f"✅ Usuario Auth creado: {email}")
        return user_auth.uid
    except auth.EmailAlreadyExistsError:
        user_auth = auth.get_user_by_email(email)
        print(f"ℹ️  Usuario Auth ya existe: {email}")
        return user_auth.uid
    except Exception as e:
        print(f"❌ Error creando usuario {email}: {e}")
        return None

def create_user_profile(uid, first_name, last_name, email, role, rut, community_memberships):
    """Crea el perfil de usuario en Firestore"""
    user_ref = db.collection('users').document(uid)
    
    user_data = {
        "id": uid,
        "first_name": first_name,
        "last_name": last_name,
        "name": f"{first_name} {last_name}",
        "email": email,
        "role": role,
        "rut": rut,
        "photoUrl": None,
        "communityId": community_memberships[0]['community_id'] if community_memberships else None,
        "memberships": community_memberships,
        "is_active": True,
        "created_at": datetime.now()
    }
    
    user_ref.set(user_data, merge=True)
    return user_data

def calculate_alicuotas(total_units):
    """
    Calcula alícuotas para 89 unidades totales:
    - 54 departamentos: ~80% del total (distribuido por m2)
    - 20 estacionamientos: ~15% del total
    - 15 bodegas: ~5% del total
    """
    # Distribución de m2 para departamentos (54 total)
    # 18 deptos de 45m2, 18 de 55m2, 18 de 65m2
    dept_45m2_count = 18
    dept_55m2_count = 18
    dept_65m2_count = 18
    
    # Porcentajes base
    dept_total_percent = 80.0
    parking_total_percent = 15.0
    storage_total_percent = 5.0
    
    # Calcular alícuotas para departamentos según m2
    # Más m2 = mayor alícuota
    total_m2 = (dept_45m2_count * 45) + (dept_55m2_count * 55) + (dept_65m2_count * 65)
    
    alicuota_45m2 = round((45 / total_m2) * dept_total_percent, 4)
    alicuota_55m2 = round((55 / total_m2) * dept_total_percent, 4)
    alicuota_65m2 = round((65 / total_m2) * dept_total_percent, 4)
    
    # Calcular alícuotas para estacionamientos y bodegas
    alicuota_parking = round(parking_total_percent / 20, 4)
    alicuota_storage = round(storage_total_percent / 15, 4)
    
    # Ajustar para que sume exactamente 100%
    calculated_total = (dept_45m2_count * alicuota_45m2 + 
                       dept_55m2_count * alicuota_55m2 + 
                       dept_65m2_count * alicuota_65m2 + 
                       20 * alicuota_parking + 
                       15 * alicuota_storage)
    
    adjustment = (100.0 - calculated_total) / 54  # Ajustar en departamentos
    alicuota_45m2 += adjustment
    alicuota_55m2 += adjustment
    alicuota_65m2 += adjustment
    
    return {
        '45m2': round(alicuota_45m2, 4),
        '55m2': round(alicuota_55m2, 4),
        '65m2': round(alicuota_65m2, 4),
        'parking': round(alicuota_parking, 4),
        'storage': round(alicuota_storage, 4)
    }

def create_condominio_palmas():
    """Crea la comunidad Condominio Las Palmas con todas sus unidades"""
    print("\n" + "="*60)
    print("🌱 CREANDO CONDOMINIO LAS PALMAS")
    print("="*60 + "\n")
    
    # Crear comunidad
    community_ref = db.collection('communities').document()
    community_id = community_ref.id
    
    community_data = {
        "id": community_id,
        "name": "Condominio Las Palmas",
        "address": "Av. Las Palmas 1234",
        "comuna": "Ñuñoa",
        "region": "Metropolitana",
        "is_active": True,
        "created_at": datetime.now(),
        "bank_name": "Banco de Chile",
        "bank_account_type": "Cuenta Corriente",
        "bank_account_number": f"{random.randint(10000000, 99999999)}",
        "bank_account_rut": "76.123.456-7",
        "bank_account_email": "admin.palmas@vecinapp.cl",
    }
    community_ref.set(community_data)
    print(f"✅ Comunidad creada: Condominio Las Palmas (ID: {community_id})")
    
    # Calcular alícuotas
    alicuotas = calculate_alicuotas(89)
    print(f"\n📊 Alícuotas calculadas:")
    print(f"   - Depto 45m²: {alicuotas['45m2']}%")
    print(f"   - Depto 55m²: {alicuotas['55m2']}%")
    print(f"   - Depto 65m²: {alicuotas['65m2']}%")
    print(f"   - Estacionamiento: {alicuotas['parking']}%")
    print(f"   - Bodega: {alicuotas['storage']}%")
    
    # Distribuir m2 por unidad (patrón cíclico)
    m2_pattern = [45, 45, 55, 55, 65, 65, 45, 55, 65]  # 9 unidades por piso
    
    # Crear 54 departamentos (6 pisos x 9 unidades)
    print(f"\n🏢 Creando 54 departamentos...")
    departments = []
    dept_index = 0
    
    for floor in range(1, 7):  # Pisos 1-6
        for unit_num in range(1, 10):  # Unidades 01-09
            unit_code = f"{floor}{unit_num:02d}"
            m2 = m2_pattern[unit_num - 1]
            alicuota = alicuotas[f'{m2}m2']
            
            unit_data = {
                "name": unit_code,
                "floor": floor,
                "type": "Departamento",
                "status": "Disponible",
                "community_id": community_id,
                "alicuota": alicuota,
                "m2": float(m2),
                "description": f"Departamento {unit_code} - {m2}m²",
            }
            
            unit_ref = community_ref.collection('units').document()
            unit_data["id"] = unit_ref.id
            unit_ref.set(unit_data)
            
            departments.append({
                "id": unit_ref.id,
                "name": unit_code,
                "floor": floor,
                "m2": m2,
                "alicuota": alicuota
            })
            dept_index += 1
    
    print(f"   ✓ {len(departments)} departamentos creados")
    
    # Crear 20 estacionamientos
    print(f"\n🚗 Creando 20 estacionamientos...")
    parkings = []
    
    for i in range(1, 21):
        parking_code = f"E-{i:02d}"
        
        parking_data = {
            "name": parking_code,
            "floor": -1,  # Subterráneo
            "type": "Estacionamiento",
            "status": "Disponible",
            "community_id": community_id,
            "alicuota": alicuotas['parking'],
            "m2": 12.0,
            "description": f"Estacionamiento {parking_code}",
        }
        
        parking_ref = community_ref.collection('units').document()
        parking_data["id"] = parking_ref.id
        parking_ref.set(parking_data)
        
        parkings.append({
            "id": parking_ref.id,
            "name": parking_code,
            "alicuota": alicuotas['parking']
        })
    
    print(f"   ✓ {len(parkings)} estacionamientos creados")
    
    # Crear 15 bodegas
    print(f"\n📦 Creando 15 bodegas...")
    storages = []
    
    for i in range(1, 16):
        storage_code = f"B-{i:02d}"
        
        storage_data = {
            "name": storage_code,
            "floor": -2,  # Subterráneo nivel -2
            "type": "Bodega",
            "status": "Disponible",
            "community_id": community_id,
            "alicuota": alicuotas['storage'],
            "m2": 6.0,
            "description": f"Bodega {storage_code}",
        }
        
        storage_ref = community_ref.collection('units').document()
        storage_data["id"] = storage_ref.id
        storage_ref.set(storage_data)
        
        storages.append({
            "id": storage_ref.id,
            "name": storage_code,
            "alicuota": alicuotas['storage']
        })
    
    print(f"   ✓ {len(storages)} bodegas creadas")
    
    # Verificar suma de alícuotas
    total_alicuota = sum(d['alicuota'] for d in departments) + \
                    sum(p['alicuota'] for p in parkings) + \
                    sum(s['alicuota'] for s in storages)
    print(f"\n✅ VERIFICACIÓN: Suma de alícuotas = {total_alicuota:.2f}%")
    
    return community_id, community_data, departments, parkings, storages

def create_residents_and_assignments(community_id, community_name, departments, parkings, storages):
    """Crea 54 residentes y los asigna a unidades"""
    print(f"\n👥 Creando 54 residentes y asignaciones...\n")
    
    # Nombres y apellidos chilenos
    first_names = [
        "María", "Juan", "Carla", "Pedro", "Sofía", "Diego", "Valentina", "Matías",
        "Francisca", "Sebastián", "Catalina", "Felipe", "Javiera", "Cristóbal", "Isidora",
        "Benjamín", "Antonia", "Martín", "Daniela", "Tomás", "Amanda", "Lucas",
        "Carolina", "Andrés", "Fernanda", "Roberto", "Camila", "Ricardo", "Paulina",
        "Gabriel", "Lorena", "Rodrigo", "Patricia", "Eduardo", "Claudia", "Jorge",
        "Mónica", "Raúl", "Teresa", "Sergio", "Verónica", "Marcelo", "Andrea",
        "Fernando", "Nicole", "Claudio", "Paola", "Álvaro", "Constanza", "Ignacio",
        "Bárbara", "Manuel", "Soledad", "Alberto"
    ]
    
    last_names = [
        "González", "Muñoz", "Rojas", "Silva", "Pérez", "Torres", "Flores", "Rivera",
        "Vargas", "Castro", "Soto", "Morales", "Campos", "Ortiz", "Núñez", "Ramírez",
        "Herrera", "Medina", "Aguilar", "Gutiérrez", "Vásquez", "Contreras", "Reyes",
        "Sepúlveda", "Espinoza", "Vera", "Díaz", "Pizarro", "Valdés", "Lagos",
        "Araya", "Bravo", "Molina", "Carrasco", "Bustos", "Sandoval", "Navarro",
        "Fuentes", "Cortés", "Paredes", "Riquelme", "Jara", "Alarcón", "Tapia",
        "Miranda", "Saavedra", "Figueroa", "Vega", "Cárdenas", "Santana", "Parra",
        "Cáceres", "Henríquez", "Vergara"
    ]
    
    # Mezclar estacionamientos y bodegas disponibles
    available_parkings = parkings.copy()
    available_storages = storages.copy()
    random.shuffle(available_parkings)
    random.shuffle(available_storages)
    
    residents_data = []
    rut_base = 18000000
    
    for i, dept in enumerate(departments):
        first_name = first_names[i % len(first_names)]
        last_name = last_names[i % len(last_names)]
        email = f"{first_name.lower()}.{last_name.lower()}{i+1}@test.cl"
        
        # Crear usuario en Auth
        resident_uid = create_auth_user(
            email=email,
            password="Test123!",
            display_name=f"{first_name} {last_name}"
        )
        
        if not resident_uid:
            continue
        
        # Memberships: siempre 1 depto
        memberships = [{
            "community_id": community_id,
            "community_name": community_name,
            "unit_id": dept['id'],
            "unit_number": dept['name'],
            "roles": ["resident"],
            "start_date": datetime.now(),
            "is_active": True
        }]
        
        assigned_units = [dept['name']]
        
        # 70% tiene estacionamiento
        has_parking = random.random() < 0.70
        parking_unit = None
        if has_parking and available_parkings:
            parking_unit = available_parkings.pop(0)
            memberships.append({
                "community_id": community_id,
                "community_name": community_name,
                "unit_id": parking_unit['id'],
                "unit_number": parking_unit['name'],
                "roles": ["resident"],
                "start_date": datetime.now(),
                "is_active": True
            })
            assigned_units.append(parking_unit['name'])
        
        # 50% tiene bodega
        has_storage = random.random() < 0.50
        storage_unit = None
        if has_storage and available_storages:
            storage_unit = available_storages.pop(0)
            memberships.append({
                "community_id": community_id,
                "community_name": community_name,
                "unit_id": storage_unit['id'],
                "unit_number": storage_unit['name'],
                "roles": ["resident"],
                "start_date": datetime.now(),
                "is_active": True
            })
            assigned_units.append(storage_unit['name'])
        
        # Crear perfil en Firestore
        create_user_profile(
            uid=resident_uid,
            first_name=first_name,
            last_name=last_name,
            email=email,
            role="resident",
            rut=f"{rut_base + i}-{random.randint(0, 9)}",
            community_memberships=memberships
        )
        
        # Actualizar estado de las unidades asignadas
        for membership in memberships:
            unit_ref = db.collection('communities').document(community_id)\
                        .collection('units').document(membership['unit_id'])
            unit_ref.update({
                'status': 'Asignado',
                'is_occupied': True,
                'resident_uid': resident_uid,
                'resident_name': f"{first_name} {last_name}",
                'updated_at': datetime.now()
            })
        
        residents_data.append({
            'uid': resident_uid,
            'name': f"{first_name} {last_name}",
            'email': email,
            'units': assigned_units
        })
        
        units_str = ', '.join(assigned_units)
        print(f"✅ {first_name} {last_name} - Unidades: {units_str}")
    
    print(f"\n✅ {len(residents_data)} residentes creados y asignados")
    return residents_data

def create_maintenances_year(community_id, community_name):
    """Crea mantenciones para un año (Nov 2024 - Nov 2025)"""
    print(f"\n🔧 Creando mantenciones para el año...\n")
    
    start_date = datetime(2024, 11, 1)
    
    # Mantenciones recurrentes
    maintenance_types = [
        {
            "title": "Mantenimiento de Piscina",
            "description": "Mantenimiento preventivo semanal de la piscina comunitaria",
            "type": "preventivo",
            "frequency": "semanal",
            "provider_name": "Servicios Acuáticos Ltda",
            "provider_contact": "+56912345678",
            "cost": 200000,
            "checklist": [
                {"title": "Limpieza de filtros", "is_completed": False},
                {"title": "Control de pH del agua", "is_completed": False},
                {"title": "Aspirado del fondo", "is_completed": False},
            ]
        },
        {
            "title": "Mantenimiento de Jardines",
            "description": "Mantenimiento de áreas verdes 2 veces por semana",
            "type": "preventivo",
            "frequency": "semanal",
            "provider_name": "Jardines del Sur SpA",
            "provider_contact": "+56987654321",
            "cost": 450000,
            "checklist": [
                {"title": "Corte de césped", "is_completed": False},
                {"title": "Riego de áreas verdes", "is_completed": False},
                {"title": "Poda de arbustos", "is_completed": False},
            ]
        },
        {
            "title": "Control de Plagas",
            "description": "Servicio preventivo mensual de control de plagas",
            "type": "preventivo",
            "frequency": "mensual",
            "provider_name": "Fumigaciones Express Ltda",
            "provider_contact": "+56923456789",
            "cost": 180000,
            "checklist": [
                {"title": "Fumigación áreas comunes", "is_completed": False},
                {"title": "Control de roedores", "is_completed": False},
            ]
        },
        {
            "title": "Mantenimiento Ascensores",
            "description": "Revisión técnica mensual de ascensores",
            "type": "preventivo",
            "frequency": "mensual",
            "provider_name": "Elevadores y Ascensores S.A.",
            "provider_contact": "+56934567890",
            "cost": 350000,
            "checklist": [
                {"title": "Revisión mecánica", "is_completed": False},
                {"title": "Lubricación de cables", "is_completed": False},
                {"title": "Prueba de seguridad", "is_completed": False},
            ]
        },
        {
            "title": "Limpieza Áreas Comunes",
            "description": "Limpieza profunda de espacios comunes",
            "type": "preventivo",
            "frequency": "semanal",
            "provider_name": "Limpiezas Integrales Ltda",
            "provider_contact": "+56945678901",
            "cost": 280000,
            "checklist": [
                {"title": "Limpieza de halls", "is_completed": False},
                {"title": "Limpieza de escaleras", "is_completed": False},
            ]
        }
    ]
    
    # Generar mantenciones para 13 meses (Nov 2024 - Nov 2025)
    count = 0
    for month_offset in range(13):
        current_date = start_date + timedelta(days=30 * month_offset)
        
        for maint_type in maintenance_types:
            # Determinar estado basado en la fecha
            if current_date < datetime.now():
                status = random.choice(["completado", "completado", "completado", "pendiente"])
                completed_date = current_date + timedelta(days=random.randint(1, 15)) if status == "completado" else None
            else:
                status = "pendiente"
                completed_date = None
            
            maintenance_data = {
                "title": maint_type["title"],
                "description": maint_type["description"],
                "type": maint_type["type"],
                "frequency": maint_type["frequency"],
                "provider_name": maint_type["provider_name"],
                "provider_contact": maint_type["provider_contact"],
                "cost": maint_type["cost"],
                "scheduled_date": current_date,
                "completed_date": completed_date,
                "status": status,
                "assigned_to": None,
                "approved_by": None,
                "approval_date": None,
                "notes": f"Mantenimiento {maint_type['frequency']} - {current_date.strftime('%B %Y')}",
                "checklist_items": maint_type["checklist"],
                "community_id": community_id,
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
            }
            
            maint_ref = db.collection('communities').document(community_id)\
                          .collection('maintenances').document()
            maintenance_data['id'] = maint_ref.id
            maint_ref.set(maintenance_data)
            count += 1
    
    print(f"✅ {count} mantenciones creadas para 13 meses")
    return count

def create_common_expenses_year(community_id, community_name, admin_uid, residents_data):
    """Crea gastos comunes para un año con morosidad del 15%"""
    print(f"\n💰 Creando gastos comunes para el año...\n")
    
    month_names = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                   'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre']
    
    # Generar para Nov 2024 - Nov 2025 (13 períodos)
    start_year = 2024
    start_month = 11
    
    # Seleccionar residentes morosos (15% de 54 = ~8 residentes)
    num_defaulters = int(len(residents_data) * 0.15)
    defaulters = random.sample(residents_data, num_defaulters)
    defaulter_uids = {d['uid'] for d in defaulters}
    
    print(f"📊 {num_defaulters} residentes con morosidad simulada\n")
    
    for month_offset in range(13):
        # Calcular año y mes
        total_months = start_month + month_offset
        year = start_year + (total_months - 1) // 12
        month = ((total_months - 1) % 12) + 1
        
        period = f"{year}-{month:02d}"
        period_display = f"{month_names[month-1]} {year}"
        
        # Items de gasto
        items = {
            'remuneraciones': [
                {
                    'description': 'Sueldo Conserje',
                    'amount': 600000,
                    'doc_number': f'{random.randint(10000, 99999)}',
                    'date': datetime(year, month, 5).isoformat(),
                },
                {
                    'description': 'Honorarios Administrador',
                    'amount': 400000,
                    'doc_number': f'{random.randint(10000, 99999)}',
                    'date': datetime(year, month, 5).isoformat(),
                },
            ],
            'gastos_extraordinarios': [
                {
                    'description': 'Reparación sistema eléctrico',
                    'amount': random.choice([0, 0, 0, 150000, 200000]),  # Solo algunos meses
                    'doc_number': f'{random.randint(10000, 99999)}' if random.random() > 0.7 else None,
                    'date': datetime(year, month, 15).isoformat() if random.random() > 0.7 else None,
                },
            ],
            'mantencion': [
                {
                    'description': f'Mantenimiento Piscina {period_display}',
                    'amount': 200000,
                    'doc_number': None,
                    'date': None,
                    'maintenance_ids': [],
                },
                {
                    'description': f'Mantenimiento Jardines {period_display}',
                    'amount': 450000,
                    'doc_number': None,
                    'date': None,
                    'maintenance_ids': [],
                },
                {
                    'description': f'Mantenimiento Ascensores {period_display}',
                    'amount': 350000,
                    'doc_number': None,
                    'date': None,
                    'maintenance_ids': [],
                },
            ],
            'servicios_comunes': [
                {
                    'description': 'Electricidad Áreas Comunes',
                    'amount': random.randint(180000, 250000),
                    'doc_number': f'{random.randint(50000, 59999)}',
                    'date': datetime(year, month, 20).isoformat(),
                },
                {
                    'description': 'Agua Potable',
                    'amount': random.randint(120000, 180000),
                    'doc_number': f'{random.randint(60000, 69999)}',
                    'date': datetime(year, month, 20).isoformat(),
                },
            ],
        }
        
        # Calcular total
        total_amount = sum(
            sum(item['amount'] for item in category_items)
            for category_items in items.values()
        )
        
        # Determinar estado según fecha
        expense_date = datetime(year, month, 1)
        if expense_date < datetime(2025, 11, 1):
            status = 'notified'  # Períodos pasados ya notificados
        elif expense_date.month == 11 and expense_date.year == 2025:
            status = 'closed'  # Noviembre 2025 cerrado pero no notificado
        else:
            status = 'draft'
        
        # Obtener unidades de la comunidad
        units_ref = db.collection('communities').document(community_id).collection('units')
        units_docs = list(units_ref.stream())
        
        # Calcular unit_expenses si está cerrado o notificado
        unit_expenses = []
        if status in ['closed', 'notified']:
            for unit_doc in units_docs:
                unit_data = unit_doc.to_dict()
                unit_id = unit_doc.id
                unit_name = unit_data.get('name', '')
                alicuota = unit_data.get('alicuota', 0.0)
                resident_uid = unit_data.get('resident_uid')
                resident_name = unit_data.get('resident_name')
                
                # Solo crear expense para unidades con residente
                if not resident_uid:
                    continue
                
                # Calcular monto
                unit_amount = total_amount * (alicuota / 100.0)
                
                # Determinar si está pagado (morosos tienen algunos períodos sin pagar)
                is_paid = True
                payment_date = None
                
                if resident_uid in defaulter_uids:
                    # Morosos: 30% de probabilidad de no pagar cada mes
                    is_paid = random.random() > 0.30
                
                if is_paid and status == 'notified':
                    # Pagado entre 1-25 días después del cierre
                    payment_date = expense_date + timedelta(days=random.randint(1, 25))
                
                # Buscar email del residente
                resident_email = None
                for res in residents_data:
                    if res['uid'] == resident_uid:
                        resident_email = res['email']
                        break
                
                unit_expenses.append({
                    'unit_id': unit_id,
                    'unit_name': unit_name,
                    'alicuota': alicuota,
                    'amount': unit_amount,
                    'resident_uid': resident_uid,
                    'resident_name': resident_name,
                    'resident_email': resident_email,
                    'pdf_url': None,
                    'is_paid': is_paid,
                    'payment_date': payment_date.isoformat() if payment_date else None,
                    'payment_method': random.choice(['transferencia', 'efectivo']) if is_paid else None,
                })
        
        # Crear documento
        expense_data = {
            'community_id': community_id,
            'period': period,
            'month': month,
            'year': year,
            'status': status,
            'total_amount': total_amount,
            'items': items,
            'unit_expenses': unit_expenses,
            'closed_by': admin_uid if status in ['closed', 'notified'] else None,
            'closed_at': expense_date if status in ['closed', 'notified'] else None,
            'created_by': admin_uid,
            'created_at': datetime.now(),
            'updated_at': datetime.now(),
        }
        
        expense_ref = db.collection('communities').document(community_id)\
                        .collection('common_expenses').document()
        expense_data['id'] = expense_ref.id
        expense_ref.set(expense_data)
        
        status_label = {'draft': 'BORRADOR', 'closed': 'CERRADO', 'notified': 'NOTIFICADO'}[status]
        
        # Calcular tasa de pago si está notificado
        payment_info = ""
        if status == 'notified' and unit_expenses:
            paid_count = sum(1 for ue in unit_expenses if ue.get('is_paid', False))
            total_count = len(unit_expenses)
            payment_rate = (paid_count / total_count) * 100 if total_count > 0 else 0
            payment_info = f" - Pagado: {paid_count}/{total_count} ({payment_rate:.0f}%)"
        
        print(f"✓ {period_display}: ${total_amount:,.0f} [{status_label}]{payment_info}")
    
    print(f"\n✅ 13 períodos de gastos comunes creados")

def seed_condominio_palmas():
    """Función principal para poblar Condominio Las Palmas"""
    print("\n" + "="*70)
    print("🏢 SEED DATA - CONDOMINIO LAS PALMAS")
    print("="*70)
    
    # 1. Crear comunidad y unidades
    community_id, community_data, departments, parkings, storages = create_condominio_palmas()
    
    # 2. Crear administrador
    print(f"\n👨‍💼 Creando administrador...")
    admin_uid = create_auth_user(
        email="admin.palmas@vecinapp.cl",
        password="Admin123!",
        display_name="Administrador Las Palmas"
    )
    
    if admin_uid:
        admin_memberships = [{
            "community_id": community_id,
            "community_name": community_data['name'],
            "roles": ["administrator"],
            "start_date": datetime.now(),
            "is_active": True
        }]
        
        create_user_profile(
            uid=admin_uid,
            first_name="Administrador",
            last_name="Las Palmas",
            email="admin.palmas@vecinapp.cl",
            role="administrator",
            rut="12345678-9",
            community_memberships=admin_memberships
        )
        print("✅ Administrador creado")
    
    # 3. Crear residentes y asignaciones
    residents_data = create_residents_and_assignments(
        community_id, 
        community_data['name'], 
        departments, 
        parkings, 
        storages
    )
    
    # 4. Crear mantenciones para el año
    create_maintenances_year(community_id, community_data['name'])
    
    # 5. Crear gastos comunes con morosidad
    create_common_expenses_year(community_id, community_data['name'], admin_uid, residents_data)
    
    print("\n" + "="*70)
    print("🎉 ¡SEED COMPLETADO!")
    print("="*70)
    print("\n📊 RESUMEN:")
    print(f"   - Comunidad: {community_data['name']}")
    print(f"   - Departamentos: 54 (6 pisos × 9 unidades)")
    print(f"   - Estacionamientos: 20")
    print(f"   - Bodegas: 15")
    print(f"   - Total unidades: 89")
    print(f"   - Residentes: 54")
    print(f"   - Administrador: 1")
    print(f"   - Mantenciones: 13 meses de datos")
    print(f"   - Gastos comunes: 13 períodos (Nov 2024 - Nov 2025)")
    print(f"   - Morosidad: ~15%")
    
    print("\n🔐 CREDENCIALES:")
    print(f"   👨‍💼 ADMINISTRADOR:")
    print(f"      Email: admin.palmas@vecinapp.cl")
    print(f"      Password: Admin123!")
    print(f"\n   👤 RESIDENTES:")
    print(f"      Password: Test123!")
    print(f"      Ejemplos: maria.gonzalez1@test.cl, juan.munoz2@test.cl")
    print("\n" + "="*70 + "\n")

if __name__ == "__main__":
    seed_condominio_palmas()
