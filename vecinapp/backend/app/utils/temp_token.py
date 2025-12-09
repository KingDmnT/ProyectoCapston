"""
Sistema de tokens temporales para descargas de PDF
Permite generar tokens de un solo uso con expiración de 5 minutos
"""
import secrets
import time
from typing import Dict, Tuple

class TemporaryTokenManager:
    """Gestor de tokens temporales para descargas autenticadas"""
    
    def __init__(self):
        # Almacenamiento en memoria: {token: (user_uid, expense_id, community_id, timestamp)}
        self._tokens: Dict[str, Tuple[str, str, str, float]] = {}
        self._token_lifetime = 300  # 5 minutos en segundos
    
    def generate_token(self, user_uid: str, expense_id: str, community_id: str) -> str:
        """
        Genera un token temporal único
        
        Args:
            user_uid: UID del usuario
            expense_id: ID del gasto común
            community_id: ID de la comunidad
            
        Returns:
            Token temporal como string
        """
        # Limpiar tokens expirados antes de generar uno nuevo
        self._cleanup_expired()
        
        # Generar token seguro
        token = secrets.token_urlsafe(32)
        
        # Almacenar token con timestamp actual
        self._tokens[token] = (user_uid, expense_id, community_id, time.time())
        
        return token
    
    def validate_and_consume_token(self, token: str) -> Tuple[str, str, str] | None:
        """
        Valida un token y lo consume (elimina después de uso)
        
        Args:
            token: Token a validar
            
        Returns:
            Tupla (user_uid, expense_id, community_id) si el token es válido, None si no
        """
        if token not in self._tokens:
            return None
        
        user_uid, expense_id, community_id, timestamp = self._tokens[token]
        
        # Verificar si el token ha expirado
        if time.time() - timestamp > self._token_lifetime:
            # Token expirado, eliminarlo
            del self._tokens[token]
            return None
        
        # Token válido, consumirlo (eliminar para que sea de un solo uso)
        del self._tokens[token]
        
        return (user_uid, expense_id, community_id)
    
    def _cleanup_expired(self):
        """Limpia tokens expirados del almacenamiento"""
        current_time = time.time()
        expired_tokens = [
            token for token, (_, _, _, timestamp) in self._tokens.items()
            if current_time - timestamp > self._token_lifetime
        ]
        
        for token in expired_tokens:
            del self._tokens[token]

# Instancia global del gestor
_token_manager = TemporaryTokenManager()

def get_token_manager() -> TemporaryTokenManager:
    """Obtiene la instancia global del gestor de tokens"""
    return _token_manager
