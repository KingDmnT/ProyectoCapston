from fastapi import APIRouter, Depends, HTTPException, status, Query
from app.schemas.common_expense import (
    CommonExpense, CommonExpenseCreate, CommonExpenseUpdate,
    ExpenseLineItem
)
from app.repositories.common_expense_repo import CommonExpenseRepository
from app.utils.pdf_generator import generate_common_expense_pdf
from app.utils.temp_token import get_token_manager
from app.services.email_service import send_common_expense_email, send_bulk_common_expense_emails
from app.api.auth import get_current_user
from app.core.security import get_current_user_optional
from typing import List, Optional
from fastapi.responses import FileResponse
from pathlib import Path
import tempfile
import os

router = APIRouter()

# Helper function to get repository instance
def get_repo():
    return CommonExpenseRepository()

# =======================
# ENDPOINTS PARA ADMINISTRADORES
# =======================

@router.post("/", response_model=CommonExpense, status_code=status.HTTP_201_CREATED)
def create_common_expense(
    expense: CommonExpenseCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Crea un nuevo gasto común en estado borrador.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden crear gastos comunes"
        )
    
    try:
        return get_repo().create(expense, current_user["uid"])
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.get("/", response_model=List[CommonExpense])
def list_common_expenses(
    community_id: str = Query(..., description="ID de la comunidad"),
    year: Optional[int] = Query(None, description="Año"),
    month: Optional[int] = Query(None, description="Mes (1-12)"),
    status: Optional[str] = Query(None, description="Estado (draft, closed, notified)"),
    current_user: dict = Depends(get_current_user)
):
    """
    Lista gastos comunes con filtros opcionales.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden listar gastos comunes"
        )
    
    try:
        return get_repo().get_all(community_id, year, month, status)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{expense_id}", response_model=CommonExpense)
def get_common_expense(
    expense_id: str,
    community_id: str = Query(..., description="ID de la comunidad"),
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene detalle de un gasto común.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden ver gastos comunes"
        )
    
    expense = get_repo().get_by_id(community_id, expense_id)
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto común no encontrado"
        )
    
    return expense

@router.put("/{expense_id}", response_model=CommonExpense)
def update_common_expense(
    expense_id: str,
    community_id: str,
    update_data: CommonExpenseUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Actualiza items del gasto común.
    Solo permite actualización si está en borrador.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden actualizar gastos comunes"
        )
    
    try:
        return get_repo().update(community_id, expense_id, update_data)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/{expense_id}/import-maintenances", response_model=CommonExpense)
def import_maintenances(
    expense_id: str,
    community_id: str,
    year: int,
    month: int,
    current_user: dict = Depends(get_current_user)
):
    """
    Importa mantenimientos del mes seleccionado y los agrupa.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden importar mantenimientos"
        )
    
    try:
        return get_repo().import_maintenances(community_id, expense_id, year, month)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/{expense_id}/close", response_model=CommonExpense)
def close_expense(
    expense_id: str,
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Cierra el período de gasto común.
    Calcula distribución por unidades y cambia estado a CLOSED.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden cerrar gastos comunes"
        )
    
    try:
        return get_repo().close_expense(community_id, expense_id, current_user["uid"])
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/{expense_id}/notify")
def notify_residents(
    expense_id: str,
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Genera PDFs para todas las unidades y envía emails a los residentes.
    Marca el gasto como NOTIFIED.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden notificar residentes"
        )
    
    # Obtener gasto común
    expense = get_repo().get_by_id(community_id, expense_id)
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto común no encontrado"
        )
    
    if expense.status != "closed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo se pueden notificar gastos cerrados"
        )
    
    # Obtener datos de la comunidad
    from app.core.firebase import get_db
    db = get_db()
    community_doc = db.collection('communities').document(community_id).get()
    if not community_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comunidad no encontrada"
        )
    community_data = community_doc.to_dict()
    
    try:
        # Agrupar unidades por residente
        resident_units = {}
        for unit_expense in expense.unit_expenses:
            if not unit_expense.resident_email:
                continue
                
            email = unit_expense.resident_email
            uid = unit_expense.resident_uid or email # Fallback to email as key if uid missing (should vary rarely happen)
            
            if uid not in resident_units:
                resident_units[uid] = {
                    'email': email,
                    'name': unit_expense.resident_name or 'Residente',
                    'units': [],
                    'amount': 0.0
                }
            
            resident_units[uid]['units'].append(unit_expense)
            resident_units[uid]['amount'] += unit_expense.amount
            
        
        # Generar PDFs y enviar emails
        recipients = []
        month_names = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre']
        period_str = f"{month_names[expense.month-1]} {expense.year}"
        
        # Crear directorio temporal para los PDFs
        temp_dir = tempfile.mkdtemp()
        
        for uid, data in resident_units.items():
            # Generar UN solo PDF por residente (con todas sus unidades)
            pdf_filename = f"gasto_comun_{expense.period}_{data['name'].replace(' ', '_')}.pdf"
            pdf_path = os.path.join(temp_dir, pdf_filename)
            
            generate_common_expense_pdf(
                expense_data=expense.dict(),
                unit_expenses=[u.dict() for u in data['units']],
                community_data=community_data,
                output_path=pdf_path
            )
            
            unit_numbers = [u.unit_name for u in data['units']]
            
            recipients.append({
                'to_email': data['email'],
                'to_name': data['name'],
                'community_name': community_data.get('name', 'Comunidad'),
                'period': period_str,
                'amount': data['amount'],
                'pdf_path': pdf_path,
                'unit_numbers': unit_numbers
            })
        
        # Enviar emails masivos
        results = send_bulk_common_expense_emails(recipients)
        
        # Marcar como notificado
        get_repo().mark_as_notified(community_id, expense_id)
        
        return {
            "message": "Notificaciones enviadas",
            "total": len(resident_units),
            "sent": results['sent'],
            "failed": results['failed']
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al enviar notificaciones: {str(e)}"
        )


@router.get("/{expense_id}/pdf/{unit_id}")
def download_pdf(
    expense_id: str,
    unit_id: str,
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Descarga el PDF de gasto común para una unidad específica.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden descargar PDFs"
        )
    
    # Obtener gasto común
    expense = get_repo().get_by_id(community_id, expense_id)
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto común no encontrado"
        )
    
    # Buscar TODAS las unidades del residente asociado a unit_id (grouped PDF)
    # Primero encontramos la unidad solicitada para obtener el residente
    target_unit = next((ue for ue in expense.unit_expenses if ue.unit_id == unit_id), None)
    if not target_unit:
        raise HTTPException(status_code=404, detail="Unidad no encontrada")
        
    resident_uid = target_unit.resident_uid
    
    # Filtramos todas las unidades de ese residente
    if resident_uid:
        resident_units = [ue for ue in expense.unit_expenses if ue.resident_uid == resident_uid]
    else:
        # Si no tiene residente asignado (raro), solo imprimimos esa unidad
        resident_units = [target_unit]
    
    # Obtener datos de la comunidad
    from app.core.firebase import get_db
    db = get_db()
    community_doc = db.collection('communities').document(community_id).get()
    if not community_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comunidad no encontrada"
        )
    community_data = community_doc.to_dict()
    
    # Generar PDF temporal combinado
    temp_dir = tempfile.mkdtemp()
    # Usar nombre del residente o unidad si es unico
    name_suffix = target_unit.resident_name or target_unit.unit_name
    pdf_filename = f"gasto_comun_{expense.period}_{name_suffix.replace(' ', '_')}.pdf"
    pdf_path = os.path.join(temp_dir, pdf_filename)
    
    try:
        generate_common_expense_pdf(
            expense_data=expense.dict(),
            unit_expenses=[u.dict() for u in resident_units],
            community_data=community_data,
            output_path=pdf_path
        )
        
        return FileResponse(
            pdf_path,
            media_type='application/pdf',
            filename=pdf_filename
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generando PDF: {str(e)}"
        )

@router.get("/{expense_id}/pdf-resident/{resident_uid}")
def download_resident_pdf(
    expense_id: str,
    resident_uid: str,
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Descarga el PDF de gasto común para un residente específico (agrupado).
    Solo admin.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(status_code=403, detail="No autorizado")
        
    expense = get_repo().get_by_id(community_id, expense_id)
    if not expense:
        raise HTTPException(status_code=404, detail="Gasto común no encontrado")
        
    resident_units = [ue for ue in expense.unit_expenses if ue.resident_uid == resident_uid]
    
    if not resident_units:
        raise HTTPException(status_code=404, detail="Residente no tiene unidades en este gasto")

    # Obtener datos comunidad
    from app.core.firebase import get_db
    db = get_db()
    community_doc = db.collection('communities').document(community_id).get()
    community_data = community_doc.to_dict() if community_doc.exists else {}
    
    temp_dir = tempfile.mkdtemp()
    name_suffix = resident_units[0].resident_name or 'Residente'
    pdf_filename = f"gasto_comun_{expense.period}_{name_suffix.replace(' ', '_')}.pdf"
    pdf_path = os.path.join(temp_dir, pdf_filename)
    
    try:
        generate_common_expense_pdf(
            expense_data=expense.dict(),
            unit_expenses=[u.dict() for u in resident_units],
            community_data=community_data,
            output_path=pdf_path
        )
        return FileResponse(pdf_path, media_type='application/pdf', filename=pdf_filename)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_common_expense(
    expense_id: str,
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Elimina un gasto común.
    Solo permite eliminar si está en borrador.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden eliminar gastos comunes"
        )
    
    try:
        get_repo().delete(community_id, expense_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.get("/{expense_id}/residents", response_model=List[dict])
def get_expense_residents(
    expense_id: str,
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene la lista de residentes y sus gastos agrupados para un gasto común específico.
    Solo administradores.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(status_code=403, detail="No autorizado")
        
    expense = get_repo().get_by_id(community_id, expense_id)
    if not expense:
        raise HTTPException(status_code=404, detail="Gasto común no encontrado")
        
    # Agrupar por residente
    grouped = {}
    for ue in expense.unit_expenses:
        # Usar UID si existe, sino agrupar por "Sin Asignar" o similar?
        # Asumiremos que unidades tienen resident_uid si estann asignadas.
        uid = ue.resident_uid
        if not uid:
            continue # O manejar unidades vacías en un grupo "Sin Residente"
            
        if uid not in grouped:
            grouped[uid] = {
                'resident_uid': uid,
                'resident_name': ue.resident_name or 'Desconocido',
                'total_amount': 0.0,
                'is_paid': True,
                'payment_date': None,
                'units': [],
                'reference_unit_id': ue.unit_id # Guardar uno para referencias
            }
        
        grouped[uid]['total_amount'] += ue.amount
        grouped[uid]['units'].append(ue.unit_name)
        if not ue.is_paid:
            grouped[uid]['is_paid'] = False
        if ue.payment_date:
            grouped[uid]['payment_date'] = ue.payment_date # Tomar la fecha de cualquiera (idealmente son iguales)
            
    return list(grouped.values())

@router.post("/{expense_id}/residents/{resident_uid}/pay")
def mark_resident_paid(
    expense_id: str,
    resident_uid: str,
    community_id: str,
    is_paid: bool = Query(True),
    current_user: dict = Depends(get_current_user)
):
    """
    Marca como pagado el gasto común de un residente (todas sus unidades).
    Solo admin.
    """
    if current_user.get("role") != "administrator":
        raise HTTPException(status_code=403, detail="No autorizado")
        
    try:
        return get_repo().mark_as_paid(community_id, expense_id, resident_uid, is_paid)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

# =======================
# ENDPOINTS PARA RESIDENTES
# =======================

@router.get("/my-expenses/list")
def get_my_expenses(
    community_id: str = Query(..., description="ID de la comunidad"),
    current_user: dict = Depends(get_current_user)
):
    """
    Lista gastos comunes del residente (últimos 2 años).
    Para residentes.
    """
    try:
        return get_repo().get_resident_expenses(current_user["uid"], community_id, limit_years=2)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/my-expenses/{expense_id}/generate-download-token")
def generate_pdf_download_token(
    expense_id: str,
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Genera un token temporal para descargar el PDF sin autenticación.
    Token válido por 5 minutos y de un solo uso.
    """
    # Verificar que el gasto común existe y el usuario tiene acceso
    expense = get_repo().get_by_id(community_id, expense_id)
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto común no encontrado"
        )
    
    # Verificar que el usuario tiene al menos una unidad en este gasto
    resident_units = [ue for ue in expense.unit_expenses if ue.resident_uid == current_user["uid"]]
    if not resident_units:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tiene acceso a este gasto común"
        )
    
    # Generar token temporal
    token_manager = get_token_manager()
    token = token_manager.generate_token(
        user_uid=current_user["uid"],
        expense_id=expense_id,
        community_id=community_id
    )
    
    return {"token": token, "expires_in": 300}  # 5 minutos

@router.get("/my-expenses/{expense_id}/pdf")
def download_my_pdf(
    expense_id: str,
    community_id: str,
    token: str | None = Query(None, description="Token temporal para descarga sin auth"),
    current_user: dict | None = Depends(get_current_user_optional)
):
    """
    Descarga el PDF de gasto común del residente.
    Acepta autenticación vía Bearer token O token temporal.
    Para residentes.
    """
    # Determinar user_uid según el método de autenticación
    user_uid = None
    
    if token:
        # Usar token temporal
        token_manager = get_token_manager()
        token_data = token_manager.validate_and_consume_token(token)
        
        if not token_data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido o expirado"
            )
        
        token_user_uid, token_expense_id, token_community_id = token_data
        
        # Verificar que el token corresponde a este gasto y comunidad
        if token_expense_id != expense_id or token_community_id != community_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Token no válido para este recurso"
            )
        
        user_uid = token_user_uid
        
    elif current_user:
        # Usar autenticación bearer tradicional
        user_uid = current_user["uid"]
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Autenticación requerida"
        )
    
    # Obtener gasto común
    expense = get_repo().get_by_id(community_id, expense_id)
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto común no encontrado"
        )
    
    # Buscar unidades del residente
    resident_units = [ue for ue in expense.unit_expenses if ue.resident_uid == user_uid]
    
    if not resident_units:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tiene acceso a este gasto común"
        )
    
    # Usar la primera unidad (o podrías generar un PDF combinado)
    unit_expense = resident_units[0]
    
    
    # Obtener datos de la comunidad
    from google.cloud.firestore import Client as FirestoreClient
    from firebase_admin import firestore as admin_firestore
    
    db = admin_firestore.client()
    community_doc = db.collection('communities').document(community_id).get()
    if not community_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comunidad no encontrada"
        )
    community_data = community_doc.to_dict()
    
    # Generar PDF temporal
    temp_dir = tempfile.mkdtemp()
    pdf_filename = f"mi_gasto_comun_{expense.period}.pdf"
    pdf_path = os.path.join(temp_dir, pdf_filename)
    
    try:
        generate_common_expense_pdf(
            expense_data=expense.dict(),
            unit_expenses=[u.dict() for u in resident_units],
            community_data=community_data,
            output_path=pdf_path
        )
        
        return FileResponse(
            pdf_path,
            media_type='application/pdf',
            filename=pdf_filename
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generando PDF: {str(e)}"
        )
