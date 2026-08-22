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
# `allow_origins` performs exact matching, so `http://localhost:*` does not
# match the random port Flutter web uses in development. Translate that one
# documented development pattern into Starlette's origin regular expression
# support; retain exact matching for every configured production origin.
configured_origins = [
    origin.strip()
    for origin in settings.CORS_ORIGINS.split(",")
    if origin.strip()
]
is_wildcard = configured_origins == ["*"]
local_origin_pattern = "http://localhost:*"
allow_origin_regex = None

if local_origin_pattern in configured_origins:
    allow_origin_regex = r"^http://localhost(?::\d+)?$"
    configured_origins.remove(local_origin_pattern)

origins = ["*"] if is_wildcard else configured_origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=allow_origin_regex,
    allow_credentials=not is_wildcard,  # credentials are incompatible with wildcard origin
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
