from app.core.stability_engine import analyze_stability
from app.models.schemas import LabData, LifestyleProfile, ActivityLevel

def test_week2_fix():
    print("🧪 Testing Week 2 Fix (Stability Engine v2)...")
    
    lifestyle = LifestyleProfile(
        activity_level=ActivityLevel.moderate,
        diet_type="Balanced",
        is_smoker=False,
        is_athlete=False
    )
    
    # Case 1: Consistent Data
    # Rolling Avg 150 -> HbA1c ~ (150+46.7)/28.7 = 6.85%
    lab1 = LabData(hba1c=6.9, fasting_glucose=140, ferritin=50, blood_event=False)
    res1 = analyze_stability(lab1, lifestyle, rolling_avg_90d=150.0)
    print(f"\n✅ Case 1 (Consistent): {res1}")
    assert res1["hba1c_estimated_from_cgm"] == 6.85
    assert res1["gap"] == 0.05
    assert "Cohérence excellente" in res1["gap_analysis"]

    # Case 2: High Lab Gap (Glycation Rapide?)
    # Rolling Avg 100 -> HbA1c ~ 5.1%
    lab2 = LabData(hba1c=8.0, fasting_glucose=100, ferritin=50, blood_event=False)
    res2 = analyze_stability(lab2, lifestyle, rolling_avg_90d=100.0)
    print(f"\n⚠️ Case 2 (High Gap): {res2}")
    assert res2["hba1c_estimated_from_cgm"] == 5.11
    # Adjusted Lab = 8.0 (no bias)
    # Gap = 8.0 - 5.11 = 2.89
    assert res2["gap"] > 2.0
    assert "HbA1c Labo plus élevée" in res2["gap_analysis"]

    print("\n🎉 Week 2 Stability Engine Logic Verified!")

if __name__ == "__main__":
    test_week2_fix()
