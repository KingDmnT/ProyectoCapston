"""
Servicio para envío de emails con PDFs de gastos comunes
"""
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from email.mime.image import MIMEImage
from pathlib import Path
import os
from dotenv import load_dotenv

load_dotenv()

# Configuración SMTP (desde variables de entorno)
SMTP_HOST = os.getenv('SMTP_HOST', 'smtp.gmail.com')
SMTP_PORT = int(os.getenv('SMTP_PORT', '587'))
SMTP_USER = os.getenv('SMTP_USER', '')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD', '')
FROM_EMAIL = os.getenv('FROM_EMAIL', SMTP_USER)
FROM_NAME = os.getenv('FROM_NAME', 'VecinApp - Gastos Comunes')

def send_common_expense_email(
    to_email: str,
    to_name: str,
    community_name: str,
    period: str,
    amount: float,
    pdf_path: str,
    unit_numbers: list = None
) -> bool:
    """
    Envía email con PDF de gasto común adjunto.
    
    Args:
        to_email: Email del destinatario
        to_name: Nombre del destinatario
        community_name: Nombre de la comunidad
        period: Período del gasto (ej: "diciembre 2025")
        amount: Monto a pagar
        pdf_path: Ruta del PDF a adjuntar
        unit_numbers: Lista de números de unidad (ej: ["101", "205"])
    
    Returns:
        True si se envió exitosamente, False en caso contrario
    """
    if not SMTP_USER or not SMTP_PASSWORD:
        print("⚠️  Advertencia: SMTP no configurado. Email no enviado.")
        print(f"   Para: {to_email}, Monto: ${amount:,.0f}")
        return False
    
    try:
        # Crear mensaje
        msg = MIMEMultipart('related')
        msg['From'] = f'{FROM_NAME} <{FROM_EMAIL}>'
        msg['To'] = to_email
        msg['Subject'] = f'Gasto Común {period} - {community_name}'
        
        # Formatear números de unidad
        units_text = ""
        if unit_numbers and len(unit_numbers) > 0:
            if len(unit_numbers) == 1:
                units_text = f"<p style=\"color: #666;\"><strong>Unidad:</strong> {unit_numbers[0]}</p>"
            else:
                units_list = ", ".join(unit_numbers)
                units_text = f"<p style=\"color: #666;\"><strong>Unidades:</strong> {units_list}</p>"
        
        # Cuerpo del email en HTML
        html_body = f"""
        <html>
          <body style="font-family: Arial, sans-serif; color: #333; background-color: #f9f9f9; margin: 0; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
              
              <!-- Header con logo -->
              <div style="background: linear-gradient(135deg, #7B4FFF 0%, #6A3DE8 100%); padding: 30px; text-align: center;">
                <!-- Círculo blanco detrás del logo -->
                    <img src="cid:logo" alt="VecinApp" style="height: 80px; width: 80px; object-fit: contain;" />
                <h1 style="color: white; margin: 10px 0 0 0; font-size: 24px;">Gasto Común {period}</h1>
              </div>
              
              <!-- Contenido -->
              <div style="padding: 30px;">
                <p style="font-size: 16px;">Estimado/a <strong>{to_name}</strong>,</p>
                
                {units_text}
                
                <p>Adjunto encontrará la liquidación de su gasto común correspondiente al período de <strong>{period}</strong>.</p>
                
                <div style="background-color: #f5f5f5; padding: 20px; border-left: 4px solid #7B4FFF; margin: 25px 0; border-radius: 4px;">
                  <p style="margin: 0; font-size: 14px; color: #666;"><strong>Monto a pagar:</strong></p>
                  <p style="margin: 5px 0 0 0; font-size: 32px; color: #7B4FFF; font-weight: bold;">
                    $ {amount:,.0f}
                  </p>
                </div>
                
                <p style="font-size: 15px; margin-top: 25px;"><strong>📄 En el documento adjunto encontrará:</strong></p>
                <ul style="line-height: 1.8; color: #555;">
                  <li>Detalle de los cobros de su(s) unidad(es)</li>
                  <li>Información bancaria para realizar el pago</li>
                  <li>Detalle completo de los egresos de la comunidad</li>
                </ul>
                
                <p style="margin-top: 25px;">Si tiene alguna consulta, no dude en contactarnos.</p>
                
                <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 30px 0;" />
                
                <p style="font-size: 12px; color: #999; text-align: center;">
                  <strong style="color: #666;">{community_name}</strong><br/>
                  Este es un correo automático generado por VecinApp.<br/>
                  Por favor no responder a este mensaje.
                </p>
              </div>
              
            </div>
          </body>
        </html>
        """
        
        msg.attach(MIMEText(html_body, 'html'))
        
        # Adjuntar logo embebido
        logo_paths = [
            Path('/app/frontend/assets/images/LogoBcoSinFondo.png'),
            Path('/app/frontend/assets/LogoBcoSinFondo.png'),
            Path(__file__).parent.parent.parent.parent / 'frontend' / 'assets' / 'images' / 'LogoBcoSinFondo.png',
        ]
        
        logo_attached = False
        for logo_path in logo_paths:
            if logo_path.exists():
                try:
                    with open(logo_path, 'rb') as logo_file:
                        logo_image = MIMEImage(logo_file.read())
                        logo_image.add_header('Content-ID', '<logo>')
                        logo_image.add_header('Content-Disposition', 'inline', filename='LogoBcoSinFondo.png')
                        msg.attach(logo_image)
                        logo_attached = True
                        break
                except Exception as e:
                    print(f"⚠️  Error al adjuntar logo: {e}")
        
        if not logo_attached:
            print("⚠️  Logo no encontrado, email enviado sin logo")
        
        # Adjuntar PDF
        if Path(pdf_path).exists():
            with open(pdf_path, 'rb') as pdf_file:
                pdf_attachment = MIMEApplication(pdf_file.read(), _subtype='pdf')
                pdf_attachment.add_header(
                    'Content-Disposition',
                    'attachment',
                    filename=f'GastoComun_{period.replace(" ", "_")}.pdf'
                )
                msg.attach(pdf_attachment)
        else:
            print(f"⚠️  Advertencia: PDF no encontrado en {pdf_path}")
            return False
        
        # Enviar email
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(msg)
        
        print(f"✅ Email enviado a {to_email}")
        return True
        
    except Exception as e:
        print(f"❌ Error enviando email a {to_email}: {str(e)}")
        return False

def send_bulk_common_expense_emails(recipients: list) -> dict:
    """
    Envía emails masivos a múltiples destinatarios.
    
    Args:
        recipients: Lista de diccionarios con datos de destinatarios:
            - to_email
            - to_name
            - community_name
            - period
            - amount
            - pdf_path
    
    Returns:
        Dict con estadísticas: {sent: int, failed: int, total: int}
    """
    results = {
        'sent': 0,
        'failed': 0,
        'total': len(recipients)
    }
    
    for recipient in recipients:
        success = send_common_expense_email(**recipient)
        if success:
            results['sent'] += 1
        else:
            results['failed'] += 1
    
    return results
