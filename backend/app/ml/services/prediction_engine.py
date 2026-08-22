"""
Unified Prediction Engine Interface and Implementations for OcuSense.
Supports MLPredictionEngine (primary) and RuleBasedPredictionEngine (fallback/comparison).
"""
import os
import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
try:
    import joblib
except ImportError:
    joblib = None

try:
    import numpy as np
except ImportError:
    np = None

from app.ml.data.schema import PredictionFeatures
# ModelExplainer is lazily imported inside MLPredictionEngine.predict
from app.config import settings

logger = logging.getLogger(__name__)

ARTIFACTS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models", "artifacts")
DEFAULT_MODEL_PATH = os.path.join(ARTIFACTS_DIR, "ocular_risk_v0.1_prototype.joblib")


class PredictionEngine(ABC):
    @abstractmethod
    def predict(self, features: PredictionFeatures) -> Dict[str, Any]:
        """
        Executes prediction and returns standardized risk payload.
        """
        pass


class MLPredictionEngine(PredictionEngine):
    """
    Primary Multivariable ML Prediction Engine.
    Uses trained model artifact with reproducible preprocessing and explainability.
    """
    def __init__(self, model_path: str = DEFAULT_MODEL_PATH):
        self.model_path = model_path
        self.bundle: Optional[Dict[str, Any]] = None
        self._load_or_train()

    def _load_or_train(self):
        if os.path.exists(self.model_path):
            try:
                self.bundle = joblib.load(self.model_path)
                logger.info(f"Loaded ML model version: {self.bundle.get('model_version')}")
                return
            except Exception as e:
                logger.warning(f"Failed to load existing model artifact: {e}")

        # Train baseline if artifact is not found
        try:
            from app.ml.models.trainer import train_and_evaluate
            logger.info("Training fresh baseline ML model artifact...")
            self.bundle = train_and_evaluate()
        except Exception as e:
            logger.error(f"Error during baseline model training: {e}")
            self.bundle = None

    def predict(self, features: PredictionFeatures) -> Dict[str, Any]:
        if not self.bundle:
            self._load_or_train()

        if not self.bundle:
            raise RuntimeError("ML model is unavailable.")

        preprocessor = self.bundle["preprocessor"]
        classifier = self.bundle["classifier"]
        feature_names = self.bundle["feature_names"]

        # 1. Convert Canonical Features to DataFrame
        raw_df = preprocessor.canonical_to_features_df(features)

        # 2. Scale & Encode features
        scaled_X = preprocessor.transform(raw_df)

        # 3. Predict Probability
        proba_classes = classifier.predict_proba(scaled_X)[0]
        # Class 1 is Flare
        risk_probability = float(np.round(proba_classes[1] if len(proba_classes) > 1 else proba_classes[0], 4))

        # 4. Stratify into Prototype Risk Bands
        low_th = settings.RISK_LOW_THRESHOLD
        high_th = settings.RISK_HIGH_THRESHOLD

        if risk_probability < low_th:
            risk_level = "LOW"
        elif risk_probability <= high_th:
            risk_level = "MODERATE"
        else:
            risk_level = "HIGH"

        # 5. Explainability: Top Contributing Factors
        from app.ml.models.explainer import ModelExplainer
        top_factors = ModelExplainer.explain_prediction(
            feature_names=feature_names,
            scaled_features=scaled_X,
            classifier=classifier,
            raw_df=raw_df,
            top_k=4
        )

        # 6. Literature-Informed Reference Comparison (For Contextual Annotations)
        def reference_payload(current: Optional[float], reference: float, unit: str) -> Dict[str, Any]:
            return {
                "current": current,
                "reference": reference,
                "unit": unit,
                "elevated": bool(current is not None and current > reference),
                "available": current is not None,
            }

        literature_refs = {
            "pm25": reference_payload(features.environment.pm25, settings.LITERATURE_PM25_REF, "µg/m³"),
            "pm10": reference_payload(features.environment.pm10, settings.LITERATURE_PM10_REF, "µg/m³"),
            "no2": reference_payload(features.environment.no2, settings.LITERATURE_NO2_REF, "µg/m³"),
            "o3": reference_payload(features.environment.o3, settings.LITERATURE_O3_REF, "µg/m³"),
            "humidity": reference_payload(features.environment.humidity, settings.LITERATURE_HUMIDITY_REF, "%"),
        }

        # 7. Low-Risk Preventive Guidance
        guidance = self._generate_guidance(risk_level, features)

        return {
            "engine": "ml",
            "risk_probability": risk_probability,
            "risk_score_percentage": int(np.round(risk_probability * 100)),
            "risk_level": risk_level,
            "prediction_window": settings.PREDICTION_WINDOW,
            "model_version": self.bundle.get("model_version", settings.MODEL_VERSION),
            "confidence": 0.85,
            "prediction_mode": "prototype_multivariable_ml",
            "top_contributing_features": top_factors,
            "literature_references": literature_refs,
            "preventive_guidance": guidance,
            "disclaimer": "Prototype AI risk estimate; not a diagnosis or clinically validated prediction."
        }

    def _generate_guidance(self, risk_level: str, features: PredictionFeatures) -> List[str]:
        if risk_level == "LOW":
            return [
                "Continue normal daily activities.",
                "Maintain routine ocular hygiene and hydration.",
                "Continue usual clinician-directed care."
            ]
        elif risk_level == "MODERATE":
            items = [
                "Monitor for increasing itchiness or redness.",
                "Reduce avoidable exposure to dust and high-traffic outdoor areas.",
                "Consider wearing wrap-around sunglasses outdoors to minimize particulate contact.",
                "Check daily environmental AQI and pollen forecasts."
            ]
            if features.symptoms.eye_rubbing > 0 or features.personalization.eye_rubbing_tendency:
                items.append("Avoid rubbing eyes; apply a cold compress if irritation occurs.")
            return items
        else:  # HIGH
            return [
                "Avoid peak outdoor exposure and high particulate dust environments where practical.",
                "Closely monitor ocular symptoms and keep lubricating / clinician-directed drops accessible.",
                "Use protective eyewear during necessary outdoor activities.",
                "Follow your existing clinician-directed allergy management plan.",
                "Seek qualified ophthalmologist assessment if severe symptoms, pain, or vision changes occur."
            ]


class RuleBasedPredictionEngine(PredictionEngine):
    """
    Fallback & Comparison Rule-Based Engine.
    Preserves existing rule logic to allow developer/research benchmark comparisons.
    """
    def predict(self, features: PredictionFeatures) -> Dict[str, Any]:
        env = features.environment
        symptoms = features.symptoms
        ocular = features.ocular

        raw_score = 0
        contributing_factors = []

        # Rule 1: High PM10/Dust + High Pollen + High Symptoms
        is_high_dust = (env.pm10 is not None and env.pm10 > 70) or features.exposure.indoor_dust >= 3.0
        is_high_pollen = str(env.pollen).lower() == "high"
        is_high_symptoms = symptoms.severity >= 6 or symptoms.itching >= 2

        if is_high_dust and is_high_pollen and is_high_symptoms:
            impact = 25
            raw_score += impact
            contributing_factors.append({
                "factor_key": "dust_pollen_symptom",
                "display_name": "Combined Dust & Pollen with Symptoms",
                "impact": impact,
                "reason": "Elevated dust and pollen coinciding with active ocular symptoms."
            })

        # Rule 2: High Humidity
        if env.humidity is not None and env.humidity >= 75:
            impact = 15
            raw_score += impact
            contributing_factors.append({
                "factor_key": "humidity",
                "display_name": "Elevated Humidity",
                "impact": impact,
                "reason": "High ambient humidity above 75% threshold."
            })

        # Rule 3: Eye Rubbing
        if symptoms.eye_rubbing > 0 or features.personalization.eye_rubbing_tendency:
            impact = 20
            raw_score += impact
            contributing_factors.append({
                "factor_key": "eye_rubbing",
                "display_name": "Eye Rubbing Habit",
                "impact": impact,
                "reason": "Mechanical friction increases ocular surface irritation."
            })

        # Rule 4: High AQI
        if env.aqi is not None and env.aqi > 100:
            impact = 15
            raw_score += impact
            contributing_factors.append({
                "factor_key": "aqi",
                "display_name": "Unhealthy Air Quality",
                "impact": impact,
                "reason": "Air Quality Index elevated above healthy levels."
            })

        # Rule 5: Objective Redness if detected
        if ocular.redness_score is not None and ocular.redness_score > 0.5:
            impact = 20
            raw_score += impact
            contributing_factors.append({
                "factor_key": "ocular_redness",
                "display_name": "Objective Redness Detected",
                "impact": impact,
                "reason": "Computer vision analysis detected conjunctival redness."
            })

        # Normalize score 0-100
        score = min(100, max(5, raw_score))
        probability = score / 100.0

        if probability < 0.25:
            level = "LOW"
        elif probability <= 0.55:
            level = "MODERATE"
        else:
            level = "HIGH"

        return {
            "engine": "rule_based",
            "risk_probability": float(np.round(probability, 2)),
            "risk_score_percentage": score,
            "risk_level": level,
            "prediction_window": "Current state heuristics",
            "model_version": "rule-based-engine-v1.0",
            "confidence": 0.60,
            "prediction_mode": "heuristic_rules",
            "top_contributing_features": contributing_factors,
            "preventive_guidance": [
                "Heuristic rule-based estimate for research reference.",
                "Consult clinical advice if symptoms persist."
            ],
            "disclaimer": "Rule-based heuristic estimation for research comparison."
        }


def get_prediction_engine(engine_type: Optional[str] = None) -> PredictionEngine:
    selected = engine_type or settings.PREDICTION_ENGINE
    if selected.lower() == "rule" or selected.lower() == "rule_based":
        return RuleBasedPredictionEngine()
    try:
        return MLPredictionEngine()
    except Exception as e:
        logger.warning(f"ML engine initialization failed ({e}), falling back to RuleBasedPredictionEngine.")
        return RuleBasedPredictionEngine()
