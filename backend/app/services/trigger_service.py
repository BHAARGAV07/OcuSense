from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
from app.config import settings
from app.models import DailyTriggerSnapshot
import datetime


class TriggerService:
    @staticmethod
    def _generate_demo_snapshots(patient_id: str) -> List[Dict[str, Any]]:
        """Generates realistic demo history (20 days) if DB history is empty for testing."""
        snapshots = []
        base_date = datetime.date.today() - datetime.timedelta(days=20)
        for i in range(20):
            current_date = base_date + datetime.timedelta(days=i)

            # High dust days (18 out of 20 days high dust in demo area)
            is_high_dust = i < 18
            # Symptomatic on 15 of those 18 high dust days -> association ~ 0.83
            had_symptoms = (is_high_dust and i % 6 != 0) or (not is_high_dust and i == 19)

            snapshots.append({
                "date": current_date.isoformat(),
                "had_symptoms": had_symptoms,
                "symptoms": ["itching", "redness"] if had_symptoms else [],
                "dust_level": "HIGH" if is_high_dust else "LOW",
                "pollen_level": "HIGH" if i % 2 == 0 else "MODERATE",
                "humidity": 78.0 if i % 3 == 0 else 60.0,
                "habits": ["eye_rubbing"] if i % 2 == 1 else []
            })
        return snapshots

    @classmethod
    def calculate_trigger_associations(
        cls,
        patient_id: str,
        db: Optional[Session] = None
    ) -> Dict[str, Any]:
        """
        Calculates daily snapshot factor association scores, lift, and confidence levels.
        """
        snapshots_data = []

        if db:
            try:
                db_snapshots = db.query(DailyTriggerSnapshot).filter(
                    DailyTriggerSnapshot.patient_id == patient_id
                ).all()
                for snap in db_snapshots:
                    snapshots_data.append({
                        "date": snap.date.isoformat() if snap.date else "",
                        "had_symptoms": snap.had_symptoms,
                        "symptoms": snap.symptoms or [],
                        "dust_level": snap.dust_level,
                        "pollen_level": snap.pollen_level,
                        "humidity": snap.humidity,
                        "habits": snap.habits or []
                    })
            except Exception:
                pass

        # If DB records are fewer than MIN_OBSERVATION_COUNT, provide seed/demo snapshots for testing
        if len(snapshots_data) < settings.MIN_OBSERVATION_COUNT:
            snapshots_data = cls._generate_demo_snapshots(patient_id)

        total_days = len(snapshots_data)
        if total_days == 0:
            return {"triggers": []}

        symptomatic_days = sum(1 for s in snapshots_data if s.get("had_symptoms"))
        baseline_prob = symptomatic_days / total_days if total_days > 0 else 0.0

        factors_to_check = [
            ("dust", lambda s: str(s.get("dust_level")).upper() == "HIGH"),
            ("pollen", lambda s: str(s.get("pollen_level")).upper() == "HIGH"),
            ("humidity", lambda s: float(s.get("humidity") or 0) >= settings.RISK_HUMIDITY_THRESHOLD),
            ("eye_rubbing", lambda s: "eye_rubbing" in [h.lower() for h in (s.get("habits") or [])])
        ]

        triggers_output = []

        for factor_name, condition_fn in factors_to_check:
            high_days = [s for s in snapshots_data if condition_fn(s)]
            observation_count = len(high_days)

            if observation_count == 0:
                association_score = 0.0
                lift = 0.0
                confidence = "insufficient data"
            else:
                symptomatic_high_days = sum(1 for s in high_days if s.get("had_symptoms"))
                association_score = round(symptomatic_high_days / observation_count, 2)
                lift = round(association_score / baseline_prob, 1) if baseline_prob > 0 else 1.0

                if observation_count < settings.MIN_OBSERVATION_COUNT:
                    confidence = "insufficient data"
                elif association_score >= 0.75 or lift >= 2.5:
                    confidence = "strong"
                elif association_score >= 0.50 or lift >= 1.5:
                    confidence = "moderate"
                else:
                    confidence = "low"

            triggers_output.append({
                "factor": factor_name,
                "association_score": association_score,
                "lift": lift,
                "confidence": confidence,
                "observation_count": observation_count
            })

        return {"triggers": triggers_output}
