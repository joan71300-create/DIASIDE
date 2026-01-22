import os
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv
import google.genai
from opik.integrations.genai import track_genai

# 1. Charger le .env en forçant l'écrasement
load_dotenv(override=True)

# 2. NETTOYAGE CRITIQUE : Supprimer la variable qui cause le conflit
if "GOOGLE_API_KEY" in os.environ:
    del os.environ["GOOGLE_API_KEY"]

app = FastAPI()

# 3. Récupérer votre clé valide
ma_cle = os.getenv("GEMINI_API_KEY")

# 4. Initialisation du client
client = google.genai.Client(api_key=ma_cle)
gemini_client = track_genai(client)

class GlucoseData(BaseModel):
    value: float

@app.post("/analyze")
async def analyze_glucose(data: GlucoseData):
    print(f"--- Analyse en cours pour : {data.value} mg/dL ---")
    try:
        # On utilise gemini-1.5-flash qui est plus stable sur les quotas
        response = gemini_client.models.generate_content(
            model="gemini-3-flash-preview", 
            contents=f"Le patient a {data.value} mg/dL de glucose. Donne un conseil court."
        )
        return {"analysis": response.text}
    except Exception as e:
        print(f"❌ Erreur Gemini : {e}")
        return {"analysis": "L'IA est momentanément indisponible."}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)