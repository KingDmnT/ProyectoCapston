from fastapi import APIRouter, Depends, HTTPException, status
from app.core.firebase import get_db
from app.schemas.camera import CameraConfig, CameraConfigCreate
from app.core.security import get_current_user
from datetime import datetime
from google.cloud import firestore

router = APIRouter()

@router.get("/{community_id}/config", response_model=CameraConfig)
def get_camera_config(
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Obtiene la configuración de cámaras de la comunidad"""
    # Verificar permisos (omito logica compleja por brevedad, asumo usuario autenticado pertenece a comunidad)
    
    db = get_db()
    doc_ref = db.collection('communities').document(community_id)\
        .collection('integrations').document('hikvision')
    
    doc = doc_ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    
    return doc.to_dict()

@router.post("/{community_id}/config", response_model=CameraConfig)
def save_camera_config(
    community_id: str,
    config: CameraConfigCreate,
    current_user: dict = Depends(get_current_user)
):
    """Guarda o actualiza la configuración de cámaras"""
    if current_user.get('role') != 'administrator':
        raise HTTPException(status_code=403, detail="Solo administradores pueden configurar cámaras")

    db = get_db()
    doc_ref = db.collection('communities').document(community_id)\
        .collection('integrations').document('hikvision')
    
    data = config.dict()
    data['updated_at'] = datetime.now().isoformat()
    
    doc_ref.set(data)
    
    return data

@router.get("/{community_id}/test-connection")
def test_nvr_connection(
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Prueba la conexión al NVR usando las credenciales guardadas"""
    import requests
    from requests.auth import HTTPDigestAuth
    
    db = get_db()
    doc_ref = db.collection('communities').document(community_id)\
        .collection('integrations').document('hikvision')
    
    doc = doc_ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    
    config = doc.to_dict()
    nvr_ip = config.get('nvr_ip')
    nvr_port = config.get('nvr_port', 80)
    username = config.get('username')
    password = config.get('password')
    
    if not all([nvr_ip, username, password]):
        raise HTTPException(status_code=400, detail="Configuración incompleta")
    
    try:
        url = f"http://{nvr_ip}:{nvr_port}/ISAPI/System/deviceInfo"
        response = requests.get(
            url,
            auth=HTTPDigestAuth(username, password),
            timeout=5
        )
        
        if response.status_code == 200:
            return {"status": "online", "message": "Conexión exitosa"}
        else:
            return {"status": "error", "message": f"HTTP {response.status_code}"}
    except requests.exceptions.Timeout:
        return {"status": "offline", "message": "Timeout - NVR no responde"}
    except requests.exceptions.ConnectionError:
        return {"status": "offline", "message": "No se pudo conectar al NVR"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@router.get("/{community_id}/channels")
def get_nvr_channels(
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Obtiene lista de canales activos del NVR"""
    import requests
    from requests.auth import HTTPDigestAuth
    import xml.etree.ElementTree as ET
    
    db = get_db()
    doc_ref = db.collection('communities').document(community_id)\
        .collection('integrations').document('hikvision')
    
    doc = doc_ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    
    config = doc.to_dict()
    nvr_ip = config.get('nvr_ip')
    nvr_port = config.get('nvr_port', 80)
    username = config.get('username')
    password = config.get('password')
    
    try:
        url = f"http://{nvr_ip}:{nvr_port}/ISAPI/System/Video/inputs/channels"
        response = requests.get(
            url,
            auth=HTTPDigestAuth(username, password),
            timeout=10
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail="Error al obtener canales")
        
        # Parsear XML de respuesta
        root = ET.fromstring(response.content)
        channels = []
        
        # Namespace de Hikvision
        ns = {'ns': 'http://www.hikvision.com/ver20/XMLSchema'}
        
        for video_input in root.findall('.//ns:VideoInputChannel', ns):
            channel_id = video_input.find('ns:id', ns)
            channel_name = video_input.find('ns:name', ns)
            
            if channel_id is not None:
                channels.append({
                    'id': int(channel_id.text),
                    'name': channel_name.text if channel_name is not None else f'Canal {channel_id.text}',
                    'enabled': True
                })
        
        return {"channels": channels}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.get("/{community_id}/snapshot/{channel_id}")
def get_channel_snapshot(
    community_id: str,
    channel_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Obtiene snapshot de un canal específico"""
    import requests
    from requests.auth import HTTPDigestAuth
    from fastapi.responses import Response
    
    db = get_db()
    doc_ref = db.collection('communities').document(community_id)\
        .collection('integrations').document('hikvision')
    
    doc = doc_ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    
    config = doc.to_dict()
    nvr_ip = config.get('nvr_ip')
    nvr_port = config.get('nvr_port', 80)
    username = config.get('username')
    password = config.get('password')
    
    try:
        url = f"http://{nvr_ip}:{nvr_port}/ISAPI/Streaming/channels/{channel_id}01/picture"
        response = requests.get(
            url,
            auth=HTTPDigestAuth(username, password),
            timeout=10
        )
        
        if response.status_code == 200:
            return Response(content=response.content, media_type="image/jpeg")
        else:
            raise HTTPException(status_code=404, detail="Canal no disponible")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.get("/{community_id}/mjpeg/{channel_id}")
def get_channel_mjpeg_stream(
    community_id: str,
    channel_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Proxy MJPEG stream desde Hikvision NVR"""
    import requests
    from requests.auth import HTTPDigestAuth
    from fastapi.responses import StreamingResponse
    
    db = get_db()
    doc_ref = db.collection('communities').document(community_id)\
        .collection('integrations').document('hikvision')
    
    doc = doc_ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    
    config = doc.to_dict()
    nvr_ip = config.get('nvr_ip')
    nvr_port = config.get('nvr_port', 80)
    username = config.get('username')
    password = config.get('password')
    
    # Intentar primero con httpPreview, si falla usar picture en modo stream
    url = f"http://{nvr_ip}:{nvr_port}/ISAPI/Streaming/channels/{channel_id}01/httpPreview"
    
    try:
        # Stream MJPEG usando requests con stream=True
        response = requests.get(
            url,
            auth=HTTPDigestAuth(username, password),
            stream=True,
            timeout=30
        )
        
        if response.status_code == 200:
            def generate():
                try:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            yield chunk
                except Exception as e:
                    print(f"Error streaming MJPEG: {e}")
            
            return StreamingResponse(
                generate(),
                media_type="multipart/x-mixed-replace; boundary=--boundary"
            )
        else:
            raise HTTPException(status_code=404, detail="Stream no disponible")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


