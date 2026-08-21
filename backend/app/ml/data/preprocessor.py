"""
Reproducible Preprocessing Pipeline for OcuSense ML.
Transforms raw tabular data or canonical PredictionFeatures into model-ready tensors.
"""
from typing import Dict, Any, List, Optional
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from app.ml.data.schema import DATASET_NUMERICAL_FEATURES, DATASET_CATEGORICAL_FEATURES, PredictionFeatures


class OcuSensePreprocessor:
    def __init__(self):
        self.scaler = StandardScaler()
        self.is_fitted = False
        self.feature_names = DATASET_NUMERICAL_FEATURES + ["Pollen_Encoded"]
        self.pollen_map = {"low": 0, "moderate": 1, "high": 2}

    def _encode_pollen(self, series: pd.Series) -> pd.Series:
        return series.astype(str).str.lower().map(lambda x: self.pollen_map.get(x, 1))

    def fit(self, df: pd.DataFrame) -> "OcuSensePreprocessor":
        """
        Fits the preprocessor scaler on the training dataframe.
        """
        df_copy = df.copy()
        
        # Ensure numerical features are present and filled
        for col in DATASET_NUMERICAL_FEATURES:
            if col not in df_copy.columns:
                df_copy[col] = 0.0
            else:
                df_copy[col] = pd.to_numeric(df_copy[col], errors="coerce").fillna(0.0)

        # Encode categorical Pollen
        if "Pollen" in df_copy.columns:
            df_copy["Pollen_Encoded"] = self._encode_pollen(df_copy["Pollen"])
        else:
            df_copy["Pollen_Encoded"] = 1

        X_num = df_copy[self.feature_names].values
        self.scaler.fit(X_num)
        self.is_fitted = True
        return self

    def transform(self, df: pd.DataFrame) -> np.ndarray:
        """
        Transforms dataframe to scaled feature matrix.
        """
        if not self.is_fitted:
            raise RuntimeError("OcuSensePreprocessor must be fitted before calling transform().")

        df_copy = df.copy()
        for col in DATASET_NUMERICAL_FEATURES:
            if col not in df_copy.columns:
                df_copy[col] = 0.0
            else:
                df_copy[col] = pd.to_numeric(df_copy[col], errors="coerce").fillna(0.0)

        if "Pollen" in df_copy.columns:
            df_copy["Pollen_Encoded"] = self._encode_pollen(df_copy["Pollen"])
        else:
            df_copy["Pollen_Encoded"] = 1

        X_num = df_copy[self.feature_names].values
        return self.scaler.transform(X_num)

    def fit_transform(self, df: pd.DataFrame) -> np.ndarray:
        return self.fit(df).transform(df)

    def canonical_to_features_df(self, canonical: PredictionFeatures) -> pd.DataFrame:
        """
        Maps the canonical PredictionFeatures object into a single-row DataFrame.
        """
        # Objective ocular redness index (0.0 to 1.0) maps to 0-3 scale or direct redness if video checked
        symptoms = canonical.symptoms
        env = canonical.environment
        exposure = canonical.exposure
        ocular = canonical.ocular

        # Blend objective redness score with subjective redness if objective is available
        redness_val = float(symptoms.redness)
        if ocular.redness_score is not None:
            # Map [0.0, 1.0] to [0.0, 3.0] scale
            redness_val = float(np.clip(ocular.redness_score * 3.0, 0.0, 3.0))

        def optional_float(value: Optional[float]) -> float:
            return float(value) if value is not None else np.nan

        row_dict = {
            "Itching": float(symptoms.itching),
            "Redness": redness_val,
            "Watering": float(symptoms.watering),
            "Irritation": float(symptoms.irritation),
            "Severity": float(symptoms.severity if symptoms.severity > 0 else (symptoms.itching + symptoms.watering + symptoms.redness + symptoms.irritation)),
            "PM2.5": optional_float(env.pm25),
            "PM10": optional_float(env.pm10),
            "AQI": optional_float(env.aqi),
            "Temperature": optional_float(env.temperature),
            "Humidity": optional_float(env.humidity),
            "Outdoor_Exposure": float(exposure.outdoor_exposure),
            "Indoor_Dust": float(exposure.indoor_dust),
            "Pollen": env.pollen if env.pollen is not None else "Unknown"
        }
        return pd.DataFrame([row_dict])
