import google.genai
import os
import asyncio
from opik.integrations.genai import track_genai
from opik import track
from app.core.config import settings
from app.models import schemas

class AIService:
    def __init__(self):
        # Workaround: google-genai peut privilégier GOOGLE_API_KEY si présent
        if "GOOGLE_API_KEY" in os.environ:
            del os.environ["GOOGLE_API_KEY"]
            
        # Initialisation du client Gemini
        self.client = google.genai.Client(api_key=settings.GEMINI_API_KEY)
        # Note: track_genai wrapping might need adjustment for async calls or handled differently.
        # For now, using raw client for async support to ensure timeout works.
        self.gemini_client = track_genai(self.client, project_name="DIASIDE")

    @track(name="generate_coach_advice")
    async def generate_coach_advice(self, user_results: dict) -> str:
        """
        Ticket B06: Consultation Gemini 3.0 avec injection dynamique des résultats.
        Gère le timeout (2s) et les rate limits via asyncio.
        """
        system_prompt = (
            "Tu es un coach expert en diabète utilisant le modèle de stabilité Miedema. "
            "Ton rôle est d'analyser les résultats ajustés du patient et de fournir "
            "un conseil court, empathique et actionnable. "
            "Ne mentionne pas les calculs internes sauf si nécessaire pour rassurer."
        )
        
        try:
            # Injection dynamique du JSON user_results
            prompt = f"{system_prompt}\n\nVoici les résultats d'analyse :\n{user_results}"
            print(f"--- Envoi à Gemini 3.0 (Timeout 10s): {prompt[:100]}... ---")
            
            # Utilisation de asyncio.wait_for pour le timeout
            # Utilisation de client.aio pour l'appel asynchrone
            response = await asyncio.wait_for(
                self.client.aio.models.generate_content(
                    model="gemini-3-flash-preview", 
                    contents=prompt,
                    config={'response_mime_type': 'text/plain'}
                ),
                timeout=10.0
            )
            return response.text
        except asyncio.TimeoutError:
            print("❌ Timeout Gemini (10s exceeded)")
            return "Désolé, le service est un peu lent. Veuillez réessayer."
        except Exception as e:
            print(f"❌ Erreur Gemini : {e}")
            if "429" in str(e) or "503" in str(e):
                return "Le service est temporairement surchargé (Rate Limit/Overloaded). Veuillez réessayer."
            return f"Erreur IA: {str(e)}"

    def format_health_context(self, snapshot: schemas.UserHealthSnapshot) -> str:
        """
        Transforme un UserHealthSnapshot en contexte textuel pour le prompt Gemini.
        Traceable via Opik car utilisé dans le flux IA.
        """
        return (
            f"Patient de {snapshot.age} ans, diabétique {snapshot.diabetes_type}. "
            f"Poids: {snapshot.weight}kg, Taille: {snapshot.height}cm. "
            f"HbA1c: {snapshot.lab_data.hba1c}%, Glycémie à jeun: {snapshot.lab_data.fasting_glucose}mg/dL. "
            f"Mode de vie: {snapshot.lifestyle.activity_level.value}, Régime: {snapshot.lifestyle.diet_type}, "
            f"Fumeur: {'Oui' if snapshot.lifestyle.is_smoker else 'Non'}."
        )

ai_service = AIService()
