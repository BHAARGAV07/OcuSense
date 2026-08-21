from fastapi import APIRouter
from app.services.hardware_service import get_hardware_reading

router = APIRouter(prefix="/api/environment", tags=["Environment"])


@router.get("/hardware")
def read_hardware_data() -> dict:
    """Returns hardware environment readings (currently temporary mock sensor data)."""
    return get_hardware_reading()
