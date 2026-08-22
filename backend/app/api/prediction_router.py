"""
Prediction and Flare Risk API Endpoints for OcuSense.
Provides probabilistic ML predictions, explainability, outcome logging, and engine comparisons.
"""
import uuid
import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, PredictionRecord, OutcomeFeedback
from app.core.deps import get_current_user
from app.schemas.prediction import (
    PredictionRequest,
    PredictionResponse,
    PredictionComparisonResponse,
    OutcomeFeedbackCreate,
    OutcomeFeedbackOut
)
from app.ml.services.prediction_engine import get_prediction_engine, MLPredictionEngine, RuleBasedPredictionEngine
from app.ml.data.schema import PredictionFeatures
from app.services.aggregation_service import DataAggregationService
from app.services.environmental_service import EnvironmentalDataService

router = APIRouter(prefix="/api/prediction", tags=["Prediction"])


def _environment_snapshot_from_features(features: PredictionFeatures) -> dict:
    return {
        "pm25": features.environment.pm25,
        "pm10": features.environment.pm10,
        "no2": features.environment.no2,
        "o3": features.environment.o3,
        "aqi": features.environment.aqi,
        "temperature": features.environment.temperature,
        "humidity": features.environment.humidity,
        "uv": features.environment.uv,
        "pollen": features.environment.pollen,
        "pollen_index": features.environment.pollen_index,
        "weather": features.environment.weather,
        "missing_fields": features.metadata.get("environment_missing_fields", []),
        "source": features.metadata.get("environment_source", "request_features"),
    }


def _optional_float(value, default=None):
    try:
        return float(value) if value is not None else default
    except (TypeError, ValueError):
        return default


def _apply_environment_to_features(features: PredictionFeatures, env_api: dict) -> None:
    features.environment.pm25 = _optional_float(env_api.get("pm25"), features.environment.pm25)
    features.environment.pm10 = _optional_float(env_api.get("pm10") or env_api.get("dust_numeric"), features.environment.pm10)
    features.environment.no2 = _optional_float(env_api.get("no2"), features.environment.no2)
    features.environment.o3 = _optional_float(env_api.get("o3"), features.environment.o3)
    features.environment.aqi = _optional_float(env_api.get("aqi_numeric") or env_api.get("aqi"), features.environment.aqi)
    features.environment.temperature = _optional_float(env_api.get("temperature"), features.environment.temperature)
    features.environment.humidity = _optional_float(env_api.get("humidity"), features.environment.humidity)
    features.environment.uv = _optional_float(env_api.get("uv"), features.environment.uv)
    features.environment.pollen = str(env_api.get("pollen")).capitalize() if env_api.get("pollen") else features.environment.pollen
    features.environment.pollen_index = _optional_float(env_api.get("pollen_index"), features.environment.pollen_index)
    features.environment.weather = env_api.get("weather") or features.environment.weather
    features.metadata["environment_missing_fields"] = env_api.get("missing_fields", [])
    features.metadata["environment_source"] = env_api.get("sources", {})
    features.metadata["environment_forecast_window"] = env_api.get("forecast_window")


@router.post("", response_model=PredictionResponse)
async def generate_prediction(
    body: PredictionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Executes flare-risk prediction using the specified or default PredictionEngine (ML).
    Saves the prediction record and reproducible feature snapshot.
    """
    if body.location:
        environmental_snapshot = await EnvironmentalDataService.get_environmental_data(
            lat=body.location.lat,
            lon=body.location.lon,
        )
        _apply_environment_to_features(body.features, environmental_snapshot)
    else:
        environmental_snapshot = body.environmental_snapshot or _environment_snapshot_from_features(body.features)

    if environmental_snapshot.get("missing_fields"):
        body.features.metadata["environment_missing_fields"] = environmental_snapshot["missing_fields"]

    engine = get_prediction_engine(body.engine)
    result = engine.predict(body.features)
    
    prediction_id = str(uuid.uuid4())
    
    # Store Prediction Record in Database
    try:
        record = PredictionRecord(
            id=prediction_id,
            user_id=str(current_user.id),
            risk_probability=result["risk_probability"],
            risk_score_percentage=result["risk_score_percentage"],
            risk_level=result["risk_level"],
            prediction_window=result["prediction_window"],
            model_version=result["model_version"],
            prediction_mode=result["prediction_mode"],
            feature_snapshot=body.features.model_dump(),
            environmental_snapshot=environmental_snapshot,
            top_contributing_features=result.get("top_contributing_features", []),
            preventive_guidance=result.get("preventive_guidance", []),
            created_at=datetime.datetime.now(datetime.timezone.utc)
        )
        db.add(record)
        db.commit()
    except Exception as e:
        db.rollback()

    result["prediction_id"] = prediction_id
    result["environmental_snapshot"] = environmental_snapshot
    return result


@router.get("/compare", response_model=PredictionComparisonResponse)
async def compare_prediction_engines(
    lat: float = 13.0827,
    lon: float = 80.2707,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Research / Developer Endpoint:
    Compares the ML Prediction Engine vs Legacy Rule-Based Engine on the current aggregated state.
    """
    combined = await DataAggregationService.get_combined_data(patient_id=str(current_user.id), db=db, lat=lat, lon=lon)
    
    # Map combined data to Canonical PredictionFeatures
    env_api = combined.get("environment_api", {})
    env_hw = combined.get("environment_hardware", {})
    patient = combined.get("patient", {})
    
    features = PredictionFeatures()
    features.environment.pm25 = _optional_float(env_api.get("pm25"))
    features.environment.pm10 = _optional_float(env_api.get("pm10") or env_api.get("dust_numeric"))
    features.environment.no2 = _optional_float(env_api.get("no2"))
    features.environment.o3 = _optional_float(env_api.get("o3"))
    features.environment.aqi = _optional_float(env_api.get("aqi_numeric"))
    features.environment.temperature = _optional_float(env_hw.get("temperature"), _optional_float(env_api.get("temperature")))
    features.environment.humidity = _optional_float(env_hw.get("humidity"), _optional_float(env_api.get("humidity")))
    features.environment.pollen = str(env_api.get("pollen")).capitalize() if env_api.get("pollen") else None
    features.environment.pollen_index = _optional_float(env_api.get("pollen_index"))
    features.environment.weather = env_api.get("weather")
    features.metadata["environment_missing_fields"] = env_api.get("missing_fields", [])
    features.metadata["environment_source"] = env_api.get("sources", {})
    
    symptoms_list = patient.get("symptoms", [])
    features.symptoms.itching = 2 if "itching" in symptoms_list else 0
    features.symptoms.redness = 2 if "redness" in symptoms_list else 0
    features.symptoms.watering = 1 if "watering" in symptoms_list else 0
    features.symptoms.irritation = 1 if "irritation" in symptoms_list else 0
    features.symptoms.severity = patient.get("symptom_severity_score", 5)

    ml_engine = MLPredictionEngine()
    rule_engine = RuleBasedPredictionEngine()

    ml_res = ml_engine.predict(features)
    rule_res = rule_engine.predict(features)

    note = (
        "ML Engine evaluates continuous multivariable interactions and returns prototype probabilities, "
        "whereas the research-only Rule-Based engine relies on hardcoded discrete thresholds."
    )

    return {
        "ml_result": ml_res,
        "rule_result": rule_res,
        "comparison_note": note
    }


@router.get("/history")
def get_prediction_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns stored prediction history for the authenticated user.
    """
    records = (
        db.query(PredictionRecord)
        .filter(PredictionRecord.user_id == str(current_user.id))
        .order_by(PredictionRecord.created_at.desc())
        .limit(20)
        .all()
    )
    
    out = []
    for r in records:
        out.append({
            "id": r.id,
            "date": r.created_at.strftime("%Y-%m-%d %H:%M") if r.created_at else "Recently",
            "risk_probability": r.risk_probability,
            "risk_score_percentage": r.risk_score_percentage,
            "risk_level": r.risk_level,
            "model_version": r.model_version,
            "prediction_mode": r.prediction_mode,
            "environment_missing_fields": (r.environmental_snapshot or {}).get("missing_fields", []),
            "top_factors": [f.get("display_name", "") for f in (r.top_contributing_features or [])[:2]],
            "has_outcome": len(r.outcomes) > 0 if hasattr(r, "outcomes") and r.outcomes else False
        })
    return {"patient_id": str(current_user.id), "history": out}


@router.post("/outcome", response_model=OutcomeFeedbackOut, status_code=status.HTTP_201_CREATED)
def submit_outcome_feedback(
    body: OutcomeFeedbackCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logs actual patient outcome following a prediction window.
    Essential for closing the feedback loop and building longitudinal research datasets.
    """
    outcome = OutcomeFeedback(
        id=str(uuid.uuid4()),
        prediction_id=body.prediction_id,
        user_id=str(current_user.id),
        flare_occurred=body.flare_occurred,
        symptom_severity=body.symptom_severity.upper(),
        rescue_medication_used=body.rescue_medication_used,
        doctor_visit=body.doctor_visit,
        notes=body.notes,
        created_at=datetime.datetime.now(datetime.timezone.utc)
    )
    db.add(outcome)
    db.commit()
    db.refresh(outcome)
    return outcome
