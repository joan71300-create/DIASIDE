from app.models.schemas import LabData, LifestyleProfile, ActivityLevel
from app.core.stability_engine import adjust_hba1c

def test_ticket_b05():
    print("🧪 Starting Ticket B05 Verification...\n")
    
    # Base Lifestyle for reuse
    base_lifestyle = LifestyleProfile(
        activity_level=ActivityLevel.moderate,
        diet_type="Balanced",
        is_smoker=False,
        is_athlete=False
    )
    
    # 1. Test Normal (No interference)
    lab_normal = LabData(hba1c=7.0, fasting_glucose=100, ferritin=50, blood_event=False)
    result = adjust_hba1c(lab_normal, base_lifestyle)
    print(f"CASE 1 (Normal): {result}")
    assert result["correction_factor"] == 0.0
    assert result["hba1c_adjusted"] == 7.0
    
    # 2. Test Low Ferritin (< 30) -> Should subtract
    lab_ferritin = LabData(hba1c=7.0, fasting_glucose=100, ferritin=20, blood_event=False)
    result = adjust_hba1c(lab_ferritin, base_lifestyle)
    print(f"CASE 2 (Ferritin < 30): {result}")
    assert result["correction_factor"] == -0.5
    assert result["hba1c_adjusted"] == 6.5
    assert "Ferritine basse" in result["analysis_summary"]
    
    # 3. Test Athlete -> Should add
    lifestyle_athlete = LifestyleProfile(
        activity_level=ActivityLevel.active,
        diet_type="Balanced",
        is_smoker=False,
        is_athlete=True
    )
    result = adjust_hba1c(lab_normal, lifestyle_athlete)
    print(f"CASE 3 (Athlete): {result}")
    assert result["correction_factor"] == 0.5
    assert result["hba1c_adjusted"] == 7.5
    assert "Athlète" in result["analysis_summary"]
    
    # 4. Test Blood Event -> Should add
    lab_blood = LabData(hba1c=7.0, fasting_glucose=100, ferritin=50, blood_event=True)
    result = adjust_hba1c(lab_blood, base_lifestyle)
    print(f"CASE 4 (Blood Event): {result}")
    assert result["correction_factor"] == 0.5
    assert result["hba1c_adjusted"] == 7.5
    assert "Perte de sang" in result["analysis_summary"]
    
    # 5. Test Both (Ferritin < 30 AND Athlete) -> Should cancel out
    result = adjust_hba1c(lab_ferritin, lifestyle_athlete)
    print(f"CASE 5 (Ferritin < 30 + Athlete): {result}")
    assert result["correction_factor"] == 0.0 # -0.5 + 0.5
    assert result["hba1c_adjusted"] == 7.0
    
    print("\n✅ All Ticket B05 tests passed!")

if __name__ == "__main__":
    test_ticket_b05()
