from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import OutcomeFeedback, PatientProfile, PredictionRecord, User
from app.core.deps import get_current_user
from app.services.aggregation_service import DataAggregationService
from app.ml.data.schema import PredictionFeatures
from app.ml.services.prediction_engine import MLPredictionEngine
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
    and granular contributing factors using the configured ML prediction engine.
    The patient ID is derived strictly from `current_user.id`.
    """
    patient_id = str(current_user.id)
    combined_data = await DataAggregationService.get_combined_data(patient_id=patient_id, db=db, lat=lat, lon=lon)
    
    env = combined_data.get("environment_api", {})
    hardware = combined_data.get("environment_hardware", {}) or {}
    patient = combined_data.get("patient", {})
    profile = db.query(PatientProfile).filter(PatientProfile.user_id == patient_id).first()

    features = PredictionFeatures()
    features.environment.pm25 = env.get("pm25")
    features.environment.pm10 = env.get("pm10") or env.get("dust_numeric")
    features.environment.no2 = env.get("no2")
    features.environment.o3 = env.get("o3")
    features.environment.aqi = env.get("aqi_numeric")
    features.environment.temperature = hardware.get("temperature", env.get("temperature"))
    features.environment.humidity = hardware.get("humidity", env.get("humidity"))
    features.environment.uv = env.get("uv")
    features.environment.pollen = env.get("pollen")
    features.environment.pollen_index = env.get("pollen_index")
    features.environment.weather = env.get("weather")
    features.metadata["environment_missing_fields"] = env.get("missing_fields", [])
    features.metadata["environment_source"] = env.get("sources", {})

    symptoms = patient.get("symptoms", [])
    features.symptoms.itching = 2 if "itching" in symptoms else 0
    features.symptoms.redness = 2 if "redness" in symptoms else 0
    features.symptoms.watering = 2 if "watering" in symptoms else 0
    features.symptoms.irritation = 2 if "irritation" in symptoms else 0
    features.symptoms.severity = patient.get("symptom_severity_score", 0)

    if profile:
        features.personalization = features.personalization.model_copy(update={
            field: getattr(profile, field)
            for field in (
                "age", "previous_allergy_history", "typical_flare_frequency",
                "typical_seasonal_pattern", "dust_sensitivity", "pollen_sensitivity",
                "pet_exposure", "smoke_exposure", "contact_lens_use"
            )
            if getattr(profile, field) is not None
        })
        features.exposure.outdoor_exposure = profile.outdoor_activity_hours or 0.0
        features.exposure.indoor_dust = 3.0 if "indoor_dust" in patient.get("habits", []) else 0.0

    features.history.previous_flares_count = db.query(OutcomeFeedback).filter(
        OutcomeFeedback.user_id == patient_id,
        OutcomeFeedback.flare_occurred.is_(True),
    ).count()

    try:
        result = MLPredictionEngine().predict(features)
    except RuntimeError as exc:
        return {
            "prediction_engine": "unavailable",
            "engine": "unavailable",
            "risk_probability": None,
            "risk_score": None,
            "risk_score_percentage": None,
            "risk_level": None,
            "model_version": None,
            "confidence": None,
            "contributing_factors": [],
            "top_contributing_features": [],
            "environment": env,
            "environment_hardware": hardware,
            "data_availability": env.get("availability", {}),
            "data_errors": env.get("errors", {}),
            "feature_vector": features.model_dump(),
            "error": str(exc),
            "disclaimer": "No model prediction is available; environmental observations are not a medical diagnosis.",
        }

    top_features = result.get("top_contributing_features", [])
    return {
        "risk_score": result.get("risk_score_percentage"),
        "risk_probability": result.get("risk_probability"),
        "risk_level": result.get("risk_level"),
        "prediction_engine": result.get("engine"),
        "engine": result.get("engine"),
        "model_version": result.get("model_version"),
        "confidence": result.get("confidence"),
        "prediction_window": result.get("prediction_window"),
        "prediction_mode": result.get("prediction_mode"),
        "contributing_factors": top_features,
        "top_contributing_features": top_features,
        "literature_references": result.get("literature_references"),
        "preventive_guidance": result.get("preventive_guidance", []),
        "environment": env,
        "environment_hardware": hardware,
        "data_availability": env.get("availability", {}),
        "data_errors": env.get("errors", {}),
        "feature_vector": features.model_dump(),
        "disclaimer": result.get("disclaimer"),
    }


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
    records = (
        db.query(PredictionRecord)
        .filter(PredictionRecord.user_id == str(current_user.id))
        .order_by(PredictionRecord.created_at.desc())
        .limit(30)
        .all()
    )

    history = []
    for record in reversed(records):
        factors = record.top_contributing_features or []
        primary_factor = "No dominant factor available"
        if factors and isinstance(factors[0], dict):
            primary_factor = factors[0].get("display_name", primary_factor)

        history.append({
            "date": str(record.created_at.date()),
            "risk_score": record.risk_score_percentage,
            "risk_level": record.risk_level,
            "primary_factor": primary_factor,
        })

    return {"patient_id": str(current_user.id), "history": history}

