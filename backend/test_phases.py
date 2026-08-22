import json
import uuid
from unittest.mock import patch
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def auth_headers():
    email = f"phase-test-{uuid.uuid4()}@ocusense.local"
    password = "phase_test_password_2026"
    client.post("/api/auth/register", json={"email": email, "password": password})
    login_resp = client.post("/api/auth/login", json={"email": email, "password": password})
    assert login_resp.status_code == 200, login_resp.text
    return {"Authorization": f"Bearer {login_resp.json()['access_token']}"}


MOCK_ENVIRONMENT = {
    "pm25": 21.74,
    "pm10": 30.08,
    "no2": 15.92,
    "o3": 104.38,
    "aqi": "moderate",
    "aqi_numeric": 83,
    "dust": "low",
    "dust_numeric": 30.08,
    "temperature": 33.6,
    "humidity": 48,
    "uv": None,
    "pollen": None,
    "pollen_index": None,
    "weather": "Sunny",
    "lat": 13.0827,
    "lon": 80.2707,
    "forecast_window": "current",
    "timestamp": "2026-08-22T00:00:00+00:00",
    "sources": {
        "weather": "open-meteo-weather",
        "air_quality": "open-meteo-air-quality",
        "pollen": "google-pollen",
    },
    "availability": {
        "weather": True,
        "air_quality": True,
        "pollen": False,
    },
    "errors": {
        "weather": None,
        "air_quality": None,
        "pollen": "HTTP 403",
    },
    "missing_fields": ["uv", "pollen", "pollen_index"],
}


def test_phase_6_hardware():
    print("\n--- Testing Phase 6: GET /api/environment/hardware ---")
    response = client.get("/api/environment/hardware")
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    data = response.json()
    print("Response:", json.dumps(data, indent=2))
    assert data["dust"] == 421
    assert data["humidity"] == 76
    assert data["temperature"] == 31
    print("[SUCCESS] Phase 6 Hardware Endpoint Passed!")


def test_phase_6_combined_data():
    print("\n--- Testing Phase 6: GET /api/analysis/combined-data ---")
    with patch(
        "app.services.environmental_service.EnvironmentalDataService.get_environmental_data",
        return_value=MOCK_ENVIRONMENT,
    ):
        response = client.get("/api/analysis/combined-data", headers=auth_headers())
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    data = response.json()
    print("Response:", json.dumps(data, indent=2))
    assert "patient" in data
    assert "environment_api" in data
    assert "environment_hardware" in data
    assert "timestamp" in data
    assert data["environment_hardware"]["dust"] == 421
    assert data["environment_api"]["pollen"] is None
    assert data["environment_api"]["pollen_index"] is None
    assert data["environment_api"]["availability"]["pollen"] is False
    assert data["environment_api"]["errors"]["pollen"] == "HTTP 403"
    print("[SUCCESS] Phase 6 Combined Data Endpoint Passed!")


def test_phase_7_risk_analysis():
    print("\n--- Testing Phase 7: GET /api/analysis/risk ---")
    with patch(
        "app.services.environmental_service.EnvironmentalDataService.get_environmental_data",
        return_value=MOCK_ENVIRONMENT,
    ):
        response = client.get("/api/analysis/risk", headers=auth_headers())
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    data = response.json()
    print("Response:", json.dumps(data, indent=2))
    assert "risk_score" in data
    assert "risk_level" in data
    assert "contributing_factors" in data
    assert data["prediction_engine"] in ["ml", "unavailable"]
    assert "environment" in data
    assert data["data_availability"]["pollen"] is False
    assert data["data_errors"]["pollen"] == "HTTP 403"
    if data["prediction_engine"] == "ml":
        assert isinstance(data["risk_score"], int)
        assert data["confidence"] is None
    print(f"Risk Score: {data['risk_score']}, Risk Level: {data['risk_level']}")
    print("[SUCCESS] Phase 7 Risk Analysis Engine Endpoint Passed!")


def test_phase_8_personalized_triggers():
    print("\n--- Testing Phase 8: GET /api/analysis/triggers ---")
    response = client.get("/api/analysis/triggers", headers=auth_headers())
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    data = response.json()
    print("Response:", json.dumps(data, indent=2))
    assert "triggers" in data
    assert len(data["triggers"]) > 0
    dust_trigger = next((t for t in data["triggers"] if t["factor"] == "dust"), None)
    assert dust_trigger is not None
    assert "association_score" in dust_trigger
    assert "lift" in dust_trigger
    assert "confidence" in dust_trigger
    assert "observation_count" in dust_trigger
    print("[SUCCESS] Phase 8 Personalized Triggers Endpoint Passed!")


if __name__ == "__main__":
    test_phase_6_hardware()
    test_phase_6_combined_data()
    test_phase_7_risk_analysis()
    test_phase_8_personalized_triggers()
    print("\n[ALL PHASES VERIFIED SUCCESSFULLY END-TO-END]")
