import datetime
from pydantic import BaseModel
from typing import Optional


class PatientProfileCreate(BaseModel):
    display_name: Optional[str] = None
    location_name: Optional[str] = None
    location_lat: Optional[float] = None
    location_lon: Optional[float] = None


class PatientProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    location_name: Optional[str] = None
    location_lat: Optional[float] = None
    location_lon: Optional[float] = None


class PatientProfileOut(BaseModel):
    id: str
    user_id: str
    display_name: Optional[str] = None
    location_name: Optional[str] = None
    location_lat: Optional[float] = None
    location_lon: Optional[float] = None
    created_at: datetime.datetime
    updated_at: datetime.datetime

    class Config:
        from_attributes = True
