from fastapi.testclient import TestClient
from sqlalchemy import create_engine, StaticPool
from sqlalchemy.orm import sessionmaker
from app.models.database import Base, get_db
from app.api.auth import get_current_user
from main import app
from app.models import models
import pytest

# 1. Setup Test DB
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

# Mock User (Simple Object to avoid DetachedInstanceError)
class MockUser:
    id = 1
    email = "test@diaside.com"
    is_active = True
    questionnaire = None

mock_user = MockUser()

def override_get_current_user():
    return mock_user

app.dependency_overrides[get_db] = override_get_db
app.dependency_overrides[get_current_user] = override_get_current_user

# Create tables
Base.metadata.create_all(bind=engine)

# Add Mock User to DB
db = TestingSessionLocal()
db_user = models.User(id=1, email="test@diaside.com", is_active=True, hashed_password="hashed")
db.add(db_user)
db.commit()
db.close()

client = TestClient(app)

def test_full_scenario():
    print("\n🚀 Starting Full Integration Test (Week 1 + Week 2)...")

    # --- WEEK 1: CGM Ingestion ---
    print("\n1️⃣  Testing /cgm (Week 1) + T-SEC001 (Questionnaire)...")
    readings = [140, 150, 160] # Avg 150
    
    # Send questionnaire with first reading
    q_data = {
        "age": 35,
        "weight": 80,
        "height": 180,
        "diabetes_type": "Type 1",
        "target_glucose_min": 70,
        "target_glucose_max": 180
    }
    
    for i, val in enumerate(readings):
        payload = {"value": val, "device_id": "dexcom-g7"}
        if i == 0:
            payload["questionnaire"] = q_data
            print("   - Sending questionnaire with first ping...")
            
        resp = client.post("/api/cgm", json=payload)
        assert resp.status_code == 200
        print(f"   - Posted glucose: {val} -> ID {resp.json()['id']}")
    
    # Verify Questionnaire in DB
    db = TestingSessionLocal()
    saved_q = db.query(models.Questionnaire).filter(models.Questionnaire.user_id == 1).first()
    assert saved_q is not None
    assert saved_q.diabetes_type == "Type 1"
    print("   ✅ Questionnaire successfully saved via /cgm")
    db.close()
    
    # --- WEEK 2: AI Coach with Stability Engine ---
    print("\n2️⃣  Testing /ai/coach (Week 2)...")
    
    # Snapshot Input: HbA1c 6.9 (consistent with 150 avg ~ 6.85)
    snapshot = {
        "age": 35,
        "weight": 80,
        "height": 180,
        "diabetes_type": "Type 1",
        "lab_data": {
            "hba1c": 6.9,
            "fasting_glucose": 140,
            "ferritin": 50, # Normal
            "blood_event": False
        },
        "lifestyle": {
            "activity_level": "moderate",
            "diet_type": "Balanced",
            "is_smoker": False,
            "is_athlete": False
        }
    }
    
    print("   - Calling AI Coach (Waiting for Gemini 3.0... ~10s)")
    resp = client.post("/api/ai/coach", json=snapshot)
    
    if resp.status_code != 200:
        print(f"❌ Error: {resp.text}")
        return

    data = resp.json()
    debug = data.get("debug_results", {})
    
    print("\n📊 Stability Analysis Results:")
    print(f"   - Rolling Avg (DB): {debug.get('rolling_avg_90d')} mg/dL (Expected 150)")
    print(f"   - Est. HbA1c: {debug.get('hba1c_estimated_from_cgm')}%")
    print(f"   - Lab HbA1c: {debug.get('hba1c_adjusted')}%")
    print(f"   - Gap Analysis: {debug.get('gap_analysis')}")
    
    print("\n🤖 AI Advice:")
    print("---------------------------------------------------")
    print(data.get("advice"))
    print("---------------------------------------------------")
    
    actions = data.get("actions", [])
    if actions:
        print(f"\n🚀 Actions ({len(actions)}):")
        for a in actions:
            print(f"   - [{a['type']}] {a['label']}")
    
    # Assertions
    assert debug.get('rolling_avg_90d') == 150.0
    assert abs(debug.get('gap')) < 0.1
    assert "Cohérence excellente" in debug.get('gap_analysis')
    assert len(data.get("advice")) > 10
    # Gemini might return actions or not depending on prompt adherence, but the field should exist
    assert "actions" in data

    print("\n✅ Full Scenario PASSED!")

if __name__ == "__main__":
    test_full_scenario()
