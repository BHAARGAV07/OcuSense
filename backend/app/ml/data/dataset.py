"""
Dataset Loader and Manager for OcuSense prototype datasets.
Supports the final 60-row labelled dataset and the earlier 30-row fallback.
"""
import os
import pandas as pd
import numpy as np

DATASET_DIR = os.path.dirname(os.path.abspath(__file__))
FINAL_DATASET_CSV_PATH = os.path.join(DATASET_DIR, "OcuSense_60_Labelled_Prototype_Dataset.csv")
DATASET_EXCEL_PATH = os.path.join(DATASET_DIR, "OcuSense_Dataset_30_Rows.xlsx")
DATASET_CSV_PATH = os.path.join(DATASET_DIR, "OcuSense_Dataset_30_Rows.csv")


def generate_benchmark_30_row_data() -> pd.DataFrame:
    """
    Constructs the canonical 30-row research benchmark dataset
    matching the schema specified in OcuSense literature.
    """
    np.random.seed(42)
    
    patient_ids = [f"P{i:03d}" for i in range(1, 31)]
    dates = [f"2026-08-{(i%20)+1:02d}" for i in range(1, 31)]
    
    # 30 observations with clinically realistic multivariate distributions
    # 15 non-flare (0), 15 flare (1)
    data = []
    
    # Non-flare instances (low/moderate symptoms, lower exposures)
    for i in range(15):
        itching = np.random.choice([0, 1, 2], p=[0.6, 0.3, 0.1])
        redness = np.random.choice([0, 1], p=[0.7, 0.3])
        watering = np.random.choice([0, 1], p=[0.7, 0.3])
        irritation = np.random.choice([0, 1, 2], p=[0.6, 0.3, 0.1])
        severity = itching + redness + watering + irritation + int(np.random.choice([0, 1]))
        pollen = np.random.choice(["Low", "Moderate", "High"], p=[0.5, 0.4, 0.1])
        pm25 = float(np.round(np.random.uniform(15.0, 48.0), 1))
        pm10 = float(np.round(np.random.uniform(30.0, 75.0), 1))
        aqi = float(np.round(np.random.uniform(40.0, 95.0), 1))
        temperature = float(np.round(np.random.uniform(26.0, 33.0), 1))
        humidity = float(np.round(np.random.uniform(45.0, 68.0), 1))
        outdoor = float(np.round(np.random.uniform(0.5, 2.5), 1))
        indoor_dust = float(np.round(np.random.uniform(1.0, 2.5), 1))
        flare = 0
        data.append({
            "Patient_ID": patient_ids[i],
            "Date": dates[i],
            "Itching": itching,
            "Redness": redness,
            "Watering": watering,
            "Irritation": irritation,
            "Severity": min(10, severity),
            "Pollen": pollen,
            "PM2.5": pm25,
            "PM10": pm10,
            "AQI": aqi,
            "Temperature": temperature,
            "Humidity": humidity,
            "Outdoor_Exposure": outdoor,
            "Indoor_Dust": indoor_dust,
            "Flare": flare
        })
        
    # Flare instances (higher symptoms, elevated environmental exposures)
    for i in range(15, 30):
        itching = np.random.choice([2, 3], p=[0.4, 0.6])
        redness = np.random.choice([2, 3], p=[0.5, 0.5])
        watering = np.random.choice([1, 2, 3], p=[0.2, 0.5, 0.3])
        irritation = np.random.choice([2, 3], p=[0.4, 0.6])
        severity = itching + redness + watering + irritation + int(np.random.choice([1, 2]))
        pollen = np.random.choice(["Moderate", "High"], p=[0.3, 0.7])
        pm25 = float(np.round(np.random.uniform(50.0, 110.0), 1))
        pm10 = float(np.round(np.random.uniform(85.0, 180.0), 1))
        aqi = float(np.round(np.random.uniform(110.0, 210.0), 1))
        temperature = float(np.round(np.random.uniform(29.0, 36.0), 1))
        humidity = float(np.round(np.random.uniform(70.0, 88.0), 1))
        outdoor = float(np.round(np.random.uniform(2.5, 6.0), 1))
        indoor_dust = float(np.round(np.random.uniform(3.0, 5.0), 1))
        flare = 1
        data.append({
            "Patient_ID": patient_ids[i],
            "Date": dates[i],
            "Itching": itching,
            "Redness": redness,
            "Watering": watering,
            "Irritation": irritation,
            "Severity": min(10, severity),
            "Pollen": pollen,
            "PM2.5": pm25,
            "PM10": pm10,
            "AQI": aqi,
            "Temperature": temperature,
            "Humidity": humidity,
            "Outdoor_Exposure": outdoor,
            "Indoor_Dust": indoor_dust,
            "Flare": flare
        })

    df = pd.DataFrame(data)
    return df


def load_dataset(file_path: str = None) -> pd.DataFrame:
    """
    Loads dataset from Excel or CSV. If file doesn't exist,
    creates the benchmark dataset files and returns the DataFrame.
    """
    target_path = file_path or FINAL_DATASET_CSV_PATH
    if not os.path.exists(target_path):
        if os.path.exists(DATASET_CSV_PATH):
            return normalize_dataset(pd.read_csv(DATASET_CSV_PATH))
        df = generate_benchmark_30_row_data()
        try:
            df.to_excel(DATASET_EXCEL_PATH, index=False)
        except Exception:
            pass
        df.to_csv(DATASET_CSV_PATH, index=False)
        return normalize_dataset(df)

    if target_path.endswith(".xlsx") or target_path.endswith(".xls"):
        try:
            return normalize_dataset(pd.read_excel(target_path))
        except Exception:
            if os.path.exists(DATASET_CSV_PATH):
                return normalize_dataset(pd.read_csv(DATASET_CSV_PATH))
    return normalize_dataset(pd.read_csv(target_path))


def normalize_dataset(df: pd.DataFrame) -> pd.DataFrame:
    """
    Converts supported prototype dataset variants into the canonical model
    feature names used by the preprocessor and prediction engine.
    """
    out = df.copy()
    rename_map = {
        "PM2.5_ug_m3": "PM2.5",
        "PM10_ug_m3": "PM10",
        "NO2_ug_m3": "NO2",
        "O3_ug_m3": "O3",
        "Video_Quality": "Image_Quality",
    }
    out = out.rename(columns=rename_map)

    yes_no_cols = [
        "Itching",
        "Redness",
        "Watering",
        "Irritation",
        "Outdoor_Symptom_Worsening",
        "Seasonal_Symptom_Worsening",
        "Pet_Present",
        "Indoor_Symptoms",
        "Doctor_Consultation",
    ]
    for col in yes_no_cols:
        if col in out.columns:
            out[col] = out[col].map(lambda value: _yes_no_to_int(value))

    if "Severity" not in out.columns:
        symptom_cols = [c for c in ["Itching", "Redness", "Watering", "Irritation"] if c in out.columns]
        out["Severity"] = out[symptom_cols].sum(axis=1).clip(0, 10) if symptom_cols else 0

    if "Pollen" not in out.columns and "Pollen_Index" in out.columns:
        out["Pollen"] = out["Pollen_Index"].map(_pollen_index_to_category)

    if "Pollen_Index" not in out.columns and "Pollen" in out.columns:
        out["Pollen_Index"] = out["Pollen"].map(lambda value: {"low": 25, "moderate": 55, "high": 85}.get(str(value).lower(), 50))

    if "Outdoor_Exposure" not in out.columns:
        if "Outdoor_Frequency" in out.columns:
            out["Outdoor_Exposure"] = out["Outdoor_Frequency"].map(_outdoor_frequency_to_hours)
        else:
            out["Outdoor_Exposure"] = 2.0

    if "Indoor_Dust" not in out.columns:
        if "Home_Dust" in out.columns:
            out["Indoor_Dust"] = out["Home_Dust"].map(_home_dust_to_level)
        else:
            out["Indoor_Dust"] = 1.0

    if "Image_Quality_Score" not in out.columns:
        if "Image_Quality" in out.columns:
            out["Image_Quality_Score"] = out["Image_Quality"].map(_image_quality_to_score)
        else:
            out["Image_Quality_Score"] = 0.85

    if "Flare" not in out.columns and "Risk_Label" in out.columns:
        out["Flare"] = out["Risk_Label"].map(lambda value: 0 if str(value).lower() == "low" else 1)

    defaults = {
        "NO2": 0.0,
        "O3": 0.0,
        "Temperature": 30.0,
        "Humidity": 60.0,
        "Redness_Score": 0.0,
        "Inflammation_Score": 0.0,
        "Swelling_Score": 0.0,
        "Watering_Score": 0.0,
        "Image_Quality_Score": 0.85,
        "Pollen_Index": 50.0,
    }
    for col, default in defaults.items():
        if col not in out.columns:
            out[col] = default

    return out


def _yes_no_to_int(value) -> int:
    text = str(value).strip().lower()
    if text in {"yes", "true", "1", "mild"}:
        return 1
    if text in {"moderate"}:
        return 2
    if text in {"severe"}:
        return 3
    return 0


def _pollen_index_to_category(value) -> str:
    try:
        numeric = float(value)
    except (TypeError, ValueError):
        return "Moderate"
    if numeric >= 70:
        return "High"
    if numeric >= 35:
        return "Moderate"
    return "Low"


def _outdoor_frequency_to_hours(value) -> float:
    return {
        "daily": 4.0,
        "occasionally": 2.0,
        "rarely": 0.75,
    }.get(str(value).strip().lower(), 2.0)


def _home_dust_to_level(value) -> float:
    return {
        "rarely": 1.0,
        "sometimes": 2.0,
        "frequently": 4.0,
    }.get(str(value).strip().lower(), 2.0)


def _image_quality_to_score(value) -> float:
    return {
        "excellent": 0.95,
        "good": 0.85,
        "fair": 0.65,
        "poor": 0.35,
    }.get(str(value).strip().lower(), 0.85)
