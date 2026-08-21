from fastapi import APIRouter
from app.services.hardware_service import get_hardware_reading
from app.services.environmental_service import EnvironmentalDataService

router = APIRouter(prefix="/api/environment", tags=["Environment"])


@router.get("/current")
async def read_current_environment(lat: float = 13.0827, lon: float = 80.2707) -> dict:
    """Returns external environmental readings with unavailable fields marked as null."""
    return await EnvironmentalDataService.get_environmental_data(lat=lat, lon=lon)


@router.get("/hardware")
def read_hardware_data() -> dict:
    """Returns hardware environment readings (currently temporary mock sensor data)."""
    return get_hardware_reading()
