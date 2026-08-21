import logging
import datetime
from typing import Dict, Any, Optional
import httpx
from app.config import settings

logger = logging.getLogger(__name__)


class EnvironmentalDataService:
    @staticmethod
    def _unavailable(fields: list[str], source: str, error: Optional[str] = None) -> Dict[str, Any]:
        payload = {field: None for field in fields}
        payload.update({
            "available": False,
            "source": source,
            "error": error,
        })
        return payload

    @staticmethod
    async def fetch_open_meteo_weather(lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Fetch weather and humidity data from Open-Meteo free API."""
        fields = ["temperature", "humidity", "weather_code", "weather"]
        try:
            url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,weather_code"
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(url)
                if resp.status_code == 200:
                    data = resp.json().get("current", {})
                    return {
                        "temperature": data.get("temperature_2m"),
                        "humidity": data.get("relative_humidity_2m"),
                        "weather_code": data.get("weather_code"),
                        "weather": "Sunny" if data.get("weather_code", 99) <= 3 else "Cloudy",
                        "available": True,
                        "source": "open-meteo-weather",
                        "error": None,
                    }
                return EnvironmentalDataService._unavailable(fields, "open-meteo-weather", f"HTTP {resp.status_code}")
        except Exception as e:
            logger.warning(f"Failed to fetch Open-Meteo weather data: {e}")
            return EnvironmentalDataService._unavailable(fields, "open-meteo-weather", str(e))

        return EnvironmentalDataService._unavailable(fields, "open-meteo-weather")

    @staticmethod
    async def fetch_open_meteo_air_quality(lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Fetch dust (pm10/pm2_5) and AQI from Open-Meteo Air Quality API."""
        fields = ["pm25", "pm10", "aqi", "dust", "dust_numeric", "aqi_numeric"]
        try:
            url = f"https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}&current=pm10,pm2_5,us_aqi,dust"
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(url)
                if resp.status_code == 200:
                    data = resp.json().get("current", {})
                    pm10 = data.get("pm10")
                    pm25 = data.get("pm2_5")
                    aqi_val = data.get("us_aqi")
                    return {
                        "pm25": pm25,
                        "pm10": pm10,
                        "aqi": "high" if aqi_val and aqi_val > 150 else ("moderate" if aqi_val and aqi_val > 50 else ("low" if aqi_val is not None else None)),
                        "aqi_numeric": aqi_val,
                        "dust": "high" if pm10 and pm10 > 300 else ("moderate" if pm10 and pm10 > 100 else ("low" if pm10 is not None else None)),
                        "dust_numeric": pm10,
                        "available": True,
                        "source": "open-meteo-air-quality",
                        "error": None,
                    }
                return EnvironmentalDataService._unavailable(fields, "open-meteo-air-quality", f"HTTP {resp.status_code}")
        except Exception as e:
            logger.warning(f"Failed to fetch Open-Meteo air quality: {e}")
            return EnvironmentalDataService._unavailable(fields, "open-meteo-air-quality", str(e))

        return EnvironmentalDataService._unavailable(fields, "open-meteo-air-quality")

    @staticmethod
    async def fetch_google_pollen(lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Fetch pollen levels from Google Pollen API using server API key."""
        key = settings.GOOGLE_POLLEN_API_KEY
        if key and key != "string":
            try:
                url = f"https://pollen.googleapis.com/v1/forecast:lookup?key={key}&location.latitude={lat}&location.longitude={lon}&days=1"
                async with httpx.AsyncClient(timeout=5.0) as client:
                    resp = await client.get(url)
                    if resp.status_code == 200:
                        data = resp.json()
                        daily_info = data.get("dailyInfo", [{}])[0]
                        plant_info = daily_info.get("pollenTypeInfo", [])
                        max_category = "low"
                        for p in plant_info:
                            cat = p.get("indexInfo", {}).get("category", "").lower()
                            if "high" in cat or "very_high" in cat:
                                max_category = "high"
                                break
                            elif "moderate" in cat:
                                max_category = "moderate"
                        return {
                            "pollen": max_category,
                            "raw": daily_info,
                            "available": True,
                            "source": "google-pollen",
                            "error": None,
                        }
                    return EnvironmentalDataService._unavailable(["pollen"], "google-pollen", f"HTTP {resp.status_code}")
            except Exception as e:
                logger.warning(f"Failed to fetch Google Pollen API: {e}")
                return EnvironmentalDataService._unavailable(["pollen"], "google-pollen", str(e))

        return EnvironmentalDataService._unavailable(["pollen"], "google-pollen", "GOOGLE_POLLEN_API_KEY not configured")

    @classmethod
    async def get_environmental_data(cls, lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Combine external environmental API sources into a single normalized dict."""
        weather_info = await cls.fetch_open_meteo_weather(lat, lon)
        air_info = await cls.fetch_open_meteo_air_quality(lat, lon)
        pollen_info = await cls.fetch_google_pollen(lat, lon)

        data = {
            "pm25": air_info.get("pm25"),
            "pm10": air_info.get("pm10"),
            "aqi": air_info.get("aqi"),
            "aqi_numeric": air_info.get("aqi_numeric"),
            "dust": air_info.get("dust"),
            "dust_numeric": air_info.get("dust_numeric"),
            "temperature": weather_info.get("temperature"),
            "humidity": weather_info.get("humidity"),
            "uv": None,
            "pollen": pollen_info.get("pollen"),
            "weather": weather_info.get("weather"),
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "sources": {
                "weather": weather_info.get("source"),
                "air_quality": air_info.get("source"),
                "pollen": pollen_info.get("source"),
            },
            "availability": {
                "weather": bool(weather_info.get("available")),
                "air_quality": bool(air_info.get("available")),
                "pollen": bool(pollen_info.get("available")),
            },
            "errors": {
                "weather": weather_info.get("error"),
                "air_quality": air_info.get("error"),
                "pollen": pollen_info.get("error"),
            },
        }
        measured_fields = ["pm25", "pm10", "aqi_numeric", "temperature", "humidity", "uv", "pollen"]
        data["missing_fields"] = [field for field in measured_fields if data.get(field) is None]
        return data
