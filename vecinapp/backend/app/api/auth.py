from fastapi import APIRouter, Depends
from app.core.security import get_current_user

router = APIRouter()

@router.get("/me")
def read_users_me(current_user: dict = Depends(get_current_user)):
    """
    Endpoint protegido de prueba.
    Devuelve la información del usuario extraída del token de Firebase.
    """
    return {
        "uid": current_user.get("uid"),
        "email": current_user.get("email"),
        "provider": current_user.get("firebase", {}).get("sign_in_provider"),
        "message": "¡Estás autenticado correctamente!"
    }
