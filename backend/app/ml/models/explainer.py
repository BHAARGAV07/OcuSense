"""
Model Explainability Module for OcuSense.
Explains predictions by computing localized feature contributions without asserting causality.
"""
from typing import List, Dict, Any
import numpy as np
import pandas as pd


FEATURE_DISPLAY_NAMES = {
    "Itching": "Ocular Itching",
    "Redness": "Ocular Redness",
    "Watering": "Lacrimation (Watering)",
    "Irritation": "Ocular Irritation",
    "Severity": "Overall Symptom Severity",
    "PM2.5": "Elevated PM2.5 Exposure",
    "PM10": "Elevated PM10 Exposure",
    "AQI": "Air Quality Index (AQI)",
    "Temperature": "Ambient Temperature",
    "Humidity": "High Ambient Humidity",
    "Outdoor_Exposure": "Prolonged Outdoor Exposure",
    "Indoor_Dust": "Indoor Dust Exposure",
    "Pollen_Encoded": "Pollen Concentration"
}

FEATURE_CONTEXT_EXPLANATIONS = {
    "Redness": "Objective/reported ocular erythema is correlated with active conjunctival inflammation.",
    "Itching": "Pruritus is a key hallmark of mast cell histamine release in ocular allergy.",
    "PM2.5": "Fine particulate matter is associated with increased ocular surface irritation in statistical models.",
    "PM10": "Coarse particulate matter is linked to mechanical barrier stress and flare risk.",
    "Humidity": "Elevated relative humidity is statistically associated with mold/allergen activity in coastal climates.",
    "Pollen_Encoded": "Elevated ambient pollen is a primary seasonal flare contributor.",
    "Outdoor_Exposure": "Extended outdoor time increases cumulative exposure to airborne aeroallergens.",
    "Indoor_Dust": "Indoor dust exposure contributes to perennial allergic triggers.",
    "Watering": "Excess tearing reflects reflex lacrimation and ocular surface response.",
    "Irritation": "Discomfort indicates ocular surface barrier disruption."
}


class ModelExplainer:
    @staticmethod
    def explain_prediction(
        feature_names: List[str],
        scaled_features: np.ndarray,
        classifier: Any,
        raw_df: pd.DataFrame,
        top_k: int = 4
    ) -> List[Dict[str, Any]]:
        """
        Computes localized contributions for each feature:
        contribution = scaled_feature_val * model_weight (for linear models)
        or scaled_feature_deviation * feature_importance (for tree models).
        """
        contributions = []
        vec = scaled_features[0]

        if hasattr(classifier.model, "coef_"):
            weights = classifier.model.coef_[0]
            for i, name in enumerate(feature_names):
                raw_val = raw_df[name.replace("_Encoded", "")].iloc[0] if name.replace("_Encoded", "") in raw_df else 0
                contrib = float(vec[i] * weights[i])
                contributions.append({
                    "factor_key": name,
                    "display_name": FEATURE_DISPLAY_NAMES.get(name, name),
                    "impact": float(np.round(contrib, 3)),
                    "direction": "increases_risk" if contrib > 0 else "decreases_risk",
                    "reason": FEATURE_CONTEXT_EXPLANATIONS.get(
                        name,
                        f"{FEATURE_DISPLAY_NAMES.get(name, name)} contributed to this model's statistical estimate."
                    ),
                    "raw_value": str(raw_val)
                })
        else:
            # Random forest feature importances weighted by absolute deviation
            importances = classifier.model.feature_importances_
            for i, name in enumerate(feature_names):
                raw_val = raw_df[name.replace("_Encoded", "")].iloc[0] if name.replace("_Encoded", "") in raw_df else 0
                contrib = float(abs(vec[i]) * importances[i])
                contributions.append({
                    "factor_key": name,
                    "display_name": FEATURE_DISPLAY_NAMES.get(name, name),
                    "impact": float(np.round(contrib, 3)),
                    "direction": "increases_risk" if vec[i] > 0 else "decreases_risk",
                    "reason": FEATURE_CONTEXT_EXPLANATIONS.get(
                        name,
                        f"{FEATURE_DISPLAY_NAMES.get(name, name)} was an important factor in this estimate."
                    ),
                    "raw_value": str(raw_val)
                })

        # Sort by positive risk contribution first
        contributions.sort(key=lambda x: x["impact"], reverse=True)
        return contributions[:top_k]
