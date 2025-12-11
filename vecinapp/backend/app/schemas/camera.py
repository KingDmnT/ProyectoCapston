from pydantic import BaseModel, Field
from typing import Optional

class CameraConfigBase(BaseModel):
    nvr_ip: str = Field(..., description="IP o Host del NVR Hikvision")
    nvr_port: int = Field(80, description="Puerto HTTP del NVR")
    username: str = Field(..., description="Usuario ISAPI")
    password: str = Field(..., description="Contraseña ISAPI")
    alias: Optional[str] = Field(None, description="Nombre amigable del NVR")

class CameraConfigCreate(CameraConfigBase):
    pass

class CameraConfig(CameraConfigBase):
    updated_at: str

    class Config:
        from_attributes = True
