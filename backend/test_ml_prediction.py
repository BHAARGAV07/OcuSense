"""
Comprehensive Integration Test Suite for OcuSense ML & Prediction Pipeline.
"""
import io
import json
from fastapi.testclient import TestClient
from PIL import Image
import numpy as np

from app.main import app

client = TestClient(app)


def create_test_eye_image_bytes(is_sharp: bool = True) -> bytes:
    # Create a 300x300 image with eye-like sclera, iris, and vessel texture
    img_arr = np.ones((300, 300, 3), dtype=np.uint8) * 200
    
    if is_sharp:
        # Sclera white background with high-frequency vessel lines (sharp gradient)
        for i in range(0, 300, 10):
            img_arr[i, :, :] = np.array([220, 100, 100], dtype=np.uint8)
            img_arr[:, i, :] = np.array([240, 110, 110], dtype=np.uint8)
        # Iris center
        center_y, center_x = 150, 150
        y, x = np.ogrid[:300, :300]
        mask = (x - center_x)**2 + (y - center_y)**2 <= 50**2
        img_arr[mask] = [50, 40, 30]
    
    img = Image.fromarray(img_arr)
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


def test_full_ml_and_personalization_flow():
    print("\n=======================================================")
    print("TESTING OCUSENSE ML & PERSONALIZATION PIPELINE")
    print("=======================================================")

    # 1. Register & Login Test User
    email = "research_patient_01@ocusense.org"
    password = "secure_password_ml_2026"
    reg_resp = client.post("/api/auth/register", json={"email": email, "password": password})
    if reg_resp.status_code == 409:
        print("User already registered, logging in...")
    
    login_resp = client.post("/api/auth/login", json={"email": email, "password": password})
    assert login_resp.status_code == 200, f"Login failed: {login_resp.text}"
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("[1] Authentication Passed.")

    # 2. Test Personalization Profile Onboarding
    print("\n--- Testing Personalization Onboarding ---")
    personalization_payload = {
        "display_name": "Dr. Research Subject",
        "location_name": "Chennai, Tamil Nadu",
        "location_lat": 13.0827,
        "location_lon": 80.2707,
        "age": 28,
        "sex": "Female",
        "previous_allergy_history": True,
        "typical_flare_frequency": "Monthly",
        "typical_seasonal_pattern": "Monsoon",
        "dust_sensitivity": True,
        "pollen_sensitivity": True,
        "pet_exposure": False,
        "smoke_exposure": True,
        "outdoor_activity_hours": 3.5,
        "eye_rubbing_tendency": True,
        "contact_lens_use": False,
        "current_medication": "Olopatadine 0.1%"
    }
    pers_resp = client.post("/api/personalization", json=personalization_payload, headers=headers)
    assert pers_resp.status_code == 200, f"Personalization failed: {pers_resp.text}"
    pers_data = pers_resp.json()
    assert pers_data["is_onboarded"] is True
    assert pers_data["age"] == 28
    print("[2] Personalization Profile saved and marked onboarded.")

    # 3. Test Ocular Image Analysis & Quality Validation
    print("\n--- Testing Ocular Analysis & Quality Check ---")
    img_bytes = create_test_eye_image_bytes()
    files = {"image": ("test_eye.jpg", img_bytes, "image/jpeg")}
    cv_resp = client.post("/api/ocular/analyze-image", files=files, headers=headers)
    assert cv_resp.status_code == 200, f"CV analysis failed: {cv_resp.text}"
    cv_data = cv_resp.json()
    print("Ocular Analysis Output:", json.dumps(cv_data, indent=2))
    assert cv_data["success"] is True
    assert cv_data["is_acceptable"] is True
    assert cv_data["redness_score"] is not None
    assert cv_data["swelling_score"] is None  # Honest null check
    assert cv_data["tear_feature"] is None     # Honest null check
    print("[3] Ocular CV Analysis and Quality Assurance Passed.")

    # 4. Test Canonical Feature Prediction API
    print("\n--- Testing Canonical Feature Prediction API ---")
    pred_payload = {
        "features": {
            "ocular": {
                "redness_score": cv_data["redness_score"],
                "inflammation_score": cv_data.get("inflammation_score", 0.5),
                "image_quality": cv_data["image_quality"],
                "confidence": 0.88
            },
            "symptoms": {
                "itching": 2,
                "watering": 2,
                "redness": 2,
                "irritation": 1,
                "severity": 7,
                "eye_rubbing": 2,
                "medication_used_today": True,
                "symptoms_duration": "1–3 days"
            },
            "environment": {
                "pm25": 58.4,
                "pm10": 92.1,
                "aqi": 135.0,
                "temperature": 32.0,
                "humidity": 78.0,
                "uv": 6.0,
                "pollen": "High",
                "weather": "Humid / Hazy"
            },
            "exposure": {
                "outdoor_exposure": 4.0,
                "indoor_dust": 3.0
            },
            "personalization": {
                "age": 28,
                "previous_allergy_history": True,
                "typical_flare_frequency": "Monthly",
                "typical_seasonal_pattern": "Monsoon",
                "dust_sensitivity": True,
                "pollen_sensitivity": True,
                "pet_exposure": False,
                "smoke_exposure": True,
                "eye_rubbing_tendency": True,
                "contact_lens_use": False
            },
            "history": {
                "previous_flares_count": 3
            }
        }
    }

    pred_resp = client.post("/api/prediction", json=pred_payload, headers=headers)
    assert pred_resp.status_code == 200, f"Prediction failed: {pred_resp.text}"
    pred_data = pred_resp.json()
    print("Prediction Output:", json.dumps(pred_data, indent=2))
    assert "risk_probability" in pred_data
    assert "risk_level" in pred_data
    assert pred_data["risk_level"] in ["LOW", "MODERATE", "HIGH"]
    assert "top_contributing_features" in pred_data
    assert len(pred_data["top_contributing_features"]) > 0
    assert "literature_references" in pred_data
    assert "preventive_guidance" in pred_data
    assert "Prototype AI risk estimate" in pred_data["disclaimer"]
    prediction_id = pred_data["prediction_id"]
    print(f"[4] ML Prediction Generated successfully! Probability: {pred_data['risk_probability']}, Level: {pred_data['risk_level']}")

    # 5. Test Research Mode Engine Comparison
    print("\n--- Testing Research Engine Comparison (ML vs Rule-Based) ---")
    comp_resp = client.get("/api/prediction/compare", headers=headers)
    assert comp_resp.status_code == 200, f"Comparison failed: {comp_resp.text}"
    comp_data = comp_resp.json()
    print("Engine Comparison Output:", json.dumps(comp_data, indent=2))
    assert "ml_result" in comp_data
    assert "rule_result" in comp_data
    assert comp_data["ml_result"]["engine"] == "ml"
    assert comp_data["rule_result"]["engine"] == "rule_based"
    print("[5] Research Engine Comparison Passed.")

    # 6. Test Outcome Feedback Logging
    print("\n--- Testing Outcome Feedback Loop ---")
    outcome_payload = {
        "prediction_id": prediction_id,
        "flare_occurred": True,
        "symptom_severity": "MODERATE",
        "rescue_medication_used": True,
        "doctor_visit": False,
        "notes": "Experienced increased itching and redness after evening outdoor exposure."
    }
    outcome_resp = client.post("/api/prediction/outcome", json=outcome_payload, headers=headers)
    assert outcome_resp.status_code == 201, f"Outcome feedback failed: {outcome_resp.text}"
    outcome_data = outcome_resp.json()
    assert outcome_data["flare_occurred"] is True
    assert outcome_data["prediction_id"] == prediction_id
    print("[6] Outcome Feedback Successfully Recorded.")

    # 7. Test Prediction History Retrieval
    print("\n--- Testing Prediction History Retrieval ---")
    hist_resp = client.get("/api/prediction/history", headers=headers)
    assert hist_resp.status_code == 200
    hist_data = hist_resp.json()
    assert "history" in hist_data
    assert len(hist_data["history"]) >= 1
    print(f"[7] History Retrieved ({len(hist_data['history'])} records).")

    print("\n=======================================================")
    print("ALL BACKEND ML & PERSONALIZATION TESTS PASSED PERFECTLY!")
    print("=======================================================\n")


if __name__ == "__main__":
    test_full_ml_and_personalization_flow()
