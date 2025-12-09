import firebase_admin
from firebase_admin import firestore as admin_firestore
from app.schemas.common_expense import (
    CommonExpense, CommonExpenseCreate, CommonExpenseUpdate,
    ExpenseLineItem, UnitExpense, ExpenseStatus
)
from typing import List, Optional
from datetime import datetime

class CommonExpenseRepository:
    """Repositorio para gestión de gastos comunes en Firestore"""
    
    def __init__(self):
        self._db = None
    
    @property
    def db(self):
        """Lazy initialization of Firestore client using Firebase Admin SDK"""
        if self._db is None:
            self._db = admin_firestore.client()
        return self._db
    def create(self, expense: CommonExpenseCreate, created_by_uid: str) -> CommonExpense:
        """
        Crea un nuevo gasto común en estado borrador.
        Ruta: communities/{community_id}/common_expenses/{expense_id}
        """
        community_ref = self.db.collection('communities').document(expense.community_id)
        expense_ref = community_ref.collection('common_expenses').document()
        
        expense_data = expense.dict()
        expense_data['id'] = expense_ref.id
        expense_data['status'] = ExpenseStatus.DRAFT.value
        expense_data['total_amount'] = 0.0
        expense_data['created_by'] = created_by_uid
        expense_data['created_at'] = datetime.now()
        expense_data['updated_at'] = datetime.now()
        expense_data['unit_expenses'] = []
        
        expense_ref.set(expense_data)
        return CommonExpense(**expense_data)
    
    def get_all(
        self,
        community_id: str,
        year: Optional[int] = None,
        month: Optional[int] = None,
        status: Optional[str] = None
    ) -> List[CommonExpense]:
        """
        Lista gastos comunes con filtros opcionales.
        Usa índices compuestos de Firestore cuando se combinan filtros con ordenamiento.
        """
        query = self.db.collection('communities').document(community_id)\
            .collection('common_expenses')
        
        # Filtrar por año
        if year:
            query = query.where('year', '==', year)
        
        # Filtrar por mes
        if month:
            query = query.where('month', '==', month)
        
        # Filtrar por estado (usa índice compuesto si se combina con year/month)
        if status:
            query = query.where('status', '==', status)
        
        # Ordenar por período descendente
        query = query.order_by('year', direction=admin_firestore.Query.DESCENDING)\
            .order_by('month', direction=admin_firestore.Query.DESCENDING)
        
        docs = query.stream()
        expenses = []
        
        for doc in docs:
            expense_data = doc.to_dict()
            
            # Convertir items dict a objetos
            if 'items' in expense_data:
                for category, items_list in expense_data['items'].items():
                    expense_data['items'][category] = [
                        ExpenseLineItem(**item) for item in items_list
                    ]
            # Convertir unit_expenses a objetos
            if 'unit_expenses' in expense_data:
                expense_data['unit_expenses'] = [
                    UnitExpense(**ue) for ue in expense_data['unit_expenses']
                ]
            expenses.append(CommonExpense(**expense_data))
        
        return expenses
    
    def get_by_id(self, community_id: str, expense_id: str) -> Optional[CommonExpense]:
        """Obtiene un gasto común por ID"""
        doc_ref = self.db.collection('communities').document(community_id)\
            .collection('common_expenses').document(expense_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return None
        
        expense_data = doc.to_dict()
        
        # Convertir items dict a objetos
        if 'items' in expense_data:
            for category, items_list in expense_data['items'].items():
                expense_data['items'][category] = [
                    ExpenseLineItem(**item) for item in items_list
                ]
        
        # Convertir unit_expenses a objetos
        if 'unit_expenses' in expense_data:
            expense_data['unit_expenses'] = [
                UnitExpense(**ue) for ue in expense_data['unit_expenses']
            ]
        
        return CommonExpense(**expense_data)
    
    def update(
        self,
        community_id: str,
        expense_id: str,
        update_data: CommonExpenseUpdate
    ) -> CommonExpense:
        """
        Actualiza items del gasto común.
        Solo permite actualización si está en estado DRAFT.
        """
        doc_ref = self.db.collection('communities').document(community_id)\
            .collection('common_expenses').document(expense_id)
        
        expense = self.get_by_id(community_id, expense_id)
        if not expense:
            raise ValueError(f"Gasto común {expense_id} no encontrado")
        
        if expense.status != ExpenseStatus.DRAFT:
            raise ValueError("No se puede editar un gasto común que no esté en borrador")
        
        update_dict = update_data.dict(exclude_unset=True)
        update_dict['updated_at'] = datetime.now()
        
        # Convertir objetos Pydantic a dicts para Firestore
        if 'items' in update_dict:
            for category, items_list in update_dict['items'].items():
                update_dict['items'][category] = [
                    item.dict() if hasattr(item, 'dict') else item 
                    for item in items_list
                ]
        
        doc_ref.update(update_dict)
        return self.get_by_id(community_id, expense_id)
    
    def add_line_item(
        self,
        community_id: str,
        expense_id: str,
        category: str,
        item: ExpenseLineItem
    ) -> CommonExpense:
        """Agrega una línea de gasto a una categoría"""
        expense = self.get_by_id(community_id, expense_id)
        if not expense:
            raise ValueError(f"Gasto común {expense_id} no encontrado")
        
        if expense.status != ExpenseStatus.DRAFT:
            raise ValueError("No se pueden agregar items a un gasto cerrado")
        
        if category not in expense.items:
            expense.items[category] = []
        
        expense.items[category].append(item)
        
        return self.update(
            community_id,
            expense_id,
            CommonExpenseUpdate(items=expense.items)
        )
    
    def remove_line_item(
        self,
        community_id: str,
        expense_id: str,
        category: str,
        item_index: int
    ) -> CommonExpense:
        """Elimina una línea de gasto de una categoría"""
        expense = self.get_by_id(community_id, expense_id)
        if not expense:
            raise ValueError(f"Gasto común {expense_id} no encontrado")
        
        if expense.status != ExpenseStatus.DRAFT:
            raise ValueError("No se pueden eliminar items de un gasto cerrado")
        
        if category not in expense.items or item_index >= len(expense.items[category]):
            raise ValueError("Índice de item inválido")
        
        expense.items[category].pop(item_index)
        
        return self.update(
            community_id,
            expense_id,
            CommonExpenseUpdate(items=expense.items)
        )
    
    def import_maintenances(
        self,
        community_id: str,
        expense_id: str,
        year: int,
        month: int
    ) -> CommonExpense:
        """
        Importa mantenimientos del mes seleccionado y los agrupa en la categoría 'mantencion'.
        Agrupa por tipo de mantenimiento y crea una línea por cada agrupación.
        """
        expense = self.get_by_id(community_id, expense_id)
        if not expense:
            raise ValueError(f"Gasto común {expense_id} no encontrado")
        
        if expense.status != ExpenseStatus.DRAFT:
            raise ValueError("No se pueden importar mantenimientos a un gasto cerrado")
        
        # Obtener mantenimientos del mes
        maintenances_ref = self.db.collection('communities').document(community_id)\
            .collection('maintenances')
        
        # Filtrar por fechas del mes
        from datetime import datetime as dt
        start_date = dt(year, month, 1)
        if month == 12:
            end_date = dt(year + 1, 1, 1)
        else:
            end_date = dt(year, month + 1, 1)
        
        query = maintenances_ref\
            .where('scheduled_date', '>=', start_date)\
            .where('scheduled_date', '<', end_date)\
            .where('status', '==', 'completado')
        
        docs = query.stream()
        
        # Agrupar por título base del mantenimiento
        grouped_maintenances = {}
        for doc in docs:
            data = doc.to_dict()
            title = data.get('title', 'Mantenimiento')
            cost = data.get('cost', 0.0)
            
            if title not in grouped_maintenances:
                grouped_maintenances[title] = {
                    'ids': [],
                    'total': 0.0
                }
            
            grouped_maintenances[title]['ids'].append(doc.id)
            grouped_maintenances[title]['total'] += cost
        
        # Crear líneas de gasto agrupadas
        period_str = f"{['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 
                        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][month-1]} {year}"
        
        mantencion_items = []
        for title, data in grouped_maintenances.items():
            item = ExpenseLineItem(
                description=f"{title} {period_str}",
                amount=data['total'],
                maintenance_ids=data['ids']
            )
            mantencion_items.append(item)
        
        # Actualizar categoría mantención
        expense.items['mantencion'] = mantencion_items
        
        return self.update(
            community_id,
            expense_id,
            CommonExpenseUpdate(items=expense.items)
        )
    
    def calculate_unit_expenses(
        self,
        community_id: str,
        expense_id: str
    ) -> CommonExpense:
        """
        Calcula el monto de gasto común para cada unidad según su alícuota.
        También obtiene los datos del residente asociado.
        """
        expense = self.get_by_id(community_id, expense_id)
        if not expense:
            raise ValueError(f"Gasto común {expense_id} no encontrado")
        
        # Calcular total
        total_amount = expense.calculate_total()
        
        # Obtener todas las unidades de la comunidad
        units_ref = self.db.collection('communities').document(community_id)\
            .collection('units')
        units_docs = units_ref.stream()
        
        # Obtener todos los usuarios para mapear residentes
        users_ref = self.db.collection('users')
        users_docs = users_ref.stream()
        
        # Crear mapa de usuarios por UID
        users_map = {}
        for user_doc in users_docs:
            user_data = user_doc.to_dict()
            users_map[user_doc.id] = user_data
        
        unit_expenses = []
        
        for unit_doc in units_docs:
            unit_data = unit_doc.to_dict()
            unit_id = unit_doc.id
            unit_name = unit_data.get('name', '')
            alicuota = unit_data.get('alicuota', 0.0)
            
            # Calcular monto para esta unidad
            unit_amount = total_amount * (alicuota / 100.0)
            
            # Buscar residente asignado
            resident_uid = unit_data.get('resident_uid')
            resident_name = None
            resident_email = None
            
            if resident_uid and resident_uid in users_map:
                user_data = users_map[resident_uid]
                resident_name = user_data.get('name') or f"{user_data.get('first_name', '')} {user_data.get('last_name', '')}".strip()
                resident_email = user_data.get('email')
            
            unit_expense = UnitExpense(
                unit_id=unit_id,
                unit_name=unit_name,
                alicuota=alicuota,
                amount=unit_amount,
                resident_uid=resident_uid,
                resident_name=resident_name,
                resident_email=resident_email
            )
            
            unit_expenses.append(unit_expense)
        
        # Actualizar gasto común
        doc_ref = self.db.collection('communities').document(community_id)\
            .collection('common_expenses').document(expense_id)
        
        doc_ref.update({
            'total_amount': total_amount,
            'unit_expenses': [ue.dict() for ue in unit_expenses],
            'updated_at': datetime.now()
        })
        
        return self.get_by_id(community_id, expense_id)
    
    def close_expense(
        self,
        community_id: str,
        expense_id: str,
        closed_by_uid: str
    ) -> CommonExpense:
        """
        Cierra el período de gasto común.
        Calcula distribución por unidades y cambia estado a CLOSED.
        """
        expense = self.get_by_id(community_id, expense_id)
        if not expense:
            raise ValueError(f"Gasto común {expense_id} no encontrado")
        
        if expense.status != ExpenseStatus.DRAFT:
            raise ValueError("Solo se pueden cerrar gastos en borrador")
        
        # Calcular gastos por unidad
        expense = self.calculate_unit_expenses(community_id, expense_id)
        
        # Cambiar estado a cerrado
        doc_ref = self.db.collection('communities').document(community_id)\
            .collection('common_expenses').document(expense_id)
        
        doc_ref.update({
            'status': ExpenseStatus.CLOSED.value,
            'closed_by': closed_by_uid,
            'closed_at': datetime.now(),
            'updated_at': datetime.now()
        })
        
        return self.get_by_id(community_id, expense_id)
    
    def mark_as_notified(
        self,
        community_id: str,
        expense_id: str
    ) -> CommonExpense:
        """Marca el gasto común como notificado"""
        doc_ref = self.db.collection('communities').document(community_id)\
            .collection('common_expenses').document(expense_id)
        
        doc_ref.update({
            'status': ExpenseStatus.NOTIFIED.value,
            'updated_at': datetime.now()
        })
        
        return self.get_by_id(community_id, expense_id)
    
    def delete(self, community_id: str, expense_id: str) -> None:
        """
        Elimina un gasto común.
        Solo permite eliminar si está en estado DRAFT.
        """
        expense = self.get_by_id(community_id, expense_id)
        if not expense:
            raise ValueError(f"Gasto común {expense_id} no encontrado")
        
        if expense.status != ExpenseStatus.DRAFT:
            raise ValueError("Solo se pueden eliminar gastos en borrador")
        
        doc_ref = self.db.collection('communities').document(community_id)\
            .collection('common_expenses').document(expense_id)
        doc_ref.delete()
    
    def get_resident_expenses(
        self,
        resident_uid: str,
        community_id: str,
        limit_years: int = 2
    ) -> List[dict]:
        """
        Obtiene los gastos comunes de un residente para los últimos N años.
        Retorna una lista filtrada con solo la info de las unidades del residente.
        Usa índices compuestos de Firestore para optimizar la consulta.
        SOLO muestra gastos NOTIFIED (cerrados pero no notificados permanecen ocultos).
        """
        from datetime import datetime as dt
        current_year = dt.now().year
        start_year = current_year - limit_years
        
        # Obtener gastos comunes usando índices compuestos de Firestore
        # SOLO mostrar gastos NOTIFIED (cerrados pero no notificados deben estar ocultos)
        query = self.db.collection('communities').document(community_id)\
            .collection('common_expenses')\
            .where('year', '>=', start_year)\
            .where('status', '==', ExpenseStatus.NOTIFIED.value)\
            .order_by('year', direction=admin_firestore.Query.DESCENDING)\
            .order_by('month', direction=admin_firestore.Query.DESCENDING)
        
        docs = query.stream()
        
        resident_expenses = []
        
        for doc in docs:
            expense_data = doc.to_dict()
            
            # Filtrar unit_expenses para solo incluir las del residente
            unit_expenses = expense_data.get('unit_expenses', [])
            resident_units = [
                ue for ue in unit_expenses 
                if ue.get('resident_uid') == resident_uid
            ]
            
            if resident_units:
                # Crear datos resumidos para el residente
                total_resident = sum(ue.get('amount', 0.0) for ue in resident_units)
                
                # Serializar closed_at si existe
                closed_at = expense_data.get('closed_at')
                if closed_at and hasattr(closed_at, 'isoformat'):
                    closed_at = closed_at.isoformat()
                elif closed_at:
                    closed_at = str(closed_at)
                
                resident_expense = {
                    'id': expense_data.get('id'),
                    'period': expense_data.get('period'),
                    'month': expense_data.get('month'),
                    'year': expense_data.get('year'),
                    'status': expense_data.get('status'),
                    'closed_at': closed_at,
                    'total_amount': total_resident,
                    'my_units': resident_units
                }
                
                resident_expenses.append(resident_expense)
        
        return resident_expenses

