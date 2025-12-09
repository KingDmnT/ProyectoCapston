"""
Generador de PDFs para Gastos Comunes
Genera PDFs profesionales de 3 páginas con formato ComunidadFeliz
"""
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.pdfgen import canvas
import qrcode
from io import BytesIO
from datetime import datetime
from pathlib import Path

# Colores del tema (basados en Logo.png - paleta azul/gris profesional)
COLOR_PRIMARY = colors.HexColor('#2C5F8D')  # Azul corporativo del logo
COLOR_SECONDARY = colors.HexColor('#5A8AB4')  # Azul claro del logo
COLOR_TEXT = colors.HexColor('#333333')
COLOR_LIGHT_GRAY = colors.HexColor('#F5F5F5')
COLOR_TABLE_HEADER = colors.HexColor('#3D6F99')  # Azul intermedio para headers

def generate_common_expense_pdf(
    expense_data: dict,
    unit_expense: dict,
    community_data: dict,
    output_path: str
) -> str:
    """
    Genera PDF de gasto común para una unidad específica.
    
    Args:
        expense_data: Datos del gasto común completo
        unit_expense: Datos del gasto de la unidad específica
        community_data: Datos de la comunidad
        output_path: Ruta donde guardar el PDF
    
    Returns:
        Ruta del archivo generado
    """
    # Crear documento
    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        rightMargin=0.5*inch,
        leftMargin=0.5*inch,
        topMargin=0.5*inch,
        bottomMargin=0.5*inch
    )
    
    # Contenedor de elementos
    elements = []
    
    # Estilos
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=COLOR_TEXT,
        spaceAfter=12,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=12,
        textColor=colors.white,
        backColor=COLOR_PRIMARY,
        spaceAfter=6,
        spaceBefore=12,
        leftIndent=6,
        fontName='Helvetica-Bold'
    )
    
    # ===========================
    # PÁGINA 1: LIQUIDACIÓN INDIVIDUAL
    # ===========================
    
    # Logo (si existe)
    # Intentar varias rutas posibles para el logo
    logo_paths = [
        # Ruta para Docker (volumen montado en /app/frontend/assets)
        Path('/app/frontend/assets/images/Logo.png'),
        Path('/app/frontend/assets/Logo.png'),
        # Rutas relativas para desarrollo local
        Path(__file__).parent.parent.parent.parent / 'frontend' / 'assets' / 'images' / 'Logo.png',
        Path(__file__).parent.parent.parent.parent / 'frontend' / 'assets' / 'Logo.png',
        Path(__file__).parent.parent / 'static' / 'Logo.png',
    ]
    
    logo_loaded = False
    for logo_path in logo_paths:
        if logo_path.exists():
            try:
                logo = Image(str(logo_path), width=1.5*inch, height=1.5*inch, kind='proportional')
                logo.hAlign = 'CENTER'
                elements.append(logo)
                logo_loaded = True
                print(f'Logo cargado desde: {logo_path}')
                break
            except Exception as e:
                print(f'Error cargando logo desde {logo_path}: {e}')
                continue
    
    if not logo_loaded:
        print('Advertencia: No se pudo cargar el logo corporativo')
        # Añadir un título como fallback
        fallback_title = Paragraph(f"\u003cb\u003e{community_data.get('name', 'COMUNIDAD')}\u003c/b\u003e", 
                                   ParagraphStyle('LogoFallback', parent=styles['Heading1'], 
                                                fontSize=16, textColor=COLOR_PRIMARY, alignment=TA_CENTER))
        elements.append(fallback_title)
    
    elements.append(Spacer(1, 0.2*inch))
    
    # Título
    elements.append(Paragraph("LIQUIDACIÓN DE GASTOS COMUNES", title_style))
    elements.append(Spacer(1, 0.1*inch))
    
    # Datos de la comunidad
    community_name = community_data.get('name', 'Comunidad')
    community_address = community_data.get('address', '')
    community_rut = community_data.get('rut', 'N/A')
    
    community_info = f"<b>{community_name}</b><br/>{community_address}<br/>RUT: {community_rut}"
    elements.append(Paragraph(community_info, styles['Normal']))
    elements.append(Spacer(1, 0.2*inch))
    
    # Tabla de información de unidad y fechas
    period = expense_data.get('period', '')
    month_names = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                   'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre']
    month = expense_data.get('month', 1)
    year = expense_data.get('year', 2025)
    period_str = f"{month_names[month-1]} - {year}"
    
    # Calcular fecha de vencimiento (asumiendo 28 del mes siguiente)
    if month == 12:
        venc_month = 1
        venc_year = year + 1
    else:
        venc_month = month + 1
        venc_year = year
    vencimiento = f"28/{venc_month:02d}/{venc_year}"
    
    info_data = [
        ['Unidad', f": {unit_expense.get('unit_name', 'N/A')}", 'Vencimiento', f": {vencimiento}"],
        ['Residente', f": {unit_expense.get('resident_name', 'N/A')}", 'Mes de cobro', f": {period_str}"],
        ['Prorrateo', f": {unit_expense.get('alicuota', 0):.2f}%", '', ''],
    ]
    
    info_table = Table(info_data, colWidths=[1.5*inch, 2*inch, 1.8*inch, 1.5*inch])
    info_table.setStyle(TableStyle([
        ('FONT', (0, 0), (-1, -1), 'Helvetica', 9),
        ('FONT', (0, 0), (0, -1), 'Helvetica-Bold', 9),
        ('FONT', (2, 0), (2, -1), 'Helvetica-Bold', 9),
        ('TEXTCOLOR', (0, 0), (-1, -1), COLOR_TEXT),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    
    elements.append(info_table)
    elements.append(Spacer(1, 0.3*inch))
    
    # Detalle del gasto común
    elements.append(Paragraph("Detalle de su gasto común", heading_style))
    elements.append(Spacer(1, 0.1*inch))
    
    # Calcular montos
    total_expense = expense_data.get('total_amount', 0)
    alicuota = unit_expense.get('alicuota', 0)
    unit_amount = unit_expense.get('amount', 0)
    
    # Tabla de cobros
    cobros_data = [
        ['Cobros del período', ''],
        [f'Gasto común ({alicuota:.4f}%)', f'$ {unit_amount:,.0f}'],
    ]
    
    cobros_table = Table(cobros_data, colWidths=[5*inch, 1.5*inch])
    cobros_table.setStyle(TableStyle([
        ('FONT', (0, 0), (-1, 0), 'Helvetica-Bold', 10),
        ('FONT', (0, 1), (0, -1), 'Helvetica', 9),
        ('FONT', (1, 0), (1, -1), 'Helvetica', 9),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ('TEXTCOLOR', (0, 0), (-1, -1), COLOR_TEXT),
        ('LINEBELOW', (0, 0), (-1, 0), 1, COLOR_TEXT),
    ]))
    
    elements.append(cobros_table)
    elements.append(Spacer(1, 0.2*inch))
    
    # Total a pagar destacado
    total_data = [
        ['Total a pagar', f'$ {unit_amount:,.0f}']
    ]
    
    total_table = Table(total_data, colWidths=[5*inch, 1.5*inch])
    total_table.setStyle(TableStyle([
        ('FONT', (0, 0), (-1, -1), 'Helvetica-Bold', 14),
        ('BACKGROUND', (0, 0), (-1, -1), COLOR_PRIMARY),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.white),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 12),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
    ]))
    
    elements.append(total_table)
    elements.append(Spacer(1, 0.3*inch))
    
    # Observaciones de la administración
    elements.append(Paragraph("Observaciones de la administración", heading_style))
    elements.append(Spacer(1, 0.1*inch))
    
    # Obtener datos bancarios de la comunidad
    bank_name = community_data.get('bank_name', '[Nombre del Banco]')
    bank_account_type = community_data.get('bank_account_type', 'Cuenta Corriente')
    bank_account_number = community_data.get('bank_account_number', '[Número de cuenta]')
    bank_account_rut = community_data.get('bank_account_rut', community_rut)
    bank_account_email = community_data.get('bank_account_email', community_data.get('contact_email', '[email de la comunidad]'))
    
    obs_text = f"""
    <b>Para pagar vía transferencia electrónica los datos son:</b><br/>
    Banco: {bank_name}<br/>
    {bank_account_type}: {bank_account_number}<br/>
    Nombre: {community_name}<br/>
    RUT: {bank_account_rut}<br/>
    Correo: {bank_account_email}<br/><br/>
    <b>Enviar el comprobante de transferencia indicando el n° de la unidad.</b><br/>
    Puedes pagar este gasto común hasta el día {vencimiento}
    """
    
    elements.append(Paragraph(obs_text, styles['Normal']))
    
    # ===========================
    # PÁGINA 2-3: EGRESOS DE LA COMUNIDAD
    # ===========================
    
    elements.append(PageBreak())
    
    # Logo en página de egresos también
    if logo_loaded:
        try:
            for logo_path in logo_paths:
                if logo_path.exists():
                    logo2 = Image(str(logo_path), width=1.2*inch, height=1.2*inch, kind='proportional')
                    logo2.hAlign = 'CENTER'
                    elements.append(logo2)
                    elements.append(Spacer(1, 0.15*inch))
                    break
        except Exception as e:
            print(f'Error agregando logo en página de egresos: {e}')

    
    # Título de egresos
    elements.append(Paragraph(f"Egresos gasto común de la comunidad", heading_style))
    total_label = Paragraph(f"<b>$ {total_expense:,.0f}</b>", 
                           ParagraphStyle('TotalRight', parent=styles['Normal'], 
                                        fontSize=14, alignment=TA_RIGHT, textColor=COLOR_PRIMARY))
    
    header_table = Table([[Paragraph("Egresos gasto común de la comunidad", heading_style), total_label]], 
                         colWidths=[5*inch, 1.5*inch])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    elements.append(header_table)
    elements.append(Spacer(1, 0.2*inch))
    
    # Obtener items por categoría
    items = expense_data.get('items', {})
    
    # Categorías a mostrar
    categories = {
        'remuneraciones': 'Administración',
        'gastos_extraordinarios': 'Gastos extraordinarios',
        'mantencion': 'Mantención',
        'servicios_comunes': 'Uso o consumo'
    }
    
    # Generar tabla de egresos
    egresos_data = [
        [Paragraph('<b>Concepto</b>', styles['Normal']), 
         Paragraph('<b>Descripción</b>', styles['Normal']),
         Paragraph('<b>N° Doc</b>', styles['Normal']),
         Paragraph('<b>Fecha</b>', styles['Normal']),
         Paragraph('<b>Monto</b>', styles['Normal'])]
    ]
    
    row_count = 1
    for cat_key, cat_name in categories.items():
        cat_items = items.get(cat_key, [])
        
        if cat_items:
            # Header de categoría con total alineado correctamente
            category_total = sum(item.get('amount', 0) for item in cat_items)
            cat_header = [
                Paragraph(f'<b>{cat_name}</b>', styles['Normal']),
                '', '', '',
                f'$ {category_total:,.0f}'  # String directo sin Paragraph para alineación correcta
            ]
            egresos_data.append(cat_header)
            row_count += 1
            
            # Items de la categoría
            for idx, item in enumerate(cat_items, 1):
                desc = item.get('description', '')
                amount = item.get('amount', 0)
                doc_num = item.get('doc_number', '')
                date = item.get('date', '')
                if date:
                    try:
                        if isinstance(date, str):
                            date_obj = datetime.fromisoformat(date.replace('Z', '+00:00'))
                        else:
                            date_obj = date
                        date_str = date_obj.strftime('%d-%m-%Y')
                    except:
                        date_str = ''
                else:
                    date_str = ''
                
                row_data = [
                    str(idx),
                    Paragraph(desc, styles['Normal']),
                    doc_num,
                    date_str,
                    Paragraph(f'$ {amount:,.0f}', 
                             ParagraphStyle('Right', parent=styles['Normal'], alignment=TA_RIGHT))
                ]
                egresos_data.append(row_data)
                row_count += 1
    
    # Total general
    egresos_data.append([
        Paragraph('<b>Total</b>', styles['Normal']),
        '', '', '',
        Paragraph(f'<b>$ {total_expense:,.0f}</b>',
                 ParagraphStyle('Right', parent=styles['Normal'], alignment=TA_RIGHT))
    ])
    
    # Crear tabla de egresos con anchos optimizados
    # [Concepto, Descripción, N° Doc, Fecha, Monto]
    egresos_table = Table(egresos_data, colWidths=[1.2*inch, 2.5*inch, 0.9*inch, 1*inch, 1.0*inch])
    
    # Estilos de la tabla
    table_style = [
        # Header
        ('BACKGROUND', (0, 0), (-1, 0), COLOR_TABLE_HEADER),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONT', (0, 0), (-1, 0), 'Helvetica-Bold', 9),
        ('ALIGN', (4, 0), (4, -1), 'RIGHT'),
        ('TOPPADDING', (0, 0), (-1, 0), 8),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        
        # General
        ('FONT', (0, 1), (-1, -1), 'Helvetica', 8),
        ('FONT', (0, 1), (0, -1), 'Helvetica-Bold', 8),  # Primera columna en bold para categorías
        ('TEXTCOLOR', (0, 1), (-1, -1), COLOR_TEXT),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 1), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        
        # Total row
        ('BACKGROUND', (0, -1), (-1, -1), COLOR_LIGHT_GRAY),
        ('FONT', (0, -1), (-1, -1), 'Helvetica-Bold', 10),
        ('TOPPADDING', (0, -1), (-1, -1), 10),
        ('BOTTOMPADDING', (0, -1), (-1, -1), 10),
    ]
    
    # Alternar colores de filas
    for i in range(1, len(egresos_data) - 1):
        if i % 2 == 0:
            table_style.append(('BACKGROUND', (0, i), (-1, i), colors.HexColor('#FAFAFA')))
    
    egresos_table.setStyle(TableStyle(table_style))
    elements.append(egresos_table)
    
    # Construir PDF
    doc.build(elements)
    
    return output_path
