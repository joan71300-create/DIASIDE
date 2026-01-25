import google.genai
import os
import asyncio
import json
from opik.integrations.genai import track_genai
from opik import track
from app.core.config import settings
from app.models import schemas
from app.core.guardrails import SafetyGuardrails

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
    async def generate_coach_advice(self, user_results: dict) -> dict:
        """
        Ticket B06/DS-B-011: Consultation Gemini 3.0 avec injection dynamique et réponse structurée (JSON).
        Gère le timeout (10s) et les rate limits.
        """
        system_prompt = (
            "Tu es un coach expert en diabète utilisant le modèle de stabilité Miedema. "
            "Ton rôle est d'analyser les résultats ajustés du patient et de fournir "
            "un conseil court, empathique et actionnable.\n"
            "Format de réponse JSON attendu :\n"
            "{\n"
            '  "advice": "texte du conseil",\n'
            '  "actions": [{"label": "Action courte (ex: Marche 10min)", "type": "sport|diet|check|medical"}]\n'
            "}"
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
                    config={'response_mime_type': 'application/json'}
                ),
                timeout=10.0
            )
            response_text = response.text
            
            # Parsing JSON
            try:
                response_json = json.loads(response_text)
                advice_text = response_json.get("advice", "")
            except json.JSONDecodeError:
                # Fallback si le modèle renvoie du texte brut
                response_json = {"advice": response_text, "actions": []}
                advice_text = response_text

            # --- TICKET B07: GUARDRAILS ---
            # On vérifie le texte du conseil
            is_safe_keyword, reason_keyword = SafetyGuardrails.check_keywords(advice_text)
            if not is_safe_keyword:
                print(f"🚫 BLOCKED by Regex: {reason_keyword}")
                raise ValueError(f"Safety Violation: {reason_keyword}")

            # 2. LLM-as-a-Judge (Opik Scorer)
            judge_prompt = SafetyGuardrails.get_judge_prompt(advice_text)
            try:
                # Appel rapide au juge (timeout court 5s)
                judge_response = await asyncio.wait_for(
                    self.client.aio.models.generate_content(
                        model="gemini-3-flash-preview",
                        contents=judge_prompt,
                        config={'response_mime_type': 'application/json'}
                    ),
                    timeout=5.0
                )
                evaluation = json.loads(judge_response.text)
                
                # Log to Opik
                print(f"⚖️ LLM Judge Score: {evaluation}")
                
                if not evaluation.get("safe", True):
                    print(f"🚫 BLOCKED by LLM Judge: {evaluation.get('reason')}")
                    raise ValueError(f"Safety Violation: {evaluation.get('reason')}")
                    
            except Exception as e_judge:
                print(f"⚠️ LLM Judge Error: {e_judge}")

            return response_json

        except ValueError as ve:
            raise ve
        except asyncio.TimeoutError:
            print("❌ Timeout Gemini (10s exceeded)")
            return {"advice": "Désolé, le service est un peu lent. Veuillez réessayer.", "actions": []}
        except Exception as e:
            print(f"❌ Erreur Gemini : {e}")
            if "429" in str(e) or "503" in str(e):
                return {"advice": "Le service est temporairement surchargé. Veuillez réessayer.", "actions": []}
            return {"advice": f"Erreur IA: {str(e)}", "actions": []}

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
