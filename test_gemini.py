from google import genai
import os
from dotenv import load_dotenv

load_dotenv(override=True)

# REMPLACEZ DIRECTEMENT PAR VOTRE CLÉ ICI LE TEMPS DU TEST
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ ERREUR: La clé API n'a pas été trouvée dans les variables d'environnement.")
else:
    print(f"ℹ️ Clé API trouvée (longueur: {len(api_key)})")

try:
    client = genai.Client(api_key=api_key)
    response = client.models.generate_content(
        model="gemini-3-flash-preview",
        contents="Dis 'OK'"
    )
    print(f"✅ Succès direct ! Gemini répond : {response.text}")
except Exception as e:
    print(f"❌ Erreur lors de la génération : {e}")
    print("\n🔍 Tentative de listage des modèles disponibles...")
    try:
        for m in client.models.list(config={"page_size": 100}):
            print(f" - {m.name}")
    except Exception as list_error:
        print(f"❌ Impossible de lister les modèles : {list_error}")
