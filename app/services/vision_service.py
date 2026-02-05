import google.genai
from google.genai import types
import os
import asyncio
import json
from app.core.config import settings
from opik.integrations.genai import track_genai
from opik import track
from app.core.prompts import VISION_COACH_PROMPT

class VisionService:
    def __init__(self):
        # Workaround: google-genai peut privilégier GOOGLE_API_KEY si présent
        if "GOOGLE_API_KEY" in os.environ:
            del os.environ["GOOGLE_API_KEY"]
            
        self.client = google.genai.Client(api_key=settings.GEMINI_API_KEY)
        # Tracking Opik
        self.gemini_client = track_genai(self.client, project_name="DIASIDE")

    @track(name="analyze_meal_vision")
    async def analyze_meal(self, image_bytes: bytes, current_glucose: float, trend: str = "stable") -> dict:
        """
        Ticket COACH-03.1: Analyse visuelle de repas avec Gemini 2.0 Flash.
        Prend une image et le contexte glycémique.
        Ticket AI-005: Utilisation du prompt centralisé.
        """
        full_prompt = f"{VISION_COACH_PROMPT}\n\nContexte Actuel : Glycémie {current_glucose} mg/dL, Tendance {trend}."

        try:
            # Préparation du contenu multimodal
            # L'image doit être passée en bytes avec son mime_type
            image_part = types.Part.from_bytes(
                data=image_bytes,
                mime_type="image/jpeg"
            )

            print(f"--- Envoi Vision à Gemini (Glucose: {current_glucose}) ---")
            
            response = await asyncio.wait_for(
                self.client.aio.models.generate_content(
                    model="gemini-2.5-flash", 
                    contents=[full_prompt, image_part],
                    config={'response_mime_type': 'application/json'}
                ),
                timeout=30.0
            )
            
            return json.loads(response.text)
            
        except asyncio.TimeoutError:
            return {"carbs": 0, "advice": "Analyse trop longue, le service est surchargé."}
        except Exception as e:
            print(f"❌ Erreur Vision : {e}")
            return {"carbs": 0, "advice": f"Erreur lors de l'analyse : {str(e)}"}

vision_service = VisionService()
