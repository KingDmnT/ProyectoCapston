from fastapi import APIRouter, HTTPException, status, Depends
from typing import List, Optional
from app.schemas.user import User, UserCreate, UserUpdate, UserAssignUnit
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
    Solo administradores pueden crear usuarios.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden crear usuarios"
        )
    
    try:
        return repo.create(user)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.get("/", response_model=List[User])
def list_users(
    community_id: Optional[str] = None,
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Lista todos los usuarios registrados.
    Puede filtrar por community_id, rol y estado activo.
    """
    return repo.get_all(
        community_id=community_id,
        role=role,
        is_active=is_active
    )

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

@router.put("/{user_id}", response_model=User)
def update_user(
    user_id: str,
    user_update: UserUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Actualiza la información de un usuario.
    Solo administradores pueden actualizar usuarios.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden actualizar usuarios"
        )
    
    try:
        updated_user = repo.update(user_id, user_update)
        if not updated_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado"
            )
        return updated_user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Elimina (desactiva) un usuario del sistema.
    Solo administradores pueden eliminar usuarios.
    Soft delete: marca is_active = False
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden eliminar usuarios"
        )
    
    success = repo.delete(user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )

@router.post("/{user_id}/assign-unit", response_model=User)
def assign_unit(
    user_id: str,
    assignment: UserAssignUnit,
    current_user: dict = Depends(get_current_user)
):
    """
    Asigna un usuario a una unidad en una comunidad.
    Solo administradores pueden asignar unidades.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden asignar unidades"
        )
    
    try:
        updated_user = repo.assign_to_unit(
            user_id=user_id,
            community_id=assignment.community_id,
            unit_id=assignment.unit_id,
            roles=assignment.roles
        )
        if not updated_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario o unidad no encontrada"
            )
        return updated_user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.delete("/{user_id}/unassign-unit/{community_id}", response_model=User)
def unassign_unit(
    user_id: str,
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Desasigna un usuario de una comunidad.
    Solo administradores pueden desasignar unidades.
    """
    # Verificar que sea admin
    if current_user.get("role") != "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo administradores pueden desasignar unidades"
        )
    
    try:
        updated_user = repo.unassign_from_community(
            user_id=user_id,
            community_id=community_id
        )
        if not updated_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado"
            )
        return updated_user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
