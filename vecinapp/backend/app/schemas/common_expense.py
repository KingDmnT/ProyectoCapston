from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from enum import Enum
from datetime import datetime

# Enums
class ExpenseStatus(str, Enum):
    """Estados del gasto común"""
    DRAFT = "draft"  # Borrador (en edición)
    CLOSED = "closed"  # Cerrado (calculado, no editable)
    NOTIFIED = "notified"  # Notificado (emails enviados)

class ExpenseCategory(str, Enum):
    """Categorías de gastos"""
    REMUNERACIONES = "remuneraciones"  # Sueldos y honorarios
    GASTOS_EXTRAORDINARIOS = "gastos_extraordinarios"  # Reparaciones, adquisiciones
    MANTENCION = "mantencion"  # Mantenciones preventivas y correctivas
    SERVICIOS_COMUNES = "servicios_comunes"  # Electricidad, agua, gas

# Sub-modelos
class ExpenseLineItem(BaseModel):
    """Línea individual de gasto"""
    description: str  # Ej: "Sueldo Conserje", "Electricidad"
    amount: float  # Monto en pesos
    doc_number: Optional[str] = None  # Número de documento/factura
    date: Optional[datetime] = None  # Fecha del documento
    maintenance_ids: Optional[List[str]] = None  # IDs de mantenimientos relacionados (para categoría mantención)

class UnitExpense(BaseModel):
    """Gasto calculado para una unidad específica"""
    unit_id: str
    unit_name: str  # Ej: "101"
    alicuota: float  # Porcentaje (ej: 4.17)
    amount: float  # Monto calculado (total × alícuota / 100)
    resident_uid: Optional[str] = None  # UID del residente
    resident_name: Optional[str] = None  # Nombre del residente
    resident_email: Optional[str] = None  # Email del residente
    pdf_url: Optional[str] = None  # URL del PDF generado
    is_paid: bool = False  # Estado de pago
    payment_date: Optional[datetime] = None  # Fecha de pago

# Schemas principales
class CommonExpenseBase(BaseModel):
    """Campos base del gasto común"""
    community_id: str
    period: str  # Formato: "2025-12" (año-mes)
    month: int  # 1-12
    year: int  # 2025
    
    # Items agrupados por categoría
    items: Dict[str, List[ExpenseLineItem]] = Field(default_factory=lambda: {
        "remuneraciones": [],
        "gastos_extraordinarios": [],
        "mantencion": [],
        "servicios_comunes": []
    })

class CommonExpenseCreate(CommonExpenseBase):
    """Schema para creación de gasto común"""
    pass

class CommonExpenseUpdate(BaseModel):
    """Schema para actualización de gasto común"""
    items: Optional[Dict[str, List[ExpenseLineItem]]] = None

class CommonExpense(CommonExpenseBase):
    """Modelo completo de gasto común"""
    id: str
    status: ExpenseStatus = ExpenseStatus.DRAFT
    total_amount: float = 0.0  # Total de todos los gastos
    
    # Metadatos
    closed_by: Optional[str] = None  # UID del admin que cerró
    closed_at: Optional[datetime] = None
    created_by: str  # UID del admin que creó
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    
    # Distribución por unidades (se calcula al cerrar)
    unit_expenses: List[UnitExpense] = Field(default_factory=list)
    
    class Config:
        from_attributes = True
    
    def calculate_total(self) -> float:
        """Calcula el total de todos los items"""
        total = 0.0
        for category_items in self.items.values():
            for item in category_items:
                total += item.amount
        return total
    
    def get_category_total(self, category: str) -> float:
        """Calcula el total de una categoría específica"""
        return sum(item.amount for item in self.items.get(category, []))
