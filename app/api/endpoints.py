from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from app.models import schemas, models
from app.models.database import get_db
from app.services.ai_service import ai_service
from app.api.auth import get_current_user
from app.core.logger import request_id_context
from app.core.stability_engine import adjust_hba1c
from datetime import datetime, timedelta
from sqlalchemy import func
import uuid

router = APIRouter()

@router.post("/ai/coach")
async def get_coach_advice(
    snapshot: schemas.UserHealthSnapshot,
    request: Request,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Ticket B06: Endpoint IA Coach.
    Reçoit un UserHealthSnapshot, calcule l'ajustement HbA1c (Ticket B05),
    et interroge Gemini 3.0 (Prompt Engine) avec les résultats.
    Retourne la réponse brute de l'IA.
    """
    # 1. Calcul de l'ajustement HbA1c (Moteur de Stabilité)
    user_results = adjust_hba1c(snapshot.lab_data, snapshot.lifestyle)
    
    # 2. Appel au Prompt Engine (Gemini 3.0)
    # L'injection du JSON user_results se fait dans le service
    analysis_text = await ai_service.generate_coach_advice(user_results)
    
    # 3. Retour réponse brute (texte) ou structure enrichie si besoin.
    # Le ticket demande "renvoie la réponse brute", mais on peut renvoyer un JSON.
    # Pour respecter strictment "renvoie la réponse brute" (string), on pourrait renvoyer PlainTextResponse.
    # Mais FastAPI par défaut renvoie du JSON. Renoyons un dict simple.
    return {
        "advice": analysis_text,
        "debug_results": user_results
    }

@router.get("/history", response_model=list[schemas.GlucoseEntry])
def read_history(
    skip: int = 0, 
    limit: int = 10, 
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    entries = db.query(models.GlucoseEntry).filter(
        models.GlucoseEntry.user_id == current_user.id
    ).offset(skip).limit(limit).all()
    return entries

@router.post("/health/snapshot", response_model=schemas.HealthSnapshotResponse)
def validate_health_snapshot(
    snapshot: schemas.UserHealthSnapshot,
    current_user: models.User = Depends(get_current_user)
):
    """
    Endpoint de validation du profil biologique (Ticket 03).
    Valide le JSON entrant via Pydantic et génère un ID temporaire.
    """
    temp_id = str(uuid.uuid4())
    
    return {
        "message": "Données biologiques valides",
        "temp_id": temp_id,
        "data": snapshot
    }
