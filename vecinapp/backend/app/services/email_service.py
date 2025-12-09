"""
Servicio para envío de emails con PDFs de gastos comunes
"""
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
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
    pdf_path: str
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
    
    Returns:
        True si se envió exitosamente, False en caso contrario
    """
    if not SMTP_USER or not SMTP_PASSWORD:
        print("⚠️  Advertencia: SMTP no configurado. Email no enviado.")
        print(f"   Para: {to_email}, Monto: ${amount:,.0f}")
        return False
    
    try:
        # Crear mensaje
        msg = MIMEMultipart()
        msg['From'] = f'{FROM_NAME} <{FROM_EMAIL}>'
        msg['To'] = to_email
        msg['Subject'] = f'Gasto Común {period} - {community_name}'
        
        # Cuerpo del email en HTML
        html_body = f"""
        <html>
          <body style="font-family: Arial, sans-serif; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
              <h2 style="color: #4ECDC4;">Gasto Común {period}</h2>
              
              <p>Estimado/a <strong>{to_name}</strong>,</p>
              
              <p>Adjunto encontrará la liquidación de su gasto común correspondiente al período de <strong>{period}</strong>.</p>
              
              <div style="background-color: #f5f5f5; padding: 15px; border-left: 4px solid #4ECDC4; margin: 20px 0;">
                <p style="margin: 0; font-size: 14px;"><strong>Monto a pagar:</strong></p>
                <p style="margin: 5px 0 0 0; font-size: 24px; color: #4ECDC4; font-weight: bold;">
                  $ {amount:,.0f}
                </p>
              </div>
              
              <p>En el documento adjunto encontrará:</p>
              <ul>
                <li>Detalle de los cobros de su unidad</li>
                <li>Información bancaria para realizar el pago</li>
                <li>Detalle completo de los egresos de la comunidad</li>
              </ul>
              
              <p>Si tiene alguna consulta, no dude en contactarnos.</p>
              
              <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;" />
              
              <p style="font-size: 12px; color: #666;">
                <strong>{community_name}</strong><br/>
                Este es un correo automático generado por VecinApp. Por favor no responder a este mensaje.
              </p>
            </div>
          </body>
        </html>
        """
        
        msg.attach(MIMEText(html_body, 'html'))
        
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
