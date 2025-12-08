from fastapi import APIRouter, HTTPException, status, Depends
from typing import List
from app.schemas.community import Community, CommunityCreate
from app.repositories.community_repo import CommunityRepository
from app.core.security import get_current_user

router = APIRouter()
repo = CommunityRepository()

@router.post("/", response_model=Community, status_code=status.HTTP_201_CREATED)
def create_community(
    community: CommunityCreate, 
    current_user: dict = Depends(get_current_user) # Solo usuarios autenticados
):
    """
    Crea una nueva comunidad.
    Requiere autenticación.
    """
    # Aquí podríamos validar si el usuario tiene permisos de Super Admin
    return repo.create(community)

@router.get("/", response_model=List[Community])
def list_communities(
    current_user: dict = Depends(get_current_user)
):
    """
    Lista las comunidades activas.
    Filtra automáticamente por comunidad para administradores no-super.
    """
    all_communities = repo.get_all()
    
    # Auto-filtrar por comunidad si es admin de comunidad (no super admin)
    user_memberships = current_user.get("memberships", [])
    
    # Si el admin tiene memberships y solo tiene 1 (no es super admin)
    if user_memberships and len(user_memberships) == 1:
        # Obtener ID de la comunidad del admin
        admin_community_id = user_memberships[0].get("community_id")
        # Filtrar solo su comunidad
        return [c for c in all_communities if c.id == admin_community_id]
    
    # Super admin o sin memberships: ver todas
    return all_communities

@router.get("/{community_id}", response_model=Community)
def get_community(
    community_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obtiene el detalle de una comunidad específica.
    """
    community = repo.get_by_id(community_id)
    if not community:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Comunidad no encontrada"
        )
    return community

@router.put("/{community_id}", response_model=Community)
def update_community(
    community_id: str, 
    community_in: CommunityCreate, 
    current_user: dict = Depends(get_current_user)
):
    """Actualiza una comunidad. Requiere permisos de Super Admin (TODO)"""
    update_data = community_in.model_dump(exclude_unset=True)
    
    updated_community = repo.update(community_id, update_data)
    if not updated_community:
        raise HTTPException(status_code=404, detail="Comunidad no encontrada")
    return updated_community

@router.delete("/{community_id}")
def delete_community(
    community_id: str, 
    current_user: dict = Depends(get_current_user)
):
    """Desactiva una comunidad (Soft Delete)"""
    success = repo.delete(community_id)
    if not success:
        raise HTTPException(status_code=404, detail="Comunidad no encontrada")
    return {"message": "Comunidad desactivada exitosamente"}
