from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
from app.core.firebase import get_db

# Esquema de seguridad: Bearer Token
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Valida el token de Firebase (JWT) recibido en el encabezado Authorization.
    Luego obtiene los datos completos del usuario desde Firestore.
    
    Retorna:
        dict: Datos completos del usuario desde Firestore (uid, email, role, memberships, etc.)
    
    Lanza:
        HTTPException: Si el token es inválido, expirado o el usuario no existe en Firestore.
    """
    token = credentials.credentials
    try:
       
 # Verificar el token con Firebase Admin SDK
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
        
        # Obtener cliente de Firestore
        db = get_db()
        
        # Obtener datos completos del usuario desde Firestore
        user_ref = db.collection('users').document(uid)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado en la base de datos"
            )
        
        user_data = user_doc.to_dict()
        user_data['uid'] = uid
        user_data['id'] = uid  # Ensure ID is always set
        
        return user_data
        
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El token ha expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except HTTPException:
        # Re-raise HTTPExceptions (como el 404)
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Error de autenticación: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )
