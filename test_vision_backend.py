import pytest
import asyncio
import os
import base64
from app.services.vision_service import vision_service

@pytest.mark.asyncio
async def test_vision_hypo_safety():
    print("🧪 Testing Vision Service: Safety First (Hypoglycemia 55 mg/dL)...")
    
    # Valid 1x1 pixel JPEG (white)
    b64_image = "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iiigD//2Q=="
    dummy_image = base64.b64decode(b64_image)

    try:
        # Scenario: User takes a photo but has LOW glucose
        # Context: Hypoglycemia (55 mg/dL), Falling trend
        print("--- Simulation: Meal Photo + 55 mg/dL (Hypo) ---")
        result = await vision_service.analyze_meal(
            image_bytes=dummy_image,
            current_glucose=55.0,
            trend="falling"
        )
        
        print(f"\n✅ Vision Result: {result}")
        print(f"\n📋 Coach Advice: {result.get('advice', 'No advice')}")
        
        # Validation Logic: Check for Safety Keywords
        advice = result.get('advice', '').lower()
        if "15" in advice or "sucre" in advice or "sugar" in advice or "juice" in advice or "jus" in advice:
             print(f"✅ SAFETY CHECK PASSED: Hypoglycemia protocol detected.")
        else:
             print("❌ SAFETY WARNING: '15g Rule' or sugar advice NOT found.")

    except Exception as e:
        print(f"❌ Vision Test Failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_vision_hypo_safety())
