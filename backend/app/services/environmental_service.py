import logging
from typing import Dict, Any, Optional
import httpx
from app.config import settings

logger = logging.getLogger(__name__)


class EnvironmentalDataService:
    @staticmethod
    async def fetch_open_meteo_weather(lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Fetch weather and humidity data from Open-Meteo free API."""
        try:
            url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,weather_code"
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(url)
                if resp.status_code == 200:
                    data = resp.json().get("current", {})
                    return {
                        "temperature": data.get("temperature_2m", 29.5),
                        "humidity": data.get("relative_humidity_2m", 68),
                        "weather_code": data.get("weather_code", 0),
                        "weather": "Sunny" if data.get("weather_code", 0) <= 3 else "Cloudy"
                    }
        except Exception as e:
            logger.warning(f"Failed to fetch Open-Meteo weather data: {e}")

        # Fallback values
        return {
            "temperature": 30.0,
            "humidity": 65,
            "weather_code": 0,
            "weather": "Sunny"
        }

    @staticmethod
    async def fetch_open_meteo_air_quality(lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Fetch dust (pm10/pm2_5) and AQI from Open-Meteo Air Quality API."""
        try:
            url = f"https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}&current=pm10,pm2_5,us_aqi,dust"
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(url)
                if resp.status_code == 200:
                    data = resp.json().get("current", {})
                    dust_val = data.get("pm10", data.get("dust", 350))
                    aqi_val = data.get("us_aqi", 85)
                    return {
                        "dust": "high" if dust_val > 300 else ("moderate" if dust_val > 100 else "low"),
                        "dust_numeric": dust_val,
                        "aqi": "high" if aqi_val > 150 else ("moderate" if aqi_val > 50 else "low"),
                        "aqi_numeric": aqi_val
                    }
        except Exception as e:
            logger.warning(f"Failed to fetch Open-Meteo air quality: {e}")

        return {
            "dust": "high",
            "dust_numeric": 380,
            "aqi": "moderate",
            "aqi_numeric": 85
        }

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
                        return {"pollen": max_category, "raw": daily_info}
            except Exception as e:
                logger.warning(f"Failed to fetch Google Pollen API: {e}")

        # Fallback value
        return {"pollen": "high"}

    @classmethod
    async def get_environmental_data(cls, lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Combine external environmental API sources into a single normalized dict."""
        weather_info = await cls.fetch_open_meteo_weather(lat, lon)
        air_info = await cls.fetch_open_meteo_air_quality(lat, lon)
        pollen_info = await cls.fetch_google_pollen(lat, lon)

        return {
            "pollen": pollen_info.get("pollen", "high"),
            "aqi": air_info.get("aqi", "moderate"),
            "dust": air_info.get("dust", "high"),
            "dust_numeric": air_info.get("dust_numeric", 380),
            "humidity": weather_info.get("humidity", 65),
            "temperature": weather_info.get("temperature", 30.0),
            "weather": weather_info.get("weather", "Sunny")
        }
