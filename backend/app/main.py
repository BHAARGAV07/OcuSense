from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base

import app.models  # Ensure all SQLAlchemy models are registered
from app.api.auth_router import router as auth_router
from app.api.patient_router import router as patient_router
from app.api.environment_router import router as environment_router
from app.api.analysis_router import router as analysis_router
from app.api.symptom_router import router as symptom_router
from app.api.habit_router import router as habit_router
from app.api.eye_rubbing_router import router as eye_rubbing_router
from app.api.reminders_router import router as reminders_router
from app.api.cold_compress_router import router as cold_compress_router
from app.api.prediction_router import router as prediction_router
from app.api.ocular_router import router as ocular_router
from app.api.personalization_router import router as personalization_router

from app.database import engine, Base, ensure_db_schema
import app.models  # Ensure all SQLAlchemy models are registered

# Create database tables and migrate missing columns if they do not exist
try:
    ensure_db_schema()
except Exception:
    pass

app = FastAPI(
    title="OcuSense API",
    version="1.0.0",
    description="FastAPI backend for OcuSense — AI-Assisted Personalized Ocular Allergy Flare-Risk Prediction",
)

# CORS setup
origins = [o.strip() for o in settings.CORS_ORIGINS.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if "*" not in settings.CORS_ORIGINS else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth_router)
app.include_router(personalization_router)
app.include_router(prediction_router)
app.include_router(ocular_router)
app.include_router(patient_router)
app.include_router(environment_router)
app.include_router(analysis_router)
app.include_router(symptom_router)
app.include_router(habit_router)
app.include_router(eye_rubbing_router)
app.include_router(reminders_router)
app.include_router(cold_compress_router)


@app.get("/")
async def root() -> dict:
    return {"message": "Welcome to OcuSense API", "status": "online"}


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
