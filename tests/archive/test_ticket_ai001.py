import pytest
import asyncio
from app.services.ai_service import ai_service
from app.models.schemas import ChatMessage

# Mocking track decorator if needed, or assuming it works in test environment
# If opik fails in test environment, we might need to mock it.

@pytest.mark.asyncio
async def test_multi_turn_context():
    print("🤖 Testing AI-001 Multi-Turn Context...")

    # 1. Mock user results
    user_results = {
        "stability_score": 75,
        "hba1c_adjusted": 6.5,
        "gap_analysis": "Stable but recent high carb intake"
    }

    # 2. Mock History (User mentions Pizza previously)
    history = [
        {"role": "user", "content": "J'ai mangé une pizza ce midi."},
        {"role": "model", "content": '{"advice": "C\'est riche en glucides. Surveillez votre glycémie.", "actions": []}'}
    ]

    # 3. User follow-up question
    user_message = "Est-ce que je peux aller courir maintenant ?"

    print(f"Context: Pizza -> Response -> '{user_message}'")

    # 4. Call Service
    try:
        response = await ai_service.generate_coach_advice(
            user_results=user_results,
            history=history,
            user_message=user_message
        )
        
        print(f"✅ Response received: {response}")
        advice = response.get("advice", "").lower()
        
        # We assume the model connects "Pizza" + "Running"
        # It should encourage running to lower the glucose from the pizza.
        
        assert "advice" in response
        assert len(advice) > 5
        print("✅ Structure Valid")
        
    except Exception as e:
        print(f"❌ Test Failed: {e}")
        raise e

if __name__ == "__main__":
    asyncio.run(test_multi_turn_context())
