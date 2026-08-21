import datetime
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session

from app.services.hardware_service import get_hardware_reading
from app.services.environmental_service import EnvironmentalDataService
from app.models import SymptomLog, HabitLog


class DataAggregationService:
    @staticmethod
    async def get_combined_data(
        patient_id: str,
        db: Optional[Session] = None,
        lat: float = 13.0827,
        lon: float = 80.2707
    ) -> Dict[str, Any]:
        """
        Pull together patient inputs, external environmental data,
        and mocked hardware reading into one normalized object.
        """
        # 1. Fetch Patient Input from DB (or fallback test data)
        patient_data = {
            "patient_id": patient_id,
            "symptoms": ["itching", "redness", "watering"],
            "symptom_severity": "HIGH",
            "symptom_severity_score": 8,
            "habits": ["eye_rubbing"],
            "recent_symptoms_increased": True
        }

        if db:
            try:
                latest_symptom = db.query(SymptomLog).filter(SymptomLog.patient_id == patient_id).order_by(SymptomLog.timestamp.desc()).first()
                latest_habit = db.query(HabitLog).filter(HabitLog.patient_id == patient_id).order_by(HabitLog.timestamp.desc()).first()

                if latest_symptom:
                    patient_data["symptoms"] = latest_symptom.symptoms or patient_data["symptoms"]
                    patient_data["symptom_severity"] = latest_symptom.severity or patient_data["symptom_severity"]
                    patient_data["symptom_severity_score"] = latest_symptom.severity_score or patient_data["symptom_severity_score"]
                    patient_data["recent_symptoms_increased"] = latest_symptom.recent_symptoms_increased

                if latest_habit:
                    patient_data["habits"] = latest_habit.habits or patient_data["habits"]
            except Exception:
                pass  # Use fallback test data if DB query fails

        # 2. Fetch External Environmental API Data
        env_api_data = await EnvironmentalDataService.get_environmental_data(lat=lat, lon=lon)

        # 3. Fetch Hardware Reading (Mock function)
        env_hw_data = get_hardware_reading()

        # 4. Return Normalized Combined Object
        return {
            "patient": patient_data,
            "environment_api": env_api_data,
            "environment_hardware": env_hw_data,
            "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
        }
