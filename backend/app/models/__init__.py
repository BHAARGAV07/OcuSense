import uuid
import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, JSON, Date, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    profile = relationship("PatientProfile", back_populates="user", uselist=False)
    predictions = relationship("PredictionRecord", back_populates="user")
    eye_analyses = relationship("EyeAnalysisRecord", back_populates="user")
    outcomes = relationship("OutcomeFeedback", back_populates="user")


class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), unique=True, nullable=False)
    display_name = Column(String, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lon = Column(Float, nullable=True)
    location_name = Column(String, nullable=True)

    # Personalization Characteristics
    age = Column(Integer, nullable=True)
    sex = Column(String, nullable=True)
    occupation = Column(String, nullable=True)
    previous_allergy_history = Column(Boolean, default=False)
    typical_flare_frequency = Column(String, default="Monthly")  # Frequent, Monthly, Seasonal, Rare
    typical_seasonal_pattern = Column(String, default="Spring/Summer")
    dust_sensitivity = Column(Boolean, default=True)
    pollen_sensitivity = Column(Boolean, default=True)
    pet_exposure = Column(Boolean, default=False)
    smoke_exposure = Column(Boolean, default=False)
    outdoor_activity_hours = Column(Float, default=2.0)
    eye_rubbing_tendency = Column(Boolean, default=False)
    contact_lens_use = Column(Boolean, default=False)
    current_medication = Column(String, nullable=True)
    is_onboarded = Column(Boolean, default=False)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    user = relationship("User", back_populates="profile")


class EyeAnalysisRecord(Base):
    __tablename__ = "eye_analyses"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)
    image_quality = Column(Float, nullable=False)
    redness_score = Column(Float, nullable=False)
    inflammation_score = Column(Float, nullable=True)
    swelling_score = Column(Float, nullable=True)
    tear_feature = Column(Float, nullable=True)
    confidence = Column(Float, default=0.85)
    feedback = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="eye_analyses")


class PredictionRecord(Base):
    __tablename__ = "predictions"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)
    risk_probability = Column(Float, nullable=False)
    risk_score_percentage = Column(Integer, nullable=False)
    risk_level = Column(String, nullable=False)  # LOW, MODERATE, HIGH
    prediction_window = Column(String, default="24–72 hours")
    model_version = Column(String, nullable=False)
    prediction_mode = Column(String, default="prototype_multivariable_ml")
    feature_snapshot = Column(JSON, nullable=False)  # Canonical PredictionFeatures snapshot
    top_contributing_features = Column(JSON, nullable=True)
    preventive_guidance = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="predictions")
    outcomes = relationship("OutcomeFeedback", back_populates="prediction")


class OutcomeFeedback(Base):
    __tablename__ = "outcome_feedbacks"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    prediction_id = Column(String, ForeignKey("predictions.id"), nullable=True)
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)
    flare_occurred = Column(Boolean, nullable=False)
    symptom_severity = Column(String, default="NONE")  # NONE, MILD, MODERATE, SEVERE
    rescue_medication_used = Column(Boolean, default=False)
    doctor_visit = Column(Boolean, default=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="outcomes")
    prediction = relationship("PredictionRecord", back_populates="outcomes")


class ModelVersionRecord(Base):
    __tablename__ = "model_versions"

    id = Column(String, primary_key=True)
    model_type = Column(String, nullable=False)
    metrics = Column(JSON, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)


class Patient(Base):
    __tablename__ = "patients"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=True)
    email = Column(String, unique=True, index=True, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    symptoms = relationship("SymptomLog", back_populates="patient")
    habits = relationship("HabitLog", back_populates="patient")
    snapshots = relationship("DailyTriggerSnapshot", back_populates="patient")


class SymptomLog(Base):
    __tablename__ = "symptom_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    patient_id = Column(String, ForeignKey("patients.id"), index=True)
    symptoms = Column(JSON)  # e.g., ["itching", "redness", "watering"]
    severity = Column(String)  # "LOW", "MODERATE", "HIGH"
    severity_score = Column(Integer, default=5)  # 1-10 scale
    recent_symptoms_increased = Column(Boolean, default=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

    patient = relationship("Patient", back_populates="symptoms")


class HabitLog(Base):
    __tablename__ = "habit_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    patient_id = Column(String, ForeignKey("patients.id"), index=True)
    habits = Column(JSON)  # e.g., ["eye_rubbing", "outdoor_activity"]
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

    patient = relationship("Patient", back_populates="habits")


class DailyTriggerSnapshot(Base):
    __tablename__ = "daily_trigger_snapshots"

    id = Column(Integer, primary_key=True, autoincrement=True)
    patient_id = Column(String, ForeignKey("patients.id"), index=True)
    date = Column(Date, index=True)
    had_symptoms = Column(Boolean, default=False)
    symptom_severity = Column(String, default="LOW")
    symptoms = Column(JSON)  # e.g. ["itching"]
    dust_level = Column(String)  # "HIGH", "MODERATE", "LOW"
    dust_numeric = Column(Float, nullable=True)
    pollen_level = Column(String)  # "HIGH", "MODERATE", "LOW"
    humidity = Column(Float)  # e.g. 76.0
    aqi = Column(String)  # "HIGH", "MODERATE", "LOW"
    weather = Column(String)
    habits = Column(JSON)  # e.g. ["eye_rubbing"]
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    patient = relationship("Patient", back_populates="snapshots")
