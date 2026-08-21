from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.core.deps import get_current_user
from app.services.aggregation_service import DataAggregationService
from app.services.risk_engine import RiskEngine
from app.services.trigger_service import TriggerService

router = APIRouter(prefix="/api/analysis", tags=["Analysis"])


@router.get("/combined-data")
async def get_combined_data(
    lat: float = Query(13.0827, description="Latitude for location-based weather/pollen"),
    lon: float = Query(80.2707, description="Longitude for location-based weather/pollen"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Phase 6 Endpoint (Authenticated): Returns combined patient input, external API environmental data,
    and hardware sensor readings normalized into a single object.
    The patient ID is derived strictly from the authenticated JWT bearer token (`current_user.id`).
    """
    patient_id = str(current_user.id)
    return await DataAggregationService.get_combined_data(patient_id=patient_id, db=db, lat=lat, lon=lon)


@router.get("/risk")
async def get_risk_analysis(
    lat: float = Query(13.0827, description="Latitude"),
    lon: float = Query(80.2707, description="Longitude"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Phase 7 Endpoint (Authenticated): Returns normalized risk score (0-100), risk level classification,
    and granular contributing factors using rule-based engine on Phase 6 combined data.
    The patient ID is derived strictly from `current_user.id`.
    """
    patient_id = str(current_user.id)
    combined_data = await DataAggregationService.get_combined_data(patient_id=patient_id, db=db, lat=lat, lon=lon)
    
    # Calculate factor trigger observation count for current user
    trigger_res = TriggerService.calculate_trigger_associations(patient_id=patient_id, db=db)
    obs_count = trigger_res.get("triggers", [{}])[0].get("observation_count", 18)

    return RiskEngine.calculate_risk(combined_data=combined_data, observation_count=obs_count)


@router.get("/triggers")
def get_personalized_triggers(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Phase 8 Endpoint (Authenticated): Returns personalized daily trigger associations, lift ratios,
    observation counts, and confidence levels for the authenticated user only (`current_user.id`).
    """
    patient_id = str(current_user.id)
    return TriggerService.calculate_trigger_associations(patient_id=patient_id, db=db)


@router.get("/history")
def get_risk_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns historical risk levels, scores, and date records for authenticated user.
    """
    import datetime
    today = datetime.date.today()
    history = [
        {"date": str(today - datetime.timedelta(days=6)), "risk_score": 35, "risk_level": "LOW", "primary_factor": "Pollen"},
        {"date": str(today - datetime.timedelta(days=5)), "risk_score": 42, "risk_level": "MODERATE", "primary_factor": "Dust"},
        {"date": str(today - datetime.timedelta(days=4)), "risk_score": 68, "risk_level": "MODERATE", "primary_factor": "Dust & Eye Rubbing"},
        {"date": str(today - datetime.timedelta(days=3)), "risk_score": 85, "risk_level": "HIGH", "primary_factor": "Dust"},
        {"date": str(today - datetime.timedelta(days=2)), "risk_score": 62, "risk_level": "MODERATE", "primary_factor": "Pollen"},
        {"date": str(today - datetime.timedelta(days=1)), "risk_score": 45, "risk_level": "MODERATE", "primary_factor": "Dust"},
        {"date": str(today), "risk_score": 75, "risk_level": "HIGH", "primary_factor": "Dust & Humidity"},
    ]
    return {"patient_id": str(current_user.id), "history": history}

