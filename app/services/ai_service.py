import google.genai
import os
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
        # Note: Opik tracke automatiquement si configuré
        self.client = google.genai.Client(api_key=settings.GEMINI_API_KEY)
        self.gemini_client = track_genai(self.client, project_name="DIASIDE")

    @track(name="generate_coach_advice")
    def generate_coach_advice(self, value: float, context: str = "", metadata: dict = None) -> str:
        """
        Analyse une valeur de glycémie avec Gemini, tracké par Opik.
        """
        try:
            prompt = f"Le patient a {value} mg/dL de glucose. {context} Donne un conseil court et bienveillant."
            print(f"--- Envoi à Gemini (Opik active): {prompt} ---")
            
            # Opik capture automatiquement les métadonnées passées si configuré correctement,
            # mais ici on utilise le décorateur @track pour ajouter des tags/metadata explicites si besoin.
            # L'intégration track_genai gère déjà beaucoup de choses.
            
            response = self.gemini_client.models.generate_content(
                model="gemini-3-flash-preview", 
                contents=prompt
            )
            return response.text
        except Exception as e:
            print(f"❌ Erreur Gemini : {e}")
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
