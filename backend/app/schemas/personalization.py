"""
Pydantic Schemas for Patient Personalization Profile.
"""
from typing import Optional
import datetime
from pydantic import BaseModel, Field


class PersonalizationProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    location_name: Optional[str] = None
    location_lat: Optional[float] = None
    location_lon: Optional[float] = None
    
    age: Optional[int] = Field(None, ge=1, le=120)
    sex: Optional[str] = None
    occupation: Optional[str] = None
    previous_allergy_history: Optional[bool] = None
    typical_flare_frequency: Optional[str] = None
    typical_seasonal_pattern: Optional[str] = None
    dust_sensitivity: Optional[bool] = None
    pollen_sensitivity: Optional[bool] = None
    pet_exposure: Optional[bool] = None
    smoke_exposure: Optional[bool] = None
    outdoor_activity_hours: Optional[float] = Field(None, ge=0.0, le=24.0)
    contact_lens_use: Optional[bool] = None
    current_medication: Optional[str] = None
    is_onboarded: Optional[bool] = None


class PersonalizationProfileOut(BaseModel):
    id: str
    user_id: str
    display_name: Optional[str] = None
    location_name: Optional[str] = None
    location_lat: Optional[float] = None
    location_lon: Optional[float] = None
    
    age: Optional[int] = None
    sex: Optional[str] = None
    occupation: Optional[str] = None
    previous_allergy_history: bool = False
    typical_flare_frequency: Optional[str] = "Monthly"
    typical_seasonal_pattern: Optional[str] = "Spring/Summer"
    dust_sensitivity: bool = True
    pollen_sensitivity: bool = True
    pet_exposure: bool = False
    smoke_exposure: bool = False
    outdoor_activity_hours: float = 2.0
    contact_lens_use: bool = False
    current_medication: Optional[str] = None
    is_onboarded: bool = False
    
    created_at: datetime.datetime
    updated_at: datetime.datetime

    class Config:
        from_attributes = True
