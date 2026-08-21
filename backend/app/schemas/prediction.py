"""
Pydantic Schemas for Prediction and Outcome APIs.
"""
from typing import Dict, Any, List, Optional
import datetime
from pydantic import BaseModel, Field
from app.ml.data.schema import PredictionFeatures


class PredictionRequest(BaseModel):
    features: PredictionFeatures
    engine: Optional[str] = Field(None, description="'ml' (default) or 'rule'")
    environmental_snapshot: Optional[Dict[str, Any]] = Field(None, description="Raw environmental service payload used for this prediction")


class ContributingFactorOut(BaseModel):
    factor_key: str
    display_name: str
    impact: float
    direction: Optional[str] = "increases_risk"
    reason: str
    raw_value: Optional[str] = None


class PredictionResponse(BaseModel):
    prediction_id: Optional[str] = None
    engine: str
    risk_probability: float
    risk_score_percentage: int
    risk_level: str  # LOW, MODERATE, HIGH
    prediction_window: str
    model_version: str
    confidence: float
    prediction_mode: str
    top_contributing_features: List[ContributingFactorOut]
    literature_references: Optional[Dict[str, Any]] = None
    environmental_snapshot: Optional[Dict[str, Any]] = None
    preventive_guidance: List[str]
    disclaimer: str


class PredictionComparisonResponse(BaseModel):
    ml_result: PredictionResponse
    rule_result: PredictionResponse
    comparison_note: str


class OutcomeFeedbackCreate(BaseModel):
    prediction_id: Optional[str] = None
    flare_occurred: bool
    symptom_severity: str = Field("NONE", description="NONE, MILD, MODERATE, SEVERE")
    rescue_medication_used: bool = False
    doctor_visit: bool = False
    notes: Optional[str] = None


class OutcomeFeedbackOut(BaseModel):
    id: str
    prediction_id: Optional[str] = None
    user_id: str
    flare_occurred: bool
    symptom_severity: str
    rescue_medication_used: bool
    doctor_visit: bool
    notes: Optional[str] = None
    created_at: datetime.datetime

    class Config:
        from_attributes = True
