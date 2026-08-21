"""
Interpretable Baseline Classifiers for OcuSense Flare Risk Prediction.
"""
from typing import Dict, Any, List, Tuple
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier


class OcuSenseRiskClassifier:
    """
    Interpretable baseline classifier. Defaults to regularized Logistic Regression,
    with Random Forest available for non-linear comparative benchmarking.
    """
    def __init__(self, model_type: str = "logistic_regression"):
        self.model_type = model_type
        if model_type == "random_forest":
            self.model = RandomForestClassifier(
                n_estimators=50,
                max_depth=3,
                min_samples_split=4,
                random_state=42,
                class_weight="balanced"
            )
        else:
            self.model = LogisticRegression(
                C=1.0,
                solver="liblinear",
                random_state=42,
                class_weight="balanced"
            )
        self.is_trained = False

    def fit(self, X: np.ndarray, y: np.ndarray) -> "OcuSenseRiskClassifier":
        self.model.fit(X, y)
        self.is_trained = True
        return self

    def predict_proba(self, X: np.ndarray) -> np.ndarray:
        if not self.is_trained:
            raise RuntimeError("Model is not trained.")
        return self.model.predict_proba(X)

    def predict(self, X: np.ndarray) -> np.ndarray:
        if not self.is_trained:
            raise RuntimeError("Model is not trained.")
        return self.model.predict(X)

    def get_feature_importances(self, feature_names: List[str]) -> List[Dict[str, Any]]:
        """
        Returns feature weights/importances ranked by magnitude.
        """
        if not self.is_trained:
            return []

        if hasattr(self.model, "coef_"):
            weights = self.model.coef_[0]
        elif hasattr(self.model, "feature_importances_"):
            weights = self.model.feature_importances_
        else:
            weights = np.zeros(len(feature_names))

        ranked = []
        for name, w in zip(feature_names, weights):
            ranked.append({
                "feature": name,
                "weight": float(np.round(w, 4)),
                "abs_weight": float(np.round(abs(w), 4))
            })
        ranked.sort(key=lambda x: x["abs_weight"], reverse=True)
        return ranked
