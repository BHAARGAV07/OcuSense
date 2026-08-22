"""
RESEARCH / LEGACY RULE-BASED ENGINE.

This module is preserved for developer comparison tests only. It must not be
used as the primary /api/analysis/risk calculation path.
"""

from typing import Dict, Any
from app.config import settings

# Configurable Rule Weights
WEIGHT_DUST_POLLEN_SYMPTOM = 25
WEIGHT_HUMIDITY_RISING_SYMPTOMS = 15
WEIGHT_HIGH_AQI = 15
WEIGHT_EYE_RUBBING_HABIT = 20

DUST_HIGH_THRESHOLD = 300  # Numeric dust threshold or string "high"


class RuleEngine:
    @staticmethod
    def evaluate_rules(combined_data: Dict[str, Any], observation_count: int = 10) -> Dict[str, Any]:
        """
        Evaluates normalized combined data (Phase 6) against configurable rules.
        Works identically regardless of whether hardware data was mocked or real.
        """
        patient = combined_data.get("patient", {})
        env_api = combined_data.get("environment_api", {})
        env_hw = combined_data.get("environment_hardware", {})

        # Extract normalized values (hardware takes precedence if available)
        humidity = env_hw.get("humidity", env_api.get("humidity", 0))
        dust_val = env_hw.get("dust", env_api.get("dust_numeric", 0))
        dust_level = "high" if (isinstance(dust_val, (int, float)) and dust_val > DUST_HIGH_THRESHOLD) or str(dust_val).lower() == "high" else "moderate"
        pollen_level = str(env_api.get("pollen", "")).lower()
        symptom_severity = str(patient.get("symptom_severity", "")).upper()
        recent_symptoms_increased = bool(patient.get("recent_symptoms_increased", False))
        habits = [h.lower() for h in patient.get("habits", [])]

        contributing_factors = []
        raw_score = 0

        # Apply MIN_OBSERVATION_COUNT guardrail from config
        insufficient_data = observation_count < settings.MIN_OBSERVATION_COUNT

        # Rule 1: High Dust + High Pollen + High Symptom Severity
        if dust_level == "high" and pollen_level == "high" and symptom_severity == "HIGH":
            impact = WEIGHT_DUST_POLLEN_SYMPTOM
            raw_score += impact
            contributing_factors.append({
                "factor": "dust",
                "impact": impact,
                "reason": "High dust + high pollen + high symptoms",
                "confidence": "insufficient data" if insufficient_data else "strong"
            })

        # Rule 2: High Humidity + Recent Symptoms Increased
        if humidity >= settings.RISK_HUMIDITY_THRESHOLD and recent_symptoms_increased:
            impact = WEIGHT_HUMIDITY_RISING_SYMPTOMS
            raw_score += impact
            contributing_factors.append({
                "factor": "humidity",
                "impact": impact,
                "reason": "High humidity coincided with rising symptoms",
                "confidence": "insufficient data" if insufficient_data else "moderate"
            })

        # Rule 3: Eye Rubbing Habit logged
        if "eye_rubbing" in habits or "eye rubbing" in habits:
            impact = WEIGHT_EYE_RUBBING_HABIT
            raw_score += impact
            contributing_factors.append({
                "factor": "eye_rubbing",
                "impact": impact,
                "reason": "Frequent eye rubbing detected, risking mechanical corneal trauma",
                "confidence": "insufficient data" if insufficient_data else "strong"
            })

        # Rule 4: High AQI
        aqi_level = str(env_api.get("aqi", "")).lower()
        if aqi_level == "high" or aqi_level == "very high":
            impact = WEIGHT_HIGH_AQI
            raw_score += impact
            contributing_factors.append({
                "factor": "aqi",
                "impact": impact,
                "reason": "Unhealthy AQI levels causing ocular surface irritation",
                "confidence": "insufficient data" if insufficient_data else "moderate"
            })

        return {
            "raw_score": raw_score,
            "contributing_factors": contributing_factors,
            "insufficient_data": insufficient_data,
            "observation_count": observation_count
        }
