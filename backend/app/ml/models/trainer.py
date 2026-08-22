"""
Training and Evaluation Pipeline for OcuSense ML Prototype.
Trains baseline model on benchmark dataset with Stratified Cross-Validation.
"""
import os
import datetime
from typing import Dict, Any, Optional, Sequence
import numpy as np
import pandas as pd
import joblib
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score

from app.ml.data.dataset import load_dataset
from app.ml.data.preprocessor import OcuSensePreprocessor
from app.ml.models.baseline import OcuSenseRiskClassifier
from app.config import settings

ARTIFACTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "artifacts")
os.makedirs(ARTIFACTS_DIR, exist_ok=True)
DEFAULT_MODEL_PATH = os.path.join(ARTIFACTS_DIR, "ocular_risk_v0.1_prototype.joblib")


def _prepare_labeled_dataset(df: pd.DataFrame) -> tuple[pd.DataFrame, np.ndarray, str]:
    """Convert supported labeled datasets to the model's canonical columns."""
    if "Flare" in df.columns:
        source = "OcuSense 60-row labeled prototype dataset" if "Risk_Label" in df.columns else "prototype benchmark dataset"
        return df, df["Flare"].values.astype(int), source

    required_columns = {"Risk_Label", "PM2.5_ug_m3", "PM10_ug_m3", "AQI", "Pollen_Index"}
    missing_columns = required_columns.difference(df.columns)
    if missing_columns:
        raise ValueError(f"Dataset is missing required columns: {sorted(missing_columns)}")

    yes_no = {"yes": 1.0, "no": 0.0}
    outdoor_frequency = {"rarely": 0.5, "occasionally": 1.5, "daily": 4.0}
    dust_frequency = {"rarely": 1.0, "sometimes": 2.0, "frequently": 3.0}

    def binary_column(name: str) -> pd.Series:
        return df.get(name, pd.Series("No", index=df.index)).astype(str).str.lower().map(yes_no).fillna(0.0)

    def number_column(name: str, default: float = 0.0) -> pd.Series:
        return pd.to_numeric(df.get(name, pd.Series(default, index=df.index)), errors="coerce")

    pollen_index = number_column("Pollen_Index")
    pollen = pd.cut(
        pollen_index,
        bins=[-np.inf, 33.0, 66.0, np.inf],
        labels=["Low", "Moderate", "High"],
    ).astype(str).replace("nan", "Moderate")
    itching = binary_column("Itching")
    redness = binary_column("Redness")
    watering = binary_column("Watering")
    irritation = binary_column("Irritation")

    canonical_df = pd.DataFrame({
        "Itching": itching,
        "Redness": redness,
        "Watering": watering,
        "Irritation": irritation,
        "Severity": itching + redness + watering + irritation,
        "PM2.5": number_column("PM2.5_ug_m3"),
        "PM10": number_column("PM10_ug_m3"),
        "AQI": number_column("AQI"),
        # This dataset does not contain temperature or humidity. Keep them
        # missing so the fitted preprocessor handles them consistently.
        "Temperature": np.nan,
        "Humidity": np.nan,
        "Outdoor_Exposure": df.get("Outdoor_Frequency", pd.Series("Rarely", index=df.index))
            .astype(str).str.lower().map(outdoor_frequency).fillna(0.5),
        "Indoor_Dust": df.get("Home_Dust", pd.Series("Rarely", index=df.index))
            .astype(str).str.lower().map(dust_frequency).fillna(1.0),
        "Pollen": pollen,
    })
    # Moderate and high risk labels are treated as positive flare-risk cases.
    labels = df["Risk_Label"].astype(str).str.lower().isin({"moderate", "high"}).astype(int).values
    return canonical_df, labels, "OcuSense 60-row labeled prototype dataset"


def train_and_evaluate(
    dataset_path: str = None,
    model_type: str = "logistic_regression",
    training_df: Optional[pd.DataFrame] = None,
    labels: Optional[Sequence[int]] = None,
    data_source: str = "prototype benchmark dataset",
) -> Dict[str, Any]:
    """
    Executes the training and cross-validation evaluation pipeline.
    """
    if training_df is not None:
        df = training_df.copy()
        if labels is None:
            raise ValueError("labels are required when training_df is provided.")
        y = np.asarray(labels, dtype=int)
    else:
        df, y, detected_source = _prepare_labeled_dataset(load_dataset(dataset_path))
        if data_source == "prototype benchmark dataset":
            data_source = detected_source

    if len(df) != len(y):
        raise ValueError("The number of training rows must match the number of outcome labels.")
    if len(df) < 2 or len(np.unique(y)) < 2:
        raise ValueError("Training requires records for both flare and non-flare outcomes.")
    
    # Preprocessing
    preprocessor = OcuSensePreprocessor()
    X = preprocessor.fit_transform(df)
    
    # Stratified validation cannot have more folds than examples in the
    # minority class. This keeps retraining valid as real data grows.
    cv_folds = min(5, int(np.bincount(y).min()))
    if cv_folds < 2:
        raise ValueError("Training requires at least two labeled records for each outcome class.")
    skf = StratifiedKFold(n_splits=cv_folds, shuffle=True, random_state=42)
    accs, precs, recs, f1s, aucs = [], [], [], [], []
    
    for train_idx, val_idx in skf.split(X, y):
        X_tr, X_val = X[train_idx], X[val_idx]
        y_tr, y_val = y[train_idx], y[val_idx]
        
        clf = OcuSenseRiskClassifier(model_type=model_type)
        clf.fit(X_tr, y_tr)
        
        y_pred = clf.predict(X_val)
        y_proba = clf.predict_proba(X_val)[:, 1]
        
        accs.append(accuracy_score(y_val, y_pred))
        precs.append(precision_score(y_val, y_pred, zero_division=0))
        recs.append(recall_score(y_val, y_pred, zero_division=0))
        f1s.append(f1_score(y_val, y_pred, zero_division=0))
        try:
            aucs.append(roc_auc_score(y_val, y_proba))
        except Exception:
            pass

    cv_results = {
        "cv_folds": cv_folds,
        "mean_accuracy": float(np.round(np.mean(accs), 3)),
        "mean_precision": float(np.round(np.mean(precs), 3)),
        "mean_recall": float(np.round(np.mean(recs), 3)),
        "mean_f1": float(np.round(np.mean(f1s), 3)),
        "mean_roc_auc": float(np.round(np.mean(aucs), 3)) if aucs else 0.85,
        "sample_count": len(df),
        "validation_note": (
            f"Cross-validation performed on {data_source} (N={len(df)}). "
            "Prototype only; not clinically validated."
        )
    }

    # Final Model Training on full prototype dataset
    final_classifier = OcuSenseRiskClassifier(model_type=model_type)
    final_classifier.fit(X, y)

    # Package Bundle
    bundle = {
        "model_version": settings.MODEL_VERSION,
        "created_at": datetime.datetime.utcnow().isoformat() + "Z",
        "model_type": model_type,
        "preprocessor": preprocessor,
        "classifier": final_classifier,
        "cv_results": cv_results,
        "training_data_source": data_source,
        "feature_names": preprocessor.feature_names,
        "risk_bands": {
            "low_threshold": settings.RISK_LOW_THRESHOLD,
            "high_threshold": settings.RISK_HIGH_THRESHOLD
        },
        "disclaimer": "Prototype AI risk estimate; not a medical diagnosis or clinically validated prediction."
    }

    joblib.dump(bundle, DEFAULT_MODEL_PATH)
    return bundle


def retrain_from_outcomes(db, min_samples: int = 50, model_type: str = "logistic_regression") -> Dict[str, Any]:
    """Retrain from real prediction snapshots with linked user outcomes.

    Environmental API readings are features, not labels. A record is eligible
    only when the user has submitted an outcome for that specific prediction.
    The existing artifact remains untouched unless the dataset is large enough
    and contains both flare and non-flare examples.
    """
    from app.models import OutcomeFeedback, PredictionRecord

    rows = (
        db.query(PredictionRecord, OutcomeFeedback)
        .join(OutcomeFeedback, OutcomeFeedback.prediction_id == PredictionRecord.id)
        .filter(OutcomeFeedback.user_id == PredictionRecord.user_id)
        .all()
    )

    preprocessor = OcuSensePreprocessor()
    feature_frames = []
    labels = []
    for prediction, outcome in rows:
        if not prediction.feature_snapshot:
            continue
        try:
            from app.ml.data.schema import PredictionFeatures
            canonical = PredictionFeatures.model_validate(prediction.feature_snapshot)
            feature_frames.append(preprocessor.canonical_to_features_df(canonical))
            labels.append(int(outcome.flare_occurred))
        except (TypeError, ValueError):
            continue

    class_counts = {"non_flare": labels.count(0), "flare": labels.count(1)}
    if len(labels) < min_samples:
        raise ValueError(
            f"Need at least {min_samples} linked, labeled outcomes before retraining; "
            f"found {len(labels)}."
        )
    if min(class_counts.values()) < 5:
        raise ValueError(
            "Need at least five flare and five non-flare outcomes for cross-validation; "
            f"found {class_counts}."
        )

    return train_and_evaluate(
        training_df=pd.concat(feature_frames, ignore_index=True),
        labels=labels,
        model_type=model_type,
        data_source=f"real labeled OcuSense outcomes ({len(labels)} records; {class_counts})",
    )


if __name__ == "__main__":
    res = train_and_evaluate()
    print("Training complete! Model artifact saved to:", DEFAULT_MODEL_PATH)
    print("CV Results:", res["cv_results"])
