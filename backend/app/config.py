from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/postgres"
    JWT_SECRET: str = "default_secret_key"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    GOOGLE_POLLEN_API_KEY: Optional[str] = None
    GOOGLE_AIR_QUALITY_API_KEY: Optional[str] = None

    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    # Comma-separated exact origins, or a single local-development origin
    # pattern such as `http://localhost:*`.
    CORS_ORIGINS: str = "http://localhost:*"

    # Intelligence & Risk Thresholds
    RISK_HUMIDITY_THRESHOLD: int = 75
    MIN_OBSERVATION_COUNT: int = 5
    TIME_WINDOW_HOURS: int = 24
    POLLEN_CACHE_TTL_HOURS: int = 24
    WEATHER_CACHE_TTL_HOURS: int = 1

    # Machine Learning & Prediction Architecture Settings
    PREDICTION_ENGINE: str = "ml"  # "ml" or "rule"
    MODEL_VERSION: str = "ocular-risk-v0.1-prototype"
    RISK_LOW_THRESHOLD: float = 0.20
    RISK_HIGH_THRESHOLD: float = 0.60
    PREDICTION_WINDOW: str = "24–72 hours"
    MODEL_ARTIFACT_PATH: str = "app/ml/models/artifacts/ocular_risk_v0.1_prototype.joblib"

    # Literature-Informed Reference Guidelines (Annotations only, not diagnostic cut-offs)
    LITERATURE_PM25_REF: float = 45.0
    LITERATURE_PM10_REF: float = 70.0
    LITERATURE_NO2_REF: float = 27.0
    LITERATURE_O3_REF: float = 88.0
    LITERATURE_HUMIDITY_REF: float = 60.0

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
