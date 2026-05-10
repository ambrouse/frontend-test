from fastapi import APIRouter

from app.schemas.models import HardwareSnapshot
from app.services.hardware import hardware_service

router = APIRouter(prefix="/api/hardware", tags=["hardware"])


@router.get("/snapshot", response_model=HardwareSnapshot)
def hardware_snapshot() -> HardwareSnapshot:
    return hardware_service.snapshot()
