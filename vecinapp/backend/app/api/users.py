from fastapi import APIRouter, HTTPException, status, Depends
from typing import List
from app.schemas.user import User, UserCreate
from app.repositories.user_repo import UserRepository
from app.core.security import get_current_user

router = APIRouter()
repo = UserRepository()

@router.post("/", response_model=User, status_code=status.HTTP_201_CREATED)
def create_user(
    user: UserCreate, 
    current_user: dict = Depends(get_current_user)
):
    """
    Registra un nuevo usuario en el sistema (Auth + Firestore).
    """
    try:
        return repo.create(user)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.get("/", response_model=List[User])
def list_users(
    current_user: dict = Depends(get_current_user)
):
    """
    Lista todos los usuarios registrados.
    """
    return repo.get_all()

@router.get("/{user_id}", response_model=User)
def get_user(
    user_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene el detalle de un usuario específico.
    """
    user = repo.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Usuario no encontrado"
        )
    return user
