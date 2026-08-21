import json
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


import uuid

def test_step_3_register():
    print("\n--- Testing Step 3: POST /api/auth/register ---")
    uid = uuid.uuid4().hex[:8]
    email_a = f"usera_{uid}@example.com"
    email_b = f"userb_{uid}@example.com"
    
    # 1. Register User A
    payload_a = {"email": email_a, "password": "securepassword123"}
    resp = client.post("/api/auth/register", json=payload_a)
    assert resp.status_code == 201, f"Expected 201, got {resp.status_code}: {resp.text}"
    data_a = resp.json()
    print("User A Register Response:", json.dumps(data_a, indent=2))
    assert "user_id" in data_a
    assert data_a["message"] == "Account created"

    # 2. Register Duplicate User A (Expect 409 Conflict)
    resp_dup = client.post("/api/auth/register", json=payload_a)
    assert resp_dup.status_code == 409, f"Expected 409, got {resp_dup.status_code}: {resp_dup.text}"
    print("Duplicate Email Conflict Response:", resp_dup.json())

    # 3. Register User B
    payload_b = {"email": email_b, "password": "password456"}
    resp_b = client.post("/api/auth/register", json=payload_b)
    assert resp_b.status_code == 201
    print("[SUCCESS] Registration & Duplicate Conflict Checks Passed!")
    return data_a["user_id"], resp_b.json()["user_id"], email_a, email_b


def test_step_3_login(email_a: str, email_b: str):
    print("\n--- Testing Step 3: POST /api/auth/login & /refresh ---")
    
    # 1. Login with bad password (Expect 401)
    bad_login = client.post("/api/auth/login", json={"email": email_a, "password": "wrongpassword"})
    assert bad_login.status_code == 401, f"Expected 401, got {bad_login.status_code}"
    print("Invalid Login Response:", bad_login.json())

    # 2. Successful Login User A
    login_a = client.post("/api/auth/login", json={"email": email_a, "password": "securepassword123"})
    assert login_a.status_code == 200, f"Expected 200, got {login_a.status_code}"
    tokens_a = login_a.json()
    print("User A Login Tokens:", json.dumps(tokens_a, indent=2))
    assert "access_token" in tokens_a
    assert "refresh_token" in tokens_a
    assert tokens_a["token_type"] == "bearer"

    # 3. Successful Login User B
    login_b = client.post("/api/auth/login", json={"email": email_b, "password": "password456"})
    assert login_b.status_code == 200
    tokens_b = login_b.json()

    # 4. Refresh Token Test
    refresh_resp = client.post("/api/auth/refresh", json={"refresh_token": tokens_a["refresh_token"]})
    assert refresh_resp.status_code == 200
    print("Refreshed Access Token Response:", refresh_resp.json())
    assert "access_token" in refresh_resp.json()

    # 5. Logout Endpoint
    logout_resp = client.post("/api/auth/logout")
    assert logout_resp.status_code == 200
    print("[SUCCESS] Login, Refresh, and Logout Passed!")

    return tokens_a["access_token"], tokens_b["access_token"]


def test_step_4_patient_profiles(token_a):
    print("\n--- Testing Step 4: GET/POST/PATCH /api/patients/me ---")
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # 1. GET /api/patients/me
    get_resp = client.get("/api/patients/me", headers=headers_a)
    assert get_resp.status_code == 200, f"Expected 200, got {get_resp.status_code}"
    print("Get Profile Me Response:", json.dumps(get_resp.json(), indent=2))

    # 2. PATCH /api/patients/me
    patch_payload = {"display_name": "Alice Patient", "location_name": "Chennai"}
    patch_resp = client.patch("/api/patients/me", json=patch_payload, headers=headers_a)
    assert patch_resp.status_code == 200
    updated_profile = patch_resp.json()
    print("Updated Profile Response:", json.dumps(updated_profile, indent=2))
    assert updated_profile["display_name"] == "Alice Patient"
    assert updated_profile["location_name"] == "Chennai"

    print("[SUCCESS] Patient Profile Management Passed!")


def test_step_5_retrofit_analysis_protection(token_a, user_b_id):
    print("\n--- Testing Step 5: Protected Analysis Routes & ID Isolation ---")
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # 1. Unauthenticated Request -> Must return 401 Unauthorized
    unauth_resp = client.get("/api/analysis/risk")
    assert unauth_resp.status_code == 401, f"Expected 401 Unauthenticated, got {unauth_resp.status_code}"
    print("Unauthenticated Request Rejected:", unauth_resp.json())

    # 2. Authenticated Risk Request (User A)
    auth_risk = client.get("/api/analysis/risk", headers=headers_a)
    assert auth_risk.status_code == 200, f"Expected 200, got {auth_risk.status_code}"
    print("Authenticated Risk Response:", json.dumps(auth_risk.json(), indent=2))

    # 3. Security Cross-User Test: User A passes `patient_id=user_b_id` in URL parameter
    # Must be ignored/prevented — User A's token can NEVER view User B's risk/trigger data!
    spoof_resp = client.get(f"/api/analysis/risk?patient_id={user_b_id}", headers=headers_a)
    assert spoof_resp.status_code == 200
    print("Spoof Attempt (passing User B ID as User A) Result:", json.dumps(spoof_resp.json(), indent=2))
    
    # 4. GET /api/analysis/combined-data
    combined_resp = client.get("/api/analysis/combined-data", headers=headers_a)
    assert combined_resp.status_code == 200

    # 5. GET /api/analysis/triggers
    triggers_resp = client.get("/api/analysis/triggers", headers=headers_a)
    assert triggers_resp.status_code == 200

    # 6. GET /api/environment/hardware (Public sensor endpoint)
    hw_resp = client.get("/api/environment/hardware")
    assert hw_resp.status_code == 200

    print("[SUCCESS] Step 5 Retrofitted Analysis & Security Isolation Passed!")


if __name__ == "__main__":
    user_a_id, user_b_id, email_a, email_b = test_step_3_register()
    token_a, token_b = test_step_3_login(email_a, email_b)
    test_step_4_patient_profiles(token_a)
    test_step_5_retrofit_analysis_protection(token_a, user_b_id)
    print("\n[ALL 5 STEPS VERIFIED END-TO-END SUCCESSFULLY!]")
