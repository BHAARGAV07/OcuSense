from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/postgres"
    JWT_SECRET: str = "default_secret_key"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    GOOGLE_POLLEN_API_KEY: Optional[str] = None

    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    CORS_ORIGINS: str = "http://localhost:*"

    # Intelligence & Risk Thresholds
    RISK_HUMIDITY_THRESHOLD: int = 75
    MIN_OBSERVATION_COUNT: int = 5
    TIME_WINDOW_HOURS: int = 24
    POLLEN_CACHE_TTL_HOURS: int = 24
    WEATHER_CACHE_TTL_HOURS: int = 1

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
