import os
from dotenv import load_dotenv
import google.genai
from opik import configure
from opik.integrations.genai import track_genai

# 1. On force le chargement du .env et on écrase les variables système existantes
load_dotenv(override=True) 

# 2. On récupère la clé du .env
ma_cle_gemini = os.getenv("GEMINI_API_KEY")

# 3. Configuration Opik (automatique via OPIK_API_KEY dans le .env)
configure()

# 4. INITIALISATION CRITIQUE : on passe la clé explicitement pour ignorer 
# les variables "fantômes" de Windows (GOOGLE_API_KEY)
client = google.genai.Client(api_key=ma_cle_gemini)
gemini_client = track_genai(client)

def test_ai_connection():
    print(f"--- Diagnostic DIASIDE ---")
    if not ma_cle_gemini:
        print("❌ Erreur : GEMINI_API_KEY est vide dans le fichier .env")
        return
    
    # On affiche les 4 derniers caractères pour vérifier sans l'exposer
    print(f"Clé utilisée (fin) : ...{ma_cle_gemini[-4:]}")

    try:
        print("Envoi de la requête à Gemini...")
        response = gemini_client.models.generate_content(
            model="gemini-3-flash-preview",
            contents="Dis 'Système DIASIDE opérationnel' en une phrase."
        )
        print(f"✅ Réponse de l'IA : {response.text}")
        print("🚀 Trace enregistrée avec succès sur Opik !")
    except Exception as e:
        print(f"❌ Gemini rejette encore la clé : {e}")

if __name__ == "__main__":
    test_ai_connection()