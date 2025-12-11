import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
from dotenv import load_dotenv
from pathlib import Path
from datetime import datetime
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

# === FUNCIÓN DE LIMPIEZA ===
def cleanup_data():
    """Elimina todos los datos de Firestore y usuarios de Auth."""
    print("\n🧹 LIMPIANDO DATOS EXISTENTES...")
    
    # 1. Eliminar usuarios de Firebase Auth
    print("🗑️  Eliminando usuarios de Authentication...")
    try:
        users = auth.list_users().users
        for user in users:
            auth.delete_user(user.uid)
            print(f"   ✓ Usuario eliminado: {user.email}")
    except Exception as e:
        print(f"   ⚠️  Error eliminando usuarios: {e}")
    
    # 2. Eliminar colección 'users'
    print("🗑️  Eliminando colección 'users'...")
    try:
        users_ref = db.collection('users')
        docs = users_ref.stream()
        deleted = 0
        for doc in docs:
            doc.reference.delete()
            deleted += 1
        print(f"   ✓ {deleted} documentos eliminados de 'users'")
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
    
    # 3. Eliminar colección 'communities' (incluyendo subcollections)
    print("🗑️  Eliminando colección 'communities'...")
    try:
        communities_ref = db.collection('communities')
        docs = communities_ref.stream()
        deleted = 0
        for doc in docs:
            # Eliminar subcollection 'units'
            units_ref = doc.reference.collection('units')
            for unit in units_ref.stream():
                unit.reference.delete()
            # Eliminar documento de comunidad
            doc.reference.delete()
            deleted += 1
        print(f"   ✓ {deleted} comunidades eliminadas")
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
    
    print("✅ Limpieza completada\n")

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

def create_community_with_units(name, address, comuna, region, floors=4, units_per_floor=6):
    """Crea una comunidad con un edificio y unidades"""
    
    # Crear comunidad
    community_ref = db.collection('communities').document()
    community_id = community_ref.id
    
    community_data = {
        "id": community_id,
        "name": name,
        "address": address,
        "comuna": comuna,
        "region": region,
        "is_active": True,
        "created_at": datetime.now(),
        # Datos Bancarios ficticios
        "bank_name": "Banco Estado",
        "bank_account_type": "Cuenta Corriente",
        "bank_account_number": f"{random.randint(10000000, 99999999)}",
        "bank_account_rut": "76.000.000-0",  # RUT genérico de empresa
        "bank_account_email": "admin@vecinapp.cl",
    }
    community_ref.set(community_data)
    print(f"✅ Comunidad creada: {name} (ID: {community_id})")
    
    # Crear unidades
    units = []
    for floor in range(1, floors + 1):
        for dept in range(1, units_per_floor + 1):
            unit_code = f"{floor}{dept:02d}"
            
            unit_data = {
                "name": unit_code,
                "floor": floor,
                "type": "Departamento",
                "status": "Disponible",
                "community_id": community_id,
                "alicuota": round(100.0 / (floors * units_per_floor), 2),
                "m2": 45.0,
                "description": f"Departamento {unit_code}",
            }
            
            unit_ref = community_ref.collection('units').document()
            unit_data["id"] = unit_ref.id
            unit_ref.set(unit_data)
            
            units.append({
                "id": unit_ref.id,
                "name": unit_code,
                "floor": floor
            })
    
    print(f"   └─ {len(units)} unidades creadas")
    return community_id, community_data, units

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

def seed_complete_data():
    """Pobla Firebase con datos completos de prueba"""
    print("\n" + "="*60)
    print("🌱 POBLAMIENTO COMPLETO DE FIREBASE")
    print("="*60 + "\n")
    
    cleanup_data()
    
    # ========================================
    # 1. CREAR COMUNIDADES CON UNIDADES
    # ========================================
    print("📍 Creando comunidades...\n")
    
    comm1_id, comm1_data, comm1_units = create_community_with_units(
        name="Edificio Las Condes",
        address="Av. Apoquindo 4500",
        comuna="Las Condes",
        region="Metropolitana",
        floors=4,
        units_per_floor=6
    )
    
    comm2_id, comm2_data, comm2_units = create_community_with_units(
        name="Condominio Conecta Huechuraba",
        address="Av. Pedro Fontova 5200",
        comuna="Huechuraba",
        region="Metropolitana",
        floors=4,
        units_per_floor=6
    )
    
    print()
    
    # ========================================
    # 2. CREAR SUPER ADMIN Y ADMINS
    # ========================================
    print("👑 Creando Super Admin y Administradores...\n")
    
    # Super Admin (ve todas las comunidades)
    super_admin_uid = create_auth_user(
        email="admin@vecinapp.cl",
        password="Admin123!",
        display_name="Admin Sistema"
    )
    
    if super_admin_uid:
        super_admin_memberships = [
            {
                "community_id": comm1_id,
                "community_name": comm1_data['name'],
                "roles": ["administrator"],
                "start_date": datetime.now(),
                "is_active": True
            },
            {
                "community_id": comm2_id,
                "community_name": comm2_data['name'],
                "roles": ["administrator"],
                "start_date": datetime.now(),
                "is_active": True
            }
        ]
        
        create_user_profile(
            uid=super_admin_uid,
            first_name="Admin",
            last_name="Sistema",
            email="admin@vecinapp.cl",
            role="administrator",
            rut="11111111-1",
            community_memberships=super_admin_memberships
        )
        print("✅ Super Admin creado")
    
    # Admin Edificio Las Condes
    admin1_uid = create_auth_user(
        email="admin.lascondes@vecinapp.cl",
        password="Admin123!",
        display_name="Pedro Administrador"
    )
    
    if admin1_uid:
        admin1_memberships = [{
            "community_id": comm1_id,
            "community_name": comm1_data['name'],
            "roles": ["administrator"],
            "start_date": datetime.now(),
            "is_active": True
        }]
        
        create_user_profile(
            uid=admin1_uid,
            first_name="Pedro",
            last_name="Administrador",
            email="admin.lascondes@vecinapp.cl",
            role="administrator",
            rut="22222222-2",
            community_memberships=admin1_memberships
        )
        print("✅ Admin Las Condes creado")
    
    # Admin Condominio Huechuraba
    admin2_uid = create_auth_user(
        email="admin.huechuraba@vecinapp.cl",
        password="Admin123!",
        display_name="Laura Administradora"
    )
    
    if admin2_uid:
        admin2_memberships = [{
            "community_id": comm2_id,
            "community_name": comm2_data['name'],
            "roles": ["administrator"],
            "start_date": datetime.now(),
            "is_active": True
        }]
        
        create_user_profile(
            uid=admin2_uid,
            first_name="Laura",
            last_name="Administradora",
            email="admin.huechuraba@vecinapp.cl",
            role="administrator",
            rut="33333333-3",
            community_memberships=admin2_memberships
        )
        print("✅ Admin Huechuraba creado")
    
    print()
    
    # ========================================
    # 3. CREAR 10 RESIDENTES (5 POR COMUNIDAD)
    # ========================================
    print("👥 Creando 10 residentes de prueba...\n")
    
    # Nombres para testing (reducidos a 10)
    resident_names = [
        ("Ana", "Torres"), ("Juan", "López"), ("María", "Rojas"), ("Carlos", "Silva"),
        ("Sofía", "Muñoz"), ("Diego", "Vega"), ("Francisca", "Castro"), ("Matías", "Soto"),
        ("Valentina", "Mora"), ("Sebastián", "Paz")
    ]
    
    rut_base = 15000000
    
    # Distribuir: 5 en cada comunidad
    for i, (first_name, last_name) in enumerate(resident_names):
        # Alternar entre comunidades: primeros 5 en comm1, siguientes 5 en comm2
        if i < 5:
            community_id = comm1_id
            community_name = comm1_data['name']
            units = comm1_units
        else:
            community_id = comm2_id
            community_name = comm2_data['name']
            units = comm2_units
        
        email = f"{first_name.lower()}.{last_name.lower()}@test.cl"
        
        # Crear usuario en Auth
        resident_uid = create_auth_user(
            email=email,
            password="Test123!",
            display_name=f"{first_name} {last_name}"
        )
        
        if resident_uid:
            # Asignar 1-2 unidades al azar
            num_units = random.randint(1, 2)
            assigned_units = random.sample(units, num_units)
            
            # Crear memberships con unidades (una membership por unidad)
            memberships = []
            for unit in assigned_units:
                membership = {
                    "community_id": community_id,
                    "community_name": community_name,
                    "unit_id": unit['id'],
                    "unit_number": unit['name'],  # Usar 'name' en field 'unit_number'
                    "roles": ["resident"],
                    "start_date": datetime.now(),
                    "is_active": True
                }
                memberships.append(membership)
            
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
            for assigned_unit in assigned_units:
                unit_ref = db.collection('communities').document(community_id).collection('units').document(assigned_unit['id'])
                unit_ref.update({
                    'status': 'Asignado',
                    'is_occupied': True,
                    'resident_uid': resident_uid,
                    'resident_name': f"{first_name} {last_name}",
                    'updated_at': datetime.now()
                })
            
            unit_names = ', '.join([u['name'] for u in assigned_units])
            print(f"✅ {first_name} {last_name} ({community_name}) - Unidades: {unit_names}")
    
    print(f"\n🎉 ¡Seed completado! 3 administradores + 10 residentes creados.")
    
    # ========================================
    # 4. CREAR MANTENIMIENTOS
    # ========================================
    seed_maintenances(comm1_id, comm1_data['name'], comm2_id, comm2_data['name'])
    
    # ========================================
    # 5. CREAR GASTOS COMUNES
    # ========================================
    seed_common_expenses(comm1_id, comm1_data['name'], comm2_id, comm2_data['name'], super_admin_uid)
    
    # ========================================
    # 6. CREAR INCIDENTES DE PRUEBA
    # ========================================
    seed_incidents(comm1_id, comm1_data['name'])
    
    print("\n" + "="*60)
    print("🔐 CREDENCIALES:")
    print("\n   👑 SUPER ADMIN:")
    print(f"      Email: admin@vecinapp.cl")
    print(f"      Password: Admin123!")
    
    print("\n   👨‍💼 ADMINS DE COMUNIDAD:")
    print(f"      admin.lascondes@vecinapp.cl / Admin123!")
    print(f"      admin.huechuraba@vecinapp.cl / Admin123!")
    
    print("\n   👤 RESIDENTES (todos):") 
    print(f"      Password: Test123!")
    print(f"      Ejemplos: ana.torres@test.cl, juan.lopez@test.cl")
    
    print("\n" + "="*60)
    print("✅ Listo para usar")
    print("="*60 + "\n")

def create_maintenance(community_id, community_name, maintenance_data):
    """Crea un mantenimiento en Firestore"""
    maintenance_ref = db.collection('communities').document(community_id).collection('maintenances').document()
    maintenance_id = maintenance_ref.id
    
    maintenance_data['id'] = maintenance_id
    maintenance_data['community_id'] = community_id
    maintenance_data['created_at'] = datetime.now()
    maintenance_data['updated_at'] = datetime.now()
    
    maintenance_ref.set(maintenance_data)
    print(f"   ✓ {maintenance_data['title']} - ${maintenance_data['cost']:,.0f} ({maintenance_data['frequency']})")
    return maintenance_id

def seed_maintenances(comm1_id, comm1_name, comm2_id, comm2_name):
    """Crea mantenimientos de ejemplo para ambas comunidades"""
    print("\n🔧 Creando mantenimientos...\n")
    
    # Calcular fechas
    from datetime import timedelta
    today = datetime.now()
    next_week = today + timedelta(days=7)
    
    # ========================================
    # MANTENIMIENTO 1: PISCINA (Semanal)
    # ========================================
    piscina_checklist = [
        {"title": "Limpieza de filtros", "is_completed": False},
        {"title": "Control de pH del agua", "is_completed": False},
        {"title": "Aspirado del fondo de la piscina", "is_completed": False},
        {"title": "Limpieza de bordes y paredes", "is_completed": False},
        {"title": "Revisión de nivel de cloro", "is_completed": False},
        {"title": "Limpieza de skimmers", "is_completed": False},
    ]
    
    piscina_data = {
        "title": "Mantenimiento de Piscina",
        "description": "Mantenimiento preventivo semanal de la piscina comunitaria. Incluye limpieza, control químico del agua y revisión de sistemas de filtrado.",
        "type": "preventivo",
        "frequency": "semanal",
        "provider_name": "Servicios Acuáticos Ltda",
        "provider_contact": "+56912345678",
        "cost": 200000,
        "scheduled_date": next_week,
        "completed_date": None,
        "status": "pendiente",
        "assigned_to": None,
        "approved_by": None,
        "approval_date": None,
        "notes": "Costo mensual de $200.000 con facturación mensual única",
        "checklist_items": piscina_checklist,
    }
    
    # ========================================
    # MANTENIMIENTO 2: JARDINES (2x Semana)
    # ========================================
    jardines_checklist = [
        {"title": "Corte y perfilado de césped", "is_completed": False},
        {"title": "Riego de áreas verdes", "is_completed": False},
        {"title": "Poda de arbustos y setos", "is_completed": False},
        {"title": "Control de malezas", "is_completed": False},
        {"title": "Fertilización del césped", "is_completed": False},
        {"title": "Limpieza de hojas y residuos", "is_completed": False},
        {"title": "Revisión de sistema de riego", "is_completed": False},
    ]
    
    jardines_data = {
        "title": "Mantenimiento de Jardines",
        "description": "Mantenimiento preventivo de áreas verdes 2 veces por semana. Incluye corte de césped, poda, riego y fertilización de jardines comunitarios.",
        "type": "preventivo",
        "frequency": "semanal",
        "provider_name": "Jardines del Sur SpA",
        "provider_contact": "+56987654321",
        "cost": 450000,
        "scheduled_date": next_week,
        "completed_date": None,
        "status": "pendiente",
        "assigned_to": None,
        "approved_by": None,
        "approval_date": None,
        "notes": "Servicio 2 veces por semana. Costo mensual de $450.000 con facturación mensual única",
        "checklist_items": jardines_checklist,
    }
    
    # ========================================
    # MANTENIMIENTO 3: CONTROL DE PLAGAS (Mensual)
    # ========================================
    plagas_checklist = [
        {"title": "Fumigación de áreas comunes", "is_completed": False},
        {"title": "Revisión de puntos críticos", "is_completed": False},
        {"title": "Aplicación de gel anti-hormigas", "is_completed": False},
        {"title": "Control de roedores", "is_completed": False},
        {"title": "Inspección de sótanos y bodegas", "is_completed": False},
        {"title": "Colocación de trampas adhesivas", "is_completed": False},
        {"title": "Informe técnico de tratamiento", "is_completed": False},
    ]
    
    plagas_data = {
        "title": "Control de Plagas",
        "description": "Servicio preventivo mensual de control de plagas. Incluye fumigación, control de roedores e insectos en áreas comunes y exteriores.",
        "type": "preventivo",
        "frequency": "mensual",
        "provider_name": "Fumigaciones Express Ltda",
        "provider_contact": "+56923456789",
        "cost": 180000,
        "scheduled_date": next_week,
        "completed_date": None,
        "status": "pendiente",
        "assigned_to": None,
        "approved_by": None,
        "approval_date": None,
        "notes": "Servicio mensual. Costo de $180.000 con facturación mensual",
        "checklist_items": plagas_checklist,
    }
    
    # ========================================
    # MANTENIMIENTO 4: PORTÓN ELÉCTRICO (Extraordinario)
    # ========================================
    porton_checklist = [
        {"title": "Revisión de motor eléctrico", "is_completed": False},
        {"title": "Lubricación de rieles y cadenas", "is_completed": False},
        {"title": "Ajuste de sensores de seguridad", "is_completed": False},
        {"title": "Prueba de sistema de apertura", "is_completed": False},
        {"title": "Revisión de cableado eléctrico", "is_completed": False},
        {"title": "Limpieza de fotocélulas", "is_completed": False},
        {"title": "Verificación de control remoto", "is_completed": False},
        {"title": "Ajuste de límites de recorrido", "is_completed": False},
    ]
    
    porton_data = {
        "title": "Reparación Portón Eléctrico",
        "description": "Mantenimiento extraordinario del portón eléctrico de acceso. Incluye revisión completa del sistema, ajustes y reparaciones necesarias.",
        "type": "extraordinario",
        "frequency": "unica_vez",
        "provider_name": "Automatización y Portones S.A.",
        "provider_contact": "+56934567890",
        "cost": 90000,
        "scheduled_date": next_week,
        "completed_date": None,
        "status": "pendiente",
        "assigned_to": None,
        "approved_by": None,
        "approval_date": None,
        "notes": "Trabajo extraordinario. Costo único de $90.000",
        "checklist_items": porton_checklist,
    }
    
    # Crear mantenimientos para Comunidad 1
    print(f"📍 {comm1_name}:")
    create_maintenance(comm1_id, comm1_name, piscina_data.copy())
    create_maintenance(comm1_id, comm1_name, jardines_data.copy())
    create_maintenance(comm1_id, comm1_name, plagas_data.copy())
    create_maintenance(comm1_id, comm1_name, porton_data.copy())
    
    # Crear mantenimientos para Comunidad 2
    print(f"\n📍 {comm2_name}:")
    create_maintenance(comm2_id, comm2_name, piscina_data.copy())
    create_maintenance(comm2_id, comm2_name, jardines_data.copy())
    create_maintenance(comm2_id, comm2_name, plagas_data.copy())
    create_maintenance(comm2_id, comm2_name, porton_data.copy())
    
    print(f"\n✅ 8 mantenimientos creados (4 por comunidad)")
    print(f"   Total mensual por comunidad: $920.000")

def seed_common_expenses(comm1_id, comm1_name, comm2_id, comm2_name, admin_uid):
    """Crea gastos comunes de ejemplo para ambas comunidades"""
    print("\n💰 Creando gastos comunes...\n")
    
    from datetime import timedelta
    today = datetime.now()
    current_month = today.month
    current_year = today.year
    
    # Mes pasado
    if current_month == 1:
        last_month = 12
        last_year = current_year - 1
    else:
        last_month = current_month - 1
        last_year = current_year
    
    month_names = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                   'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre']
    
    def create_common_expense(community_id, community_name, month, year, status_val, closed_by=None):
        """Helper para crear un gasto común"""
        period = f"{year}-{month:02d}"
        period_display = f"{month_names[month-1]} {year}"
        
        # Items por categoría
        items = {
            'remuneraciones': [
                {
                    'description': 'Sueldo Conserje',
                    'amount': 550000,
                    'doc_number': '12345',
                    'date': datetime(year, month, 5).isoformat(),
                },
                {
                    'description': 'Honorarios Administrador',
                    'amount': 350000,
                    'doc_number': '12346',
                    'date': datetime(year, month, 5).isoformat(),
                },
            ],
            'gastos_extraordinarios': [
                {
                    'description': 'Reparación Portón Eléctrico',
                    'amount': 90000,
                    'doc_number': '98765',
                    'date': datetime(year, month, 15).isoformat(),
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
            ],
            'servicios_comunes': [
                {
                    'description': 'Electricidad Áreas Comunes',
                    'amount': 180000,
                    'doc_number': '55512',
                    'date': datetime(year, month, 20).isoformat(),
                },
                {
                    'description': 'Agua Potable',
                    'amount': 120000,
                    'doc_number': '55513',
                    'date': datetime(year, month, 20).isoformat(),
                },
            ],
        }
        
        # Calcular total
        total_amount = sum(
            sum(item['amount'] for item in category_items)
            for category_items in items.values()
        )
        
        # Obtener unidades de la comunidad para calcular distribución
        units_ref = db.collection('communities').document(community_id).collection('units')
        units_docs = list(units_ref.stream())
        
        # Obtener usuarios
        users_ref = db.collection('users')
        users_docs = list(users_ref.stream())
        users_map = {doc.id: doc.to_dict() for doc in users_docs}
        
        # Calcular unit_expenses si está cerrado o notificado
        unit_expenses = []
        if status_val in ['closed', 'notified']:
            for unit_doc in units_docs:
                unit_data = unit_doc.to_dict()
                unit_id = unit_doc.id
                unit_name = unit_data.get('name', '')
                alicuota = unit_data.get('alicuota', 0.0)
                
                # Calcular monto para esta unidad
                unit_amount = total_amount * (alicuota / 100.0)
                
                # Buscar residente
                resident_uid = unit_data.get('resident_uid')
                resident_name = None
                resident_email = None
                
                if resident_uid and resident_uid in users_map:
                    user_data = users_map[resident_uid]
                    first_name = user_data.get('first_name', '')
                    last_name = user_data.get('last_name', '')
                    resident_name = f"{first_name} {last_name}".strip() or user_data.get('name', 'Residente')
                    resident_email = user_data.get('email')
                
                unit_expenses.append({
                    'unit_id': unit_id,
                    'unit_name': unit_name,
                    'alicuota': alicuota,
                    'amount': unit_amount,
                    'resident_uid': resident_uid,
                    'resident_name': resident_name,
                    'resident_email': resident_email,
                    'pdf_url': None,
                })
        
        # Crear documento
        expense_data = {
            'community_id': community_id,
            'period': period,
            'month': month,
            'year': year,
            'status': status_val,
            'total_amount': total_amount,
            'items': items,
            'unit_expenses': unit_expenses,
            'closed_by': closed_by if status_val in ['closed', 'notified'] else None,
            'closed_at': datetime.now() if status_val in ['closed', 'notified'] else None,
            'created_by': admin_uid,
            'created_at': datetime.now(),
            'updated_at': datetime.now(),
        }
        
        # Guardar en Firestore
        expense_ref = db.collection('communities').document(community_id)\
            .collection('common_expenses').document()
        expense_data['id'] = expense_ref.id
        expense_ref.set(expense_data)
        
        status_label = {
            'draft': 'BORRADOR',
            'closed': 'CERRADO',
            'notified': 'NOTIFICADO'
        }[status_val]
        
        print(f"   ✓ Gasto común {period_display}: ${total_amount:,.0f} [{status_label}]")
        return expense_ref.id
    
    # Crear gastos comunes para Comunidad 1
    print(f"📍 {comm1_name}:")
    # Gasto del mes pasado (notificado)
    create_common_expense(comm1_id, comm1_name, last_month, last_year, 'notified', admin_uid)
    # Gasto del mes actual (cerrado, listo para notificar)
    create_common_expense(comm1_id, comm1_name, current_month, current_year, 'closed', admin_uid)
    
    # Crear gastos comunes para Comunidad 2
    print(f"\n📍 {comm2_name}:")
    create_common_expense(comm2_id, comm2_name, last_month, last_year, 'notified', admin_uid)
    create_common_expense(comm2_id, comm2_name, current_month, current_year, 'closed', admin_uid)
    
    print(f"\n✅ 4 gastos comunes creados (2 por comunidad)")
    print(f"   - Mes pasado: NOTIFICADO (enviado a residentes)")
    print(f"   - Mes actual: CERRADO (listo para notificar)")

def seed_incidents(comm_id, comm_name):
    """Crea incidentes de prueba para la comunidad Las Condes"""
    print(f"\n🚨 Creando incidentes de prueba...\n")
    print(f"📍 {comm_name}:")
    
    from datetime import timedelta
    
    # Obtener usuarios residentes de esta comunidad
    users_ref = db.collection('users')
    users_docs = list(users_ref.stream())
    
    # Filtrar residentes de esta comunidad
    residents = []
    for user_doc in users_docs:
        user_data = user_doc.to_dict()
        memberships = user_data.get('memberships', [])
        for membership in memberships:
            if membership.get('community_id') == comm_id and 'resident' in membership.get('roles', []):
                residents.append({
                    'uid': user_doc.id,
                    'name': f"{user_data.get('first_name', '')} {user_data.get('last_name', '')}".strip(),
                    'unit': membership.get('unit_number', 'N/A')
                })
                break
    
    if len(residents) < 2:
        print("   ⚠️  No hay suficientes residentes para crear incidentes")
        return
    
    # Tomar los primeros 2 residentes para crear incidentes
    resident1 = residents[0]
    resident2 = residents[1]
    
    today = datetime.now()
    
    # Incidentes de ejemplo
    incidents_data = [
        {
            'user': resident1,
            'title': 'Problema con el ascensor del piso 3',
            'description': 'El ascensor se detiene en el piso 3 y no sube más. Hace ruidos extraños y la puerta no cierra correctamente.',
            'category': 'instalaciones',
            'priority': 'alta',
            'status': 'pendiente',
            'created_at': today - timedelta(days=2),
            'comments': []
        },
        {
            'user': resident1,
            'title': 'Filtración de agua en estacionamiento',
            'description': 'Hay una filtración de agua en el estacionamiento subterráneo, sector A. El agua está empozándose cerca de los estacionamientos 15-20.',
            'category': 'instalaciones',
            'priority': 'alta',
            'status': 'en_proceso',
            'created_at': today - timedelta(days=5),
            'comments': [
                {
                    'user_name': 'Admin Sistema',
                    'user_role': 'admin',
                    'comment_text': 'Ya contactamos al plomero. Vendrá mañana a revisar.',
                    'created_at': today - timedelta(days=4)
                }
            ]
        },
        {
            'user': resident2,
            'title': 'Intento de robo en el edificio',
            'description': 'Anoche alrededor de las 23:00 hrs se vieron personas sospechosas intentando forzar la puerta del acceso peatonal. Las cámaras deberían tener registro.',
            'category': 'seguridad',
            'priority': 'critica',
            'status': 'resuelto',
            'created_at': today - timedelta(days=3),
            'comments': [
                {
                    'user_name': 'Admin Sistema',
                    'user_role': 'admin',
                    'comment_text': 'Se revisaron las cámaras y se hizo la denuncia a Carabineros. Se reforzará la seguridad.',
                    'created_at': today - timedelta(days=2)
                },
                {
                    'user_name': resident2['name'],
                    'user_role': 'resident',
                    'comment_text': 'Gracias por la rápida gestión. ¿Se va a cambiar la cerradura?',
                    'created_at': today - timedelta(days=1)
                },
                {
                    'user_name': 'Admin Sistema',
                    'user_role': 'admin',
                    'comment_text': 'Sí, mañana viene el cerrajero a instalar una nueva cerradura de seguridad.',
                    'created_at': today - timedelta(hours=12)
                }
            ]
        },
        {
            'user': resident2,
            'title': 'Ruido excesivo en depto 401',
            'description': 'El departamento 401 está haciendo mucho ruido después de las 22:00 hrs todos los días. Música alta y movimientos de muebles.',
            'category': 'ruido',
            'priority': 'media',
            'status': 'pendiente',
            'created_at': today - timedelta(days=1),
            'comments': []
        }
    ]
    
    # Crear incidentes
    incidents_ref = db.collection('communities').document(comm_id).collection('incidents')
    
    for incident_data in incidents_data:
        user = incident_data['user']
        
        # Preparar documento del incidente
        incident_doc = {
            'title': incident_data['title'],
            'description': incident_data['description'],
            'category': incident_data['category'],
            'priority': incident_data['priority'],
            'status': incident_data['status'],
            'community_id': comm_id,
            'created_by': user['uid'],
            'reported_by_id': user['uid'],
            'reported_by_name': user['name'],
            'reported_by_unit': user['unit'],
            'is_security': incident_data['category'] == 'seguridad',
            'admin_notes': None,
            'created_at': incident_data['created_at'],
            'updated_at': incident_data['created_at'],
            'resolved_at': incident_data['created_at'] + timedelta(hours=1) if incident_data['status'] == 'resuelto' else None,
            'resolved_by_id': 'admin-system' if incident_data['status'] == 'resuelto' else None,
            'resolved_by_name': 'Admin Sistema' if incident_data['status'] == 'resuelto' else None,
        }
        
        # Crear el incidente
        incident_ref = incidents_ref.document()
        incident_doc['id'] = incident_ref.id
        incident_ref.set(incident_doc)
        
        # Crear comentarios si existen
        if incident_data['comments']:
            comments_ref = incident_ref.collection('comments')
            for comment_data in incident_data['comments']:
                comment_doc = {
                    'user_name': comment_data['user_name'],
                    'user_role': comment_data['user_role'],
                    'comment_text': comment_data['comment_text'],
                    'created_at': comment_data['created_at']
                }
                comment_ref = comments_ref.document()
                comment_doc['id'] = comment_ref.id
                comment_ref.set(comment_doc)
        
        status_emoji = {
            'pendiente': '⏳',
            'en_proceso': '🔄',
            'resuelto': '✅'
        }.get(incident_data['status'], '❓')
        
        comments_count = len(incident_data['comments'])
        comments_str = f" ({comments_count} comentarios)" if comments_count > 0 else ""
        
        print(f"   {status_emoji} {incident_data['title']}{comments_str}")
        print(f"      Reportado por: {user['name']} (Depto {user['unit']})")
    
    print(f"\n✅ {len(incidents_data)} incidentes creados para {comm_name}")

if __name__ == "__main__":
    seed_complete_data()
