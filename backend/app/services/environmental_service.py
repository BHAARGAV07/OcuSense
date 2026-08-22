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
                logger.warning("Open-Meteo weather failed: status=%s endpoint=/v1/forecast", resp.status_code)
                return EnvironmentalDataService._unavailable(fields, "open-meteo-weather", f"HTTP {resp.status_code}")
        except Exception as e:
            logger.warning("Open-Meteo weather failed: endpoint=/v1/forecast error=%s", e)
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
                logger.warning("Open-Meteo air quality failed: status=%s endpoint=/v1/air-quality", resp.status_code)
                return EnvironmentalDataService._unavailable(fields, "open-meteo-air-quality", f"HTTP {resp.status_code}")
        except Exception as e:
            logger.warning("Open-Meteo air quality failed: endpoint=/v1/air-quality error=%s", e)
            return EnvironmentalDataService._unavailable(fields, "open-meteo-air-quality", str(e))

        return EnvironmentalDataService._unavailable(fields, "open-meteo-air-quality")

    @staticmethod
    def _pollutant_value_ug_m3(pollutant: Dict[str, Any]) -> Optional[float]:
        concentration = pollutant.get("concentration") or {}
        value = concentration.get("value")
        units = str(concentration.get("units", "")).upper()
        code = str(pollutant.get("code", "")).lower()
        if value is None:
            return None
        try:
            numeric = float(value)
        except (TypeError, ValueError):
            return None
        if units == "PARTS_PER_BILLION":
            # Approximate 25 C conversions: ug/m3 = ppb * molecular weight / 24.45.
            if code == "no2":
                return numeric * 1.88
            if code == "o3":
                return numeric * 2.00
        return numeric

    @staticmethod
    def _extract_air_quality_values(item: Dict[str, Any]) -> Dict[str, Optional[float]]:
        values: Dict[str, Optional[float]] = {"pm25": None, "pm10": None, "no2": None, "o3": None, "aqi_numeric": None}
        for index in item.get("indexes", []) or []:
            if str(index.get("code", "")).lower() == "uaqi":
                values["aqi_numeric"] = index.get("aqi")
                break
        for pollutant in item.get("pollutants", []) or []:
            code = str(pollutant.get("code", "")).lower()
            if code in {"pm25", "pm10", "no2", "o3"}:
                values[code] = EnvironmentalDataService._pollutant_value_ug_m3(pollutant)
        return values

    @staticmethod
    async def fetch_google_air_quality_forecast(lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Fetch Google Air Quality forecast values for the 24-72 hour risk window."""
        fields = ["pm25", "pm10", "no2", "o3", "aqi", "aqi_numeric", "dust", "dust_numeric"]
        key = settings.GOOGLE_AIR_QUALITY_API_KEY
        if not key or key == "string":
            return EnvironmentalDataService._unavailable(fields, "google-air-quality-forecast", "GOOGLE_AIR_QUALITY_API_KEY not configured")

        now = datetime.datetime.now(datetime.timezone.utc)
        start = (now + datetime.timedelta(hours=24)).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        end = (now + datetime.timedelta(hours=72)).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        url = f"https://airquality.googleapis.com/v1/forecast:lookup?key={key}"
        body = {
            "location": {"latitude": lat, "longitude": lon},
            "period": {"startTime": start, "endTime": end},
            "pageSize": 72,
            "universalAqi": True,
            "languageCode": "en",
            "extraComputations": ["POLLUTANT_CONCENTRATION", "DOMINANT_POLLUTANT_CONCENTRATION"],
        }
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                resp = await client.post(url, json=body)
                if resp.status_code != 200:
                    logger.warning(
                        "Google Air Quality API failed: status=%s endpoint=/v1/forecast:lookup",
                        resp.status_code,
                    )
                    return EnvironmentalDataService._unavailable(fields, "google-air-quality-forecast", f"HTTP {resp.status_code}")
                hourly = resp.json().get("hourlyForecasts", [])
                if not hourly:
                    return EnvironmentalDataService._unavailable(fields, "google-air-quality-forecast", "No hourlyForecasts returned")

                extracted = [EnvironmentalDataService._extract_air_quality_values(item) for item in hourly]

                def max_available(name: str) -> Optional[float]:
                    vals = [item.get(name) for item in extracted if item.get(name) is not None]
                    return float(max(vals)) if vals else None

                pm10 = max_available("pm10")
                aqi_val = max_available("aqi_numeric")
                return {
                    "pm25": max_available("pm25"),
                    "pm10": pm10,
                    "no2": max_available("no2"),
                    "o3": max_available("o3"),
                    "aqi": "high" if aqi_val and aqi_val > 150 else ("moderate" if aqi_val and aqi_val > 50 else ("low" if aqi_val is not None else None)),
                    "aqi_numeric": aqi_val,
                    "dust": "high" if pm10 and pm10 > 70 else ("moderate" if pm10 and pm10 > 35 else ("low" if pm10 is not None else None)),
                    "dust_numeric": pm10,
                    "forecast_window": "24-72 hours",
                    "forecast_points": len(hourly),
                    "available": True,
                    "source": "google-air-quality-forecast",
                    "error": None,
                }
        except Exception as e:
            logger.warning("Google Air Quality API failed: endpoint=/v1/forecast:lookup error=%s", e)
            return EnvironmentalDataService._unavailable(fields, "google-air-quality-forecast", str(e))

    @staticmethod
    async def fetch_google_pollen(lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Fetch pollen levels from Google Pollen API using server API key."""
        fields = ["pollen", "pollen_index"]
        key = settings.GOOGLE_POLLEN_API_KEY
        if key and key != "string":
            try:
                url = f"https://pollen.googleapis.com/v1/forecast:lookup?key={key}&location.latitude={lat}&location.longitude={lon}&days=3"
                async with httpx.AsyncClient(timeout=5.0) as client:
                    resp = await client.get(url)
                    if resp.status_code == 200:
                        data = resp.json()
                        daily_items = data.get("dailyInfo", [])
                        max_category = "low"
                        max_index = None
                        for daily_info in daily_items:
                            plant_info = daily_info.get("pollenTypeInfo", [])
                            for p in plant_info:
                                index_info = p.get("indexInfo", {})
                                cat = index_info.get("category", "").lower()
                                val = index_info.get("value")
                                if val is not None:
                                    max_index = max(float(val), max_index or 0.0)
                                if "high" in cat or "very_high" in cat:
                                    max_category = "high"
                                elif "moderate" in cat and max_category != "high":
                                    max_category = "moderate"
                        return {
                            "pollen": max_category,
                            "pollen_index": max_index,
                            "raw": daily_items[:3],
                            "available": True,
                            "source": "google-pollen",
                            "error": None,
                        }
                    logger.warning(
                        "Google Pollen API failed: status=%s endpoint=/v1/forecast:lookup",
                        resp.status_code,
                    )
                    return EnvironmentalDataService._unavailable(fields, "google-pollen", f"HTTP {resp.status_code}")
            except Exception as e:
                logger.warning("Google Pollen API failed: endpoint=/v1/forecast:lookup error=%s", e)
                return EnvironmentalDataService._unavailable(fields, "google-pollen", str(e))

        return EnvironmentalDataService._unavailable(fields, "google-pollen", "GOOGLE_POLLEN_API_KEY not configured")

    @classmethod
    async def get_environmental_data(cls, lat: float = 13.0827, lon: float = 80.2707) -> Dict[str, Any]:
        """Combine external environmental API sources into a single normalized dict."""
        weather_info = await cls.fetch_open_meteo_weather(lat, lon)
        google_air_info = await cls.fetch_google_air_quality_forecast(lat, lon)
        fallback_air_info = None if google_air_info.get("available") else await cls.fetch_open_meteo_air_quality(lat, lon)
        air_info = google_air_info if google_air_info.get("available") else fallback_air_info
        pollen_info = await cls.fetch_google_pollen(lat, lon)

        data = {
            "pm25": air_info.get("pm25"),
            "pm10": air_info.get("pm10"),
            "no2": air_info.get("no2"),
            "o3": air_info.get("o3"),
            "aqi": air_info.get("aqi"),
            "aqi_numeric": air_info.get("aqi_numeric"),
            "dust": air_info.get("dust"),
            "dust_numeric": air_info.get("dust_numeric"),
            "temperature": weather_info.get("temperature"),
            "humidity": weather_info.get("humidity"),
            "uv": None,
            "pollen": pollen_info.get("pollen"),
            "pollen_index": pollen_info.get("pollen_index"),
            "weather": weather_info.get("weather"),
            "lat": lat,
            "lon": lon,
            "forecast_window": air_info.get("forecast_window", "current"),
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
        measured_fields = ["pm25", "pm10", "no2", "o3", "aqi_numeric", "temperature", "humidity", "uv", "pollen", "pollen_index"]
        data["missing_fields"] = [field for field in measured_fields if data.get(field) is None]
        return data
