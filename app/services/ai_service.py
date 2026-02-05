import google.genai
from google.genai import types # Add this import
import os
import asyncio
import json
from opik.integrations.genai import track_genai
from opik import track
from app.core.config import settings
from app.models import schemas
from app.core.guardrails import SafetyGuardrails
from app.core.prompts import COACH_SYSTEM_PROMPT

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
    async def generate_coach_advice(self, user_results: dict, history: list = [], user_message: str = None, health_context: str = "", image_bytes: bytes = None) -> dict:
        """
        Ticket B06/DS-B-011: Consultation Gemini 3.0 avec injection dynamique et réponse structurée (JSON).
        Gère le timeout (10s) et les rate limits.
        
        Ticket AI-001: Ajout du support Multi-Turn (history + user_message).
        Ticket AI-005: Utilisation du prompt centralisé avec Few-Shot.
        """
        try:
            # Injection dynamique du JSON user_results
            prompt = f"{COACH_SYSTEM_PROMPT}\n\n"
            
            if health_context:
                prompt += f"{health_context}\n\n"
            
            prompt += f"Analyse Stabilité & Médicale :\n{user_results}"
            
            # --- TICKET AI-001: Context Injection ---
            if history:
                prompt += "\n\nHistorique de la conversation (derniers messages) :\n"
                # Sliding window simple (last 5 messages) to save tokens
                for msg in history[-5:]:
                    # Handle both dict and Pydantic model safely
                    if isinstance(msg, dict):
                        role = msg.get('role', 'user')
                        content = msg.get('content', '')
                    else:
                        role = getattr(msg, 'role', 'user')
                        content = getattr(msg, 'content', '')
                        
                    prompt += f"- {role.upper()}: {content}\n"
            
            if user_message:
                prompt += f"\n\nNouvelle question de l'utilisateur : {user_message}"
            
            # Si image présente, on l'ajoute au prompt comme "Regarde ça"
            if image_bytes:
                prompt += "\n\n[IMAGE INCLUSE] L'utilisateur a joint une image (Graphique ou Repas) pour analyse."
            # ----------------------------------------

            print(f"--- Envoi à Gemini 2.5 Flash (Timeout 20s): {prompt[:200]}... ---")
            
            # Construction du contenu (Texte + Image potentielle)
            contents = [prompt]
            if image_bytes:
                image_part = types.Part.from_bytes(
                    data=image_bytes,
                    mime_type="image/jpeg" # On assume JPEG pour simplifier, ou on détectera plus tard
                )
                contents.append(image_part)

            # Utilisation de asyncio.wait_for pour le timeout
            # Utilisation de client.aio pour l'appel asynchrone
            response = await asyncio.wait_for(
                self.client.aio.models.generate_content(
                    model="gemini-2.5-flash", 
                    contents=contents,
                    config={'response_mime_type': 'application/json'}
                ),
                timeout=20.0
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
                        model="gemini-2.5-flash",
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
            print("❌ Timeout Gemini (20s exceeded)")
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
        # Format Activity History
        activity_context = "Pas d'activité récente enregistrée."
        if snapshot.recent_activity:
            last_stats = snapshot.recent_activity[-1] # Most recent
            activity_context = (
                f"Dernière activité ({last_stats.date.strftime('%Y-%m-%d')}): {last_stats.steps} pas, "
                f"{last_stats.calories_burned} kcal brûlées."
            )

        # Format Meal History
        meal_context = "Pas de repas récents enregistrés."
        if snapshot.recent_meals:
            recent_meals_str = [f"- {m.timestamp.strftime('%H:%M')}: {m.name} ({m.carbs}g glucides)" for m in snapshot.recent_meals[-3:]]
            meal_context = "Derniers repas :\n" + "\n".join(recent_meals_str)

        return (
            f"PROFIL PATIENT :\n"
            f"- Info: {snapshot.age} ans, {snapshot.lifestyle.gender}, {snapshot.diabetes_type}\n"
            f"- Biométrie: {snapshot.weight}kg, {snapshot.height}cm\n"
            f"- Objectif Pas: {snapshot.lifestyle.daily_step_goal}/jour\n"
            f"- Activité: Niveau {snapshot.lifestyle.activity_level.value}. {activity_context}\n"
            f"- Nutrition: Régime {snapshot.lifestyle.diet_type}. {meal_context}\n"
            f"- Labo: HbA1c {snapshot.lab_data.hba1c}%, Glycémie à jeun {snapshot.lab_data.fasting_glucose}mg/dL.\n"
        )

ai_service = AIService()
