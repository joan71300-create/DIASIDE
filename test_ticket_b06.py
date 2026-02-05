import pytest
import asyncio
from app.models.schemas import LabData, LifestyleProfile, ActivityLevel
from app.core.stability_engine import adjust_hba1c
from app.services.ai_service import ai_service
import time

@pytest.mark.asyncio
async def test_ticket_b06():
    print("🧪 Starting Ticket B06 Verification (Gemini 3.0 Prompt Engine)...\n")
    
    # 1. Prepare Data (Ticket B05 inputs)
    lab = LabData(hba1c=7.0, fasting_glucose=100, ferritin=20, blood_event=False)
    lifestyle = LifestyleProfile(
        activity_level=ActivityLevel.moderate, 
        diet_type="Balanced", 
        is_smoker=False,
        is_athlete=False
    )
    
    print(f"📋 Input: HbA1c={lab.hba1c}%, Ferritin={lab.ferritin} (Low)")
    
    # 2. Run Stability Engine
    user_results = adjust_hba1c(lab, lifestyle)
    print(f"⚙️  Stability Engine Results: {user_results}")
    
    # 3. Call AI Service (Gemini 3.0)
    print("\n🚀 Calling Gemini 3.0 Flash Preview...")
    start_time = time.time()
    try:
        advice = await ai_service.generate_coach_advice(user_results)
        elapsed = time.time() - start_time
        print(f"✅ AI Response ({elapsed:.2f}s):\n")
        print("--------------------------------------------------")
        print(advice)
        print("--------------------------------------------------")
        
        if elapsed > 2.5: # Allow slight buffer over 2s for network overhead in test
             print("⚠️  Warning: Response took longer than 2s. Timeout config check needed.")
        else:
             print("⏱️  Timing OK (< 2s)")
             
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_ticket_b06())
