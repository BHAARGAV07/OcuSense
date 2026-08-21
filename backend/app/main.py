from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base

import app.models  # Ensure all SQLAlchemy models are registered
from app.api.auth_router import router as auth_router
from app.api.patient_router import router as patient_router
from app.api.environment_router import router as environment_router
from app.api.analysis_router import router as analysis_router

# Create database tables if they do not exist
try:
    Base.metadata.create_all(bind=engine)
except Exception:
    pass

app = FastAPI(
    title="OcuSense API",
    version="1.0.0",
    description="FastAPI backend for OcuSense — Authentication, Patient Profiles, Hardware Integration & Analysis Engine",
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
app.include_router(patient_router)
app.include_router(environment_router)
app.include_router(analysis_router)


@app.get("/")
async def root() -> dict:
    return {"message": "Welcome to OcuSense API", "status": "online"}


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
