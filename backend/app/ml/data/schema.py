"""
Canonical Feature Definitions and Schemas for OcuSense ML Pipeline.
"""
from typing import Dict, Any, Optional, List
from pydantic import BaseModel, Field


# Canonical prototype dataset feature schema
DATASET_NUMERICAL_FEATURES = [
    "Itching",
    "Redness",
    "Watering",
    "Irritation",
    "Severity",
    "Redness_Score",
    "Inflammation_Score",
    "Swelling_Score",
    "Watering_Score",
    "Image_Quality_Score",
    "PM2.5",
    "PM10",
    "NO2",
    "O3",
    "AQI",
    "Temperature",
    "Humidity",
    "Pollen_Index",
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
    medication_used_today: bool = Field(False, description="Whether rescue/regular drops were taken")
    symptoms_duration: str = Field("<1 day", description="<1 day, 1-3 days, >3 days")


class EnvironmentalFeatures(BaseModel):
    pm25: Optional[float] = Field(None, description="PM2.5 concentration in ug/m3, if available")
    pm10: Optional[float] = Field(None, description="PM10 concentration in ug/m3, if available")
    no2: Optional[float] = Field(None, description="NO2 concentration in ug/m3, if available")
    o3: Optional[float] = Field(None, description="O3 concentration in ug/m3, if available")
    aqi: Optional[float] = Field(None, description="Air Quality Index, if available")
    temperature: Optional[float] = Field(None, description="Ambient temperature in Celsius, if available")
    humidity: Optional[float] = Field(None, description="Relative humidity in percentage, if available")
    uv: Optional[float] = Field(None, description="UV index, if available")
    pollen: Optional[str] = Field(None, description="Low, Moderate, High, if available")
    pollen_index: Optional[float] = Field(None, description="Numeric pollen index from live API, if available")
    weather: Optional[str] = Field(None, description="General weather description, if available")


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
