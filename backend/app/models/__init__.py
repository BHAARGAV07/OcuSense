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


class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), unique=True, nullable=False)
    display_name = Column(String, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lon = Column(Float, nullable=True)
    location_name = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    user = relationship("User", back_populates="profile")


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
