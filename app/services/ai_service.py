import google.genai
from google.genai import types # Add this import
import os
import asyncio
import json
import math
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

    def anonymize_health_snapshot(self, snapshot: schemas.UserHealthSnapshot) -> schemas.UserHealthSnapshot:
        """
        Anonymizes a UserHealthSnapshot to protect user privacy.
        """
        anon_snapshot = snapshot.copy(deep=True)

        # Anonymize age
        age = anon_snapshot.age
        if age < 18:
            anon_snapshot.age = "under 18"
        elif age < 25:
            anon_snapshot.age = "18-24"
        elif age < 35:
            anon_snapshot.age = "25-34"
        elif age < 45:
            anon_snapshot.age = "35-44"
        elif age < 55:
            anon_snapshot.age = "45-54"
        elif age < 65:
            anon_snapshot.age = "55-64"
        else:
            anon_snapshot.age = "65+"

        # Anonymize weight and height using BMI
        try:
            height_m = anon_snapshot.height / 100
            bmi = anon_snapshot.weight / (height_m * height_m)
            if bmi < 18.5:
                bmi_category = "underweight"
            elif bmi < 25:
                bmi_category = "normal weight"
            elif bmi < 30:
                bmi_category = "overweight"
            else:
                bmi_category = "obese"
            anon_snapshot.weight = bmi_category
            anon_snapshot.height = None
        except (ZeroDivisionError, TypeError):
            anon_snapshot.weight = "unknown"
            anon_snapshot.height = None
            

        # Round biometric values
        anon_snapshot.lab_data.hba1c = round(anon_snapshot.lab_data.hba1c, 1)
        anon_snapshot.lab_data.fasting_glucose = int(round(anon_snapshot.lab_data.fasting_glucose / 10) * 10)
        
        for activity in anon_snapshot.recent_activity:
            activity.steps = int(round(activity.steps / 100) * 100)
            activity.calories_burned = int(round(activity.calories_burned / 10) * 10)
            activity.distance_km = round(activity.distance_km, 1)

        for meal in anon_snapshot.recent_meals:
            meal.carbs = int(round(meal.carbs / 5) * 5) if meal.carbs else None
            meal.calories = int(round(meal.calories / 50) * 50) if meal.calories else None


        return anon_snapshot

    def format_health_context(self, snapshot: schemas.UserHealthSnapshot) -> str:
        """
        Transforme un UserHealthSnapshot en contexte textuel pour le prompt Gemini.
        Traceable via Opik car utilisé dans le flux IA.
        """
        anon_snapshot = self.anonymize_health_snapshot(snapshot)

        # Format Activity History
        activity_context = "Pas d'activité récente enregistrée."
        if anon_snapshot.recent_activity:
            last_stats = anon_snapshot.recent_activity[-1] # Most recent
            activity_context = (
                f"Dernière activité ({last_stats.date.strftime('%Y-%m-%d')}): {last_stats.steps} pas, "
                f"{last_stats.calories_burned} kcal brûlées."
            )

        # Format Meal History
        meal_context = "Pas de repas récents enregistrés."
        if anon_snapshot.recent_meals:
            recent_meals_str = [f"- {m.timestamp.strftime('%H:%M')}: {m.name} ({m.carbs}g glucides)" for m in anon_snapshot.recent_meals[-3:]]
            meal_context = "Derniers repas :\n" + "\n".join(recent_meals_str)

        # Build the anonymized context string
        biometrics_str = f"{anon_snapshot.weight}"
        if anon_snapshot.height:
            biometrics_str += f", {anon_snapshot.height}cm"

        # Name
        name_str = f"Nom: {anon_snapshot.name}" if anon_snapshot.name else "Nom: Inconnu"

        # Limitations
        limitations_str = ""
        if anon_snapshot.lifestyle.physical_limitations:
             limitations_str = f"- ⚠️ LIMITATIONS PHYSIQUES : {anon_snapshot.lifestyle.physical_limitations}\n"

        # Format Goals
        goal_context = ""
        if anon_snapshot.target_hba1c:
            goal_context = f"- OBJECTIF: Atteindre HbA1c {anon_snapshot.target_hba1c}%"
            if anon_snapshot.target_hba1c_date:
                goal_context += f" d'ici le {anon_snapshot.target_hba1c_date.strftime('%d/%m/%Y')}"
            goal_context += ".\n"

        return (
            f"PROFIL PATIENT ({name_str}):\n"
            f"- Info: {anon_snapshot.age} ans, {anon_snapshot.lifestyle.gender}, {anon_snapshot.diabetes_type}\n"
            f"- Biométrie: {biometrics_str}\n"
            f"{limitations_str}"
            f"{goal_context}"
            f"- Objectif Pas: {anon_snapshot.lifestyle.daily_step_goal}/jour\n"
            f"- Activité: Niveau {anon_snapshot.lifestyle.activity_level.value}. {activity_context}\n"
            f"- Nutrition: Régime {anon_snapshot.lifestyle.diet_type}. {meal_context}\n"
            f"- Labo: HbA1c {anon_snapshot.lab_data.hba1c}%, Glycémie à jeun {anon_snapshot.lab_data.fasting_glucose}mg/dL.\n"
        )

ai_service = AIService()
