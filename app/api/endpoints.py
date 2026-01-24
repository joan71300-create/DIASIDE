from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from app.models import schemas, models
from app.models.database import get_db
from app.services.ai_service import ai_service
from app.api.auth import get_current_user
from app.core.logger import request_id_context
from app.core.stability_engine import calculate_hba1c_adjustment
from datetime import datetime, timedelta
from sqlalchemy import func
import uuid

router = APIRouter()

@router.post("/ai/coach", response_model=schemas.AIAnalysisResponse)
async def get_coach_advice(
    data: schemas.GlucoseDataCreate,
    request: Request,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Récupération du contexte de traçabilité
    req_id = request_id_context.get()
    
    # Enregistrer la mesure en base (optionnel mais recommandé)
    db_entry = models.GlucoseEntry(
        user_id=current_user.id,
        value=data.value,
        note=data.note
    )
    db.add(db_entry)
    db.commit()

    # Calculate rolling average for last 90 days
    ninety_days_ago = datetime.utcnow() - timedelta(days=90)
    avg_result = db.query(func.avg(models.GlucoseEntry.value)).filter(
        models.GlucoseEntry.user_id == current_user.id,
        models.GlucoseEntry.timestamp >= ninety_days_ago
    ).scalar()
    rolling_avg = float(avg_result) if avg_result else data.value
    
    # Prepare questionnaire data
    q_data = {}
    if current_user.questionnaire:
        q_data = {
            "age": current_user.questionnaire.age,
            "diabetes_type": current_user.questionnaire.diabetes_type,
            # Adaptez selon votre modèle réel
            "is_smoker": False 
        }

    # Miedema HbA1c adjustment
    hba1c_adjusted, correction_factor, stability_summary = calculate_hba1c_adjustment(
        data.value, rolling_avg, q_data
    )

    # Construction du contexte biologique (Ticket 03) avec Miedema
    bio_context = stability_summary
    if current_user.questionnaire:
         bio_context += f" Patient diabétique {current_user.questionnaire.diabetes_type}."
    
    # Appel IA avec métadonnées Opik
    metadata = {
        "user_id": str(current_user.id),
        "request_id": req_id,
        "diabetes_type": current_user.questionnaire.diabetes_type if current_user.questionnaire else "unknown"
    }
    
    analysis_text = ai_service.generate_coach_advice(
        value=data.value, 
        context=bio_context,
        metadata=metadata
    )
    
    return {
        "analysis": analysis_text,
        "hba1c_adjusted": hba1c_adjusted,
        "correction_factor": correction_factor,
        "stability_summary": stability_summary
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
