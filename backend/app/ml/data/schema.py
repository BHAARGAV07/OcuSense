"""
Canonical Feature Definitions and Schemas for OcuSense ML Pipeline.
"""
from typing import Dict, Any, Optional, List
from pydantic import BaseModel, Field


# Canonical 30-Row Dataset Features Schema
DATASET_NUMERICAL_FEATURES = [
    "Itching",
    "Redness",
    "Watering",
    "Irritation",
    "Severity",
    "PM2.5",
    "PM10",
    "AQI",
    "Temperature",
    "Humidity",
    "Outdoor_Exposure",
    "Indoor_Dust"
]

DATASET_CATEGORICAL_FEATURES = [
    "Pollen"
]

DATASET_TARGET = "Flare"
IGNORED_COLUMNS = ["Patient_ID", "Date"]


class OcularFeatures(BaseModel):
    redness_score: Optional[float] = Field(None, ge=0.0, le=1.0, description="Objective conjunctival redness index")
    inflammation_score: Optional[float] = Field(None, ge=0.0, le=1.0, description="Inflammation index")
    swelling_score: Optional[float] = Field(None, ge=0.0, le=1.0, description="Lid edema/swelling index if available")
    tear_feature: Optional[float] = Field(None, ge=0.0, le=1.0, description="Tear film/lacrimation index if available")
    image_quality: Optional[float] = Field(None, ge=0.0, le=1.0, description="Quality validation score of the captured image/video")
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0, description="CV model confidence score")


class SymptomFeatures(BaseModel):
    itching: int = Field(0, ge=0, le=3, description="0=No, 1=Mild, 2=Moderate, 3=Severe")
    watering: int = Field(0, ge=0, le=3, description="0=No, 1=Mild, 2=Moderate, 3=Severe")
    redness: int = Field(0, ge=0, le=3, description="0=No, 1=Mild, 2=Moderate, 3=Severe")
    irritation: int = Field(0, ge=0, le=3, description="0=No, 1=Mild, 2=Moderate, 3=Severe")
    severity: int = Field(0, ge=0, le=10, description="Overall subjective severity 0-10")
    eye_rubbing: int = Field(0, ge=0, le=3, description="0=No, 1=Mild, 2=Moderate, 3=Severe")
    medication_used_today: bool = Field(False, description="Whether rescue/regular drops were taken")
    symptoms_duration: str = Field("<1 day", description="<1 day, 1-3 days, >3 days")


class EnvironmentalFeatures(BaseModel):
    pm25: float = Field(25.0, description="PM2.5 concentration in ug/m3")
    pm10: float = Field(45.0, description="PM10 concentration in ug/m3")
    aqi: float = Field(70.0, description="Air Quality Index")
    temperature: float = Field(28.0, description="Ambient temperature in Celsius")
    humidity: float = Field(65.0, description="Relative humidity in percentage")
    uv: Optional[float] = Field(5.0, description="UV index")
    pollen: str = Field("Moderate", description="Low, Moderate, High")
    weather: Optional[str] = Field("Sunny", description="General weather description")


class ExposureFeatures(BaseModel):
    outdoor_exposure: float = Field(2.0, description="Hours spent outdoors today")
    indoor_dust: float = Field(1.0, description="Estimated indoor dust level (1-5)")


class PersonalizationFeatures(BaseModel):
    age: Optional[int] = Field(30, description="Patient age")
    sex: Optional[str] = Field(None, description="Male, Female, Other")
    city: Optional[str] = Field(None, description="Location/City")
    previous_allergy_history: bool = Field(True, description="Known history of allergic conjunctivitis")
    typical_flare_frequency: Optional[str] = Field("Monthly", description="Frequent, Monthly, Seasonal, Rare")
    typical_seasonal_pattern: Optional[str] = Field("Spring/Summer", description="Spring/Summer, Monsoon, Winter, All Year")
    dust_sensitivity: bool = Field(True, description="Self-reported dust sensitivity")
    pollen_sensitivity: bool = Field(True, description="Self-reported pollen sensitivity")
    pet_exposure: bool = Field(False, description="Exposure to pets")
    smoke_exposure: bool = Field(False, description="Exposure to smoke or traffic exhaust")
    eye_rubbing_tendency: bool = Field(True, description="Habitual eye rubbing tendency")
    contact_lens_use: bool = Field(False, description="Wears contact lenses")


class HistoricalFeatures(BaseModel):
    previous_flares_count: int = Field(0, description="Recorded past flares count")
    recent_flare_days_ago: Optional[int] = Field(None, description="Days since last flare")


class PredictionFeatures(BaseModel):
    """
    The Single Canonical Feature Object passed into the Prediction Engine.
    """
    ocular: OcularFeatures = Field(default_factory=OcularFeatures)
    symptoms: SymptomFeatures = Field(default_factory=SymptomFeatures)
    environment: EnvironmentalFeatures = Field(default_factory=EnvironmentalFeatures)
    exposure: ExposureFeatures = Field(default_factory=ExposureFeatures)
    personalization: PersonalizationFeatures = Field(default_factory=PersonalizationFeatures)
    history: HistoricalFeatures = Field(default_factory=HistoricalFeatures)
    metadata: Dict[str, Any] = Field(default_factory=dict)
