import json
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


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
    response = client.get("/api/analysis/combined-data?patient_id=p123")
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    data = response.json()
    print("Response:", json.dumps(data, indent=2))
    assert "patient" in data
    assert "environment_api" in data
    assert "environment_hardware" in data
    assert "timestamp" in data
    assert data["environment_hardware"]["dust"] == 421
    print("[SUCCESS] Phase 6 Combined Data Endpoint Passed!")


def test_phase_7_risk_analysis():
    print("\n--- Testing Phase 7: GET /api/analysis/risk ---")
    response = client.get("/api/analysis/risk?patient_id=p123")
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    data = response.json()
    print("Response:", json.dumps(data, indent=2))
    assert "risk_score" in data
    assert "risk_level" in data
    assert "contributing_factors" in data
    assert isinstance(data["risk_score"], int)
    print(f"Risk Score: {data['risk_score']}, Risk Level: {data['risk_level']}")
    print("[SUCCESS] Phase 7 Risk Analysis Engine Endpoint Passed!")


def test_phase_8_personalized_triggers():
    print("\n--- Testing Phase 8: GET /api/analysis/triggers ---")
    response = client.get("/api/analysis/triggers?patient_id=p123")
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
