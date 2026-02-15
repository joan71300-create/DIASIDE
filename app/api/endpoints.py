from fastapi import APIRouter, Depends, Request, HTTPException, UploadFile, File, Form # Corrected import
from sqlalchemy.orm import Session
from opik import track
from app.models import schemas, models
from app.models.database import get_db
from app.services.ai_service import ai_service
from app.services.nightscout_service import nightscout_service
from app.services.medtrum_service import medtrum_service # Added import
from app.services.vision_service import vision_service # Import vision_service
from app.api.auth import get_current_user
from app.core.logger import request_id_context
from app.core.stability_engine import analyze_stability
from app.core.config import settings
from datetime import datetime, timedelta
from sqlalchemy import func
import uuid
import base64 # Import base64

router = APIRouter()

@router.post("/medtrum/connect")
@track(name="api_medtrum_connect")
def connect_medtrum(
    payload: schemas.MedtrumConnectRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Connecte et synchronise les données Medtrum (Direct Scraping).
    """
    try:
        # Configurer la région si besoin (TODO: implémenter dans le service)
        if payload.region == "com":
            medtrum_service.BASE_URL = "https://easyview.medtrum.com"
        else:
            medtrum_service.BASE_URL = "https://easyview.medtrum.fr"
            
        result = medtrum_service.sync_data(
            db, 
            current_user, 
            payload.username, 
            payload.password,
            days=90 # On récupère 90 jours direct pour l`HbA1c
        )
        
        # Sauvegarder les identifiants pour la sync automatique
        creds = db.query(models.MedtrumCredentials).filter(
            models.MedtrumCredentials.user_id == current_user.id
        ).first()
        if creds:
            creds.username = payload.username
            creds.password = payload.password
            creds.region = payload.region
        else:
            creds = models.MedtrumCredentials(
                user_id=current_user.id,
                username=payload.username,
                password=payload.password,
                region=payload.region
            )
            db.add(creds)
        db.commit()
        
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/medtrum/sync")
@track(name="api_medtrum_sync_auto")
def sync_medtrum_auto(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Synchronise automatiquement les données Medtrum si les identifiants sont stockés.
    Appelé par l'app à chaque ouverture.
    """
    # Récupérer les identifiants
    creds = db.query(models.MedtrumCredentials).filter(
        models.MedtrumCredentials.user_id == current_user.id
    ).first()
    
    if not creds:
        return {"status": "no_credentials", "message": "Aucun compte Medtrum connecté"}
    
    try:
        # Configurer la région
        if creds.region == "com":
            medtrum_service.BASE_URL = "https://easyview.medtrum.com"
        else:
            medtrum_service.BASE_URL = "https://easyview.medtrum.fr"
        
        # Sync seulement 1 jour (données récentes)
        result = medtrum_service.sync_data(
            db,
            current_user,
            creds.username,
            creds.password,
            days=1
        )
        
        # Mettre à jour last_sync
        creds.last_sync = datetime.utcnow()
        db.commit()
        
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/nightscout/sync")
@track(name="api_nightscout_sync")
async def sync_nightscout(
    payload: schemas.NightscoutSyncRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Synchronise les données depuis une instance Nightscout.
    """
    result = await nightscout_service.sync_user_data(
        db, 
        current_user, 
        payload.url, 
        payload.token
    )
    return result

@router.post("/ai/coach")
@track(name="api_coach_advice")
async def get_coach_advice(
    chat_request: schemas.ChatRequest,
    request: Request,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Ticket B06: Endpoint IA Coach.
    Reçoit un ChatRequest (Snapshot + Historique), calcule l`ajustement HbA1c (Ticket B05),
    et interroge Gemini 3.0 (Prompt Engine) avec les résultats.
    Retourne la réponse brute de l`IA.
    """
    snapshot = chat_request.snapshot

    # 1. Calcul de la moyenne glissante (90j) depuis la base de données (T-M001)
    ninety_days_ago = datetime.utcnow() - timedelta(days=90)
    avg_result = db.query(func.avg(models.GlucoseEntry.value)).filter(
        models.GlucoseEntry.user_id == current_user.id,
        models.GlucoseEntry.timestamp >= ninety_days_ago
    ).scalar()
    
    # Si pas de données, on utilise la glycémie à jeun du snapshot comme estimation
    rolling_avg = float(avg_result) if avg_result else float(snapshot.lab_data.fasting_glucose)

    # 2. Analyse Complète de Stabilité (Ajustement HbA1c + Gap Analysis)
    user_results = analyze_stability(snapshot.lab_data, snapshot.lifestyle, rolling_avg)
    
    # --- TICKET CARTE BLANCHE: Enrichissement via DB ---
    # On charge les dernières stats et repas depuis la BDD pour donner le contexte réel à l`IA
    today = datetime.utcnow().date()
    db_stats = db.query(models.DailyStats).filter(
        models.DailyStats.user_id == current_user.id,
        func.date(models.DailyStats.date) == today
    ).first()
    
    if db_stats:
        snapshot.recent_activity.append(schemas.DailyStats.model_validate(db_stats))
    
    db_meals = db.query(models.Meal).filter(
        models.Meal.user_id == current_user.id
    ).order_by(models.Meal.timestamp.desc()).limit(3).all()
    
    if db_meals:
        snapshot.recent_meals = [schemas.Meal.model_validate(m) for m in db_meals]
        
    # Inject Goals from Questionnaire (Fix for Context Blindness)
    if current_user.questionnaire:
        snapshot.target_hba1c = current_user.questionnaire.target_hba1c
        snapshot.target_hba1c_date = current_user.questionnaire.target_hba1c_date
    # ---------------------------------------------------

    # Generate holistic context string
    health_ctx_str = ai_service.format_health_context(snapshot)
    
    # Décoder l`image si présente (Base64 -> Bytes)
    image_bytes = None
    if chat_request.image_base64:
        import base64
        try:
            # On nettoie le préfixe si présent (ex: "data:image/jpeg;base64,")
            b64_str = chat_request.image_base64
            if "," in b64_str:
                b64_str = b64_str.split(",")[1]
            image_bytes = base64.b64decode(b64_str)
        except Exception as e:
            print(f"⚠️ Erreur décodage image: {e}")

    # 3. Appel au Prompt Engine (Gemini 3.0) - Retourne maintenant un DICT structuré
    try:
        ai_response = await ai_service.generate_coach_advice(
            user_results, 
            history=chat_request.history,
            user_message=chat_request.user_message,
            health_context=health_ctx_str,
            image_bytes=image_bytes
        )
    except ValueError as e:
        if "Safety Violation" in str(e):
            # Return a generic message if blocked by safety filter
            return schemas.AIAnalysisResponse(
                advice="Je ne peux pas te donner de conseil sur ce sujet pour des raisons de sécurité. N\`hésite pas si tu as d\`autres questions.",
                actions=[],
                debug_results=user_results
            )
        raise e
    
    # 4. Construction de la réponse structurée (DS-B-011)
    return schemas.AIAnalysisResponse(
        advice=ai_response.get("advice", ""),
        actions=ai_response.get("actions", []),
        debug_results=user_results
    )

@router.post("/log/activity", response_model=schemas.DailyStats)
@track(name="api_log_activity")
def log_activity(
    stats: schemas.DailyStatsCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Log daily activity stats (steps, calories).
    Update if exists for today, else create.
    """
    today = datetime.utcnow().date()
    db_stats = db.query(models.DailyStats).filter(
        models.DailyStats.user_id == current_user.id,
        func.date(models.DailyStats.date) == today
    ).first()

    if db_stats:
        db_stats.steps = stats.steps
        db_stats.calories_burned = stats.calories_burned
        db_stats.distance_km = stats.distance_km
    else:
        db_stats = models.DailyStats(
            user_id=current_user.id,
            **stats.model_dump()
        )
        db.add(db_stats)
    
    db.commit()
    db.refresh(db_stats)
    return db_stats

@router.post("/log/meal", response_model=schemas.Meal)
@track(name="api_log_meal")
def log_meal(
    meal: schemas.MealCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Log a meal.
    """
    db_meal = models.Meal(
        user_id=current_user.id,
        **meal.model_dump()
    )
    db.add(db_meal)
    db.commit()
    db.refresh(db_meal)
    return db_meal

@router.get("/history", response_model=list[schemas.GlucoseEntry])
@track(name="api_read_history")
def read_history(
    skip: int = 0, 
    limit: int = 10, 
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    entries = db.query(models.GlucoseEntry).filter(
        models.GlucoseEntry.user_id == current_user.id
    ).order_by(models.GlucoseEntry.timestamp.desc()).offset(skip).limit(limit).all()
    return entries

@router.get("/stats/tir")
@track(name="api_get_tir")
def get_tir_stats(
    days: int = 1,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Calculates Time In Range (TIR) stats.
    Target: 70-180 mg/dL
    """
    start_date = datetime.utcnow() - timedelta(days=days)
    entries = db.query(models.GlucoseEntry).filter(
        models.GlucoseEntry.user_id == current_user.id,
        models.GlucoseEntry.timestamp >= start_date
    ).all()
    
    if not entries:
        return {"low": 0, "normal": 0, "high": 0, "count": 0}
        
    low = 0
    normal = 0
    high = 0
    
    for e in entries:
        if e.value < 70:
            low += 1
        elif e.value > 180:
            high += 1
        else:
            normal += 1
            
    total = len(entries)
    return {
        "low": round((low / total) * 100, 1),
        "normal": round((normal / total) * 100, 1),
        "high": round((high / total) * 100, 1),
        "count": total,
        "avg": round(sum(e.value for e in entries) / total, 0)
    }

@router.get("/stats/hba1c")
@track(name="api_get_hba1c")
def get_hba1c_stats(
    days: int = 90,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Calcule l`HbA1c estimée sur X jours directement en base.
    Optimisé pour les gros volumes de données.
    """
    start_date = datetime.utcnow() - timedelta(days=days)
    
    avg_glucose = db.query(func.avg(models.GlucoseEntry.value)).filter(
        models.GlucoseEntry.user_id == current_user.id,
        models.GlucoseEntry.timestamp >= start_date
    ).scalar()
    
    if not avg_glucose:
        return {"estimated_hba1c": None, "avg_glucose": None, "points": 0}
        
    avg_val = float(avg_glucose)
    estimated_hba1c = (avg_val + 46.7) / 28.7
    
    # Récupérer l`offset utilisateur
    offset = current_user.questionnaire.hba1c_offset if current_user.questionnaire else 0.0
    
    return {
        "estimated_hba1c": estimated_hba1c + offset,
        "raw_hba1c": estimated_hba1c,
        "offset": offset,
        "avg_glucose": avg_val,
        "points": 90000 # Juste pour info, on pourrait faire un count() mais c`est lourd
    }

@router.post("/health/snapshot", response_model=schemas.HealthSnapshotResponse)
@track(name="api_health_snapshot")
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

@router.post("/cgm", response_model=schemas.GlucoseEntry)
@track(name="api_receive_cgm")
def receive_cgm_ping(
    ping: schemas.CGMPing,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Ticket T-API001: Réception des pings CGM.
    Enregistre une nouvelle mesure de glucose provenant d`un capteur.
    Met à jour le questionnaire si fourni (T-SEC001).
    """
    # Mise à jour du Questionnaire (T-SEC001)
    if ping.questionnaire:
        # Check if exists
        db_quest = db.query(models.Questionnaire).filter(models.Questionnaire.user_id == current_user.id).first()
        if db_quest:
            # Update
            for key, value in ping.questionnaire.model_dump().items():
                setattr(db_quest, key, value)
        else:
            # Create
            db_quest = models.Questionnaire(
                user_id=current_user.id,
                **ping.questionnaire.model_dump()
            )
            db.add(db_quest)
        db.commit()

    db_entry = models.GlucoseEntry(
        user_id=current_user.id,
        value=ping.value,
        timestamp=ping.timestamp or datetime.utcnow(),
        note=f"CGM Upload ({ping.device_id})"
    )
    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)
    return db_entry

@router.put("/profile", response_model=schemas.Questionnaire)
@track(name="api_update_profile")
def update_profile(
    profile_data: schemas.QuestionnaireCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update user profile / questionnaire (Personalization).
    """
    db_quest = db.query(models.Questionnaire).filter(models.Questionnaire.user_id == current_user.id).first()
    
    if not db_quest:
        # Create if missing
        db_quest = models.Questionnaire(
            user_id=current_user.id,
            **profile_data.model_dump()
        )
        db.add(db_quest)
    else:
        # Update fields
        for key, value in profile_data.model_dump(exclude_unset=True).items():
            setattr(db_quest, key, value)
            
    db.commit()
    db.refresh(db_quest)
    return db_quest

@router.get("/profile", response_model=schemas.Questionnaire)
def get_profile(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_quest = db.query(models.Questionnaire).filter(models.Questionnaire.user_id == current_user.id).first()
    if not db_quest:
        # Return default/empty
        return schemas.Questionnaire(
            id=0, 
            user_id=current_user.id, 
            age=30, weight=70, height=170, diabetes_type="Type 1",
            target_glucose_min=70, target_glucose_max=180
        )
    return db_quest

# --- NEW ENDPOINT FOR FOOD RECOGNITION (Base64) ---
@router.post("/vision/food", response_model=schemas.FoodRecognitionResponse)
@track(name="api_food_recognition")
async def analyze_food_image(
    image: UploadFile = File(...),
    current_glucose: float = Form(...),
    trend: str = Form(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Analyzes an image of food to estimate nutritional information (carbs) and provide advice.
    """
    try:
        image_bytes = await image.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error reading image file: {e}")

    try:
        # Call the VisionService to analyze the meal
        analysis_result = await vision_service.analyze_meal(
            image_bytes=image_bytes,
            current_glucose=current_glucose,
            trend=trend
        )

        # Format the result into the response model
        return schemas.FoodRecognitionResponse(
            carbs=float(analysis_result.get("carbs", 0.0)),
            advice=analysis_result.get("advice", "No advice available.")
        )

    except Exception as e:
        # Catch any other potential errors during analysis
        print(f"Error during food analysis: {e}")
        raise HTTPException(status_code=500, detail="Error processing food image analysis.")


# --- ENDPOINT FOR FOOD RECOGNITION (Base64 JSON) ---
@router.post("/vision/food/base64", response_model=schemas.FoodRecognitionResponse)
@track(name="api_food_recognition_base64")
async def analyze_food_image_base64(
    payload: schemas.FoodRecognitionRequest,
    current_user: models.User = Depends(get_current_user)
):
    """
    Analyzes an image of food using base64 string.
    """
    try:
        # Decode base64 to bytes
        image_data = payload.image_base64
        if "," in image_data:
            image_data = image_data.split(",")[1]
        image_bytes = base64.b64decode(image_data)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error decoding image: {e}")

    try:
        # Call the VisionService to analyze the meal
        analysis_result = await vision_service.analyze_meal(
            image_bytes=image_bytes,
            current_glucose=payload.current_glucose,
            trend=payload.trend
        )

        # Format the result into the response model
        return schemas.FoodRecognitionResponse(
            carbs=float(analysis_result.get("carbs", 0.0)),
            advice=analysis_result.get("advice", "No advice available.")
        )

    except Exception as e:
        print(f"Error during food analysis: {e}")
        raise HTTPException(status_code=500, detail="Error processing food image analysis.")

# --- END NEW ENDPOINT ---


if settings.ENABLE_SIMULATION_ENDPOINT:
    @router.post("/simulation/start")
    @track(name="api_simulation_start")
    def start_simulation(
        target_avg_glucose: int = 160, # ~7.2% HbA1c
        days: int = 90,
        current_user: models.User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ):
        """
        Génère des données fictives sur X jours pour simuler un historique.
        Utile pour tester le calcul HbA1c.
        """
        import random
        
        # Nettoyage des anciennes données simulées (optionnel)
        # db.query(models.GlucoseEntry).filter(models.GlucoseEntry.user_id == current_user.id).delete()
        
        start_date = datetime.utcnow() - timedelta(days=days)
        entries = []
        
        for day in range(days):
            day_date = start_date + timedelta(days=day)
            # 4 mesures par jour (Matin, Midi, Soir, Nuit)
            for hour in [8, 13, 19, 23]:
                # Simulation : Onde sinusoïdale + Bruit aléatoire
                base_value = target_avg_glucose + random.randint(-40, 40)
                
                # Post-prandial spikes (Midi et Soir)s
                if hour in [13, 19]:
                    base_value += random.randint(20, 60)
                    
                entry = models.GlucoseEntry(
                    user_id=current_user.id,
                    value=float(base_value),
                    timestamp=day_date.replace(hour=hour, minute=random.randint(0, 59)),
                    note="Simulation"
                )
                entries.append(entry)
        
        db.add_all(entries)
        db.commit()
        
        return {"message": f"Simulation terminée : {len(entries)} points générés.", "avg_target": target_avg_glucose}


# ==================== NOUVEAUX ENDPOINTS POUR LA MÉMOIRE DU CHATBOT ====================

@router.post("/chat/create", response_model=schemas.ConversationResponse)
@track(name="api_create_conversation")
def create_conversation(
    payload: schemas.ConversationCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Crée une nouvelle conversation.
    """
    conversation = models.Conversation(
        user_id=current_user.id,
        title=payload.title or f"Conversation du {datetime.utcnow().strftime('%d/%m/%Y %H:%M')}"
    )
    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    return conversation


@router.get("/chat/history", response_model=list[schemas.ConversationListResponse])
@track(name="api_get_conversations")
def get_conversations(
    limit: int = 20,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Liste toutes les conversations de l'utilisateur.
    """
    conversations = db.query(models.Conversation).filter(
        models.Conversation.user_id == current_user.id
    ).order_by(models.Conversation.updated_at.desc()).limit(limit).all()
    
    result = []
    for conv in conversations:
        message_count = db.query(func.count(models.Message.id)).filter(
            models.Message.conversation_id == conv.id
        ).scalar() or 0
        
        result.append(schemas.ConversationListResponse(
            id=conv.id,
            title=conv.title,
            created_at=conv.created_at,
            updated_at=conv.updated_at,
            message_count=message_count
        ))
    
    return result


@router.get("/chat/{conversation_id}/messages", response_model=schemas.ConversationResponse)
@track(name="api_get_messages")
def get_messages(
    conversation_id: int,
    limit: int = 50,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Récupère tous les messages d'une conversation.
    """
    conversation = db.query(models.Conversation).filter(
        models.Conversation.id == conversation_id,
        models.Conversation.user_id == current_user.id
    ).first()
    
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation non trouvée")
    
    messages = db.query(models.Message).filter(
        models.Message.conversation_id == conversation_id
    ).order_by(models.Message.timestamp.asc()).limit(limit).all()
    
    conversation.messages = messages
    return conversation


@router.delete("/chat/{conversation_id}")
@track(name="api_delete_conversation")
def delete_conversation(
    conversation_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Supprime une conversation et tous ses messages.
    """
    conversation = db.query(models.Conversation).filter(
        models.Conversation.id == conversation_id,
        models.Conversation.user_id == current_user.id
    ).first()
    
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation non trouvée")
    
    db.delete(conversation)
    db.commit()
    
    return {"message": "Conversation supprimée"}


# --- Endpoints pour la User Memory ---

@router.get("/memory", response_model=list[schemas.UserMemoryResponse])
@track(name="api_get_memories")
def get_memories(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Récupère toutes les mémoires de l'utilisateur.
    """
    memories = db.query(models.UserMemory).filter(
        models.UserMemory.user_id == current_user.id
    ).all()
    return memories


@router.post("/memory", response_model=schemas.UserMemoryResponse)
@track(name="api_save_memory")
def save_memory(
    payload: schemas.UserMemoryCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Sauvegarde ou met à jour une mémoire utilisateur.
    """
    # Chercher si la clé existe déjà
    existing = db.query(models.UserMemory).filter(
        models.UserMemory.user_id == current_user.id,
        models.UserMemory.memory_key == payload.memory_key
    ).first()
    
    if existing:
        existing.memory_value = payload.memory_value
        db.commit()
        db.refresh(existing)
        return existing
    else:
        memory = models.UserMemory(
            user_id=current_user.id,
            memory_key=payload.memory_key,
            memory_value=payload.memory_value
        )
        db.add(memory)
        db.commit()
        db.refresh(memory)
        return memory


@router.delete("/memory/{memory_key}")
@track(name="api_delete_memory")
def delete_memory(
    memory_key: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Supprime une mémoire utilisateur.
    """
    memory = db.query(models.UserMemory).filter(
        models.UserMemory.user_id == current_user.id,
        models.UserMemory.memory_key == memory_key
    ).first()
    
    if not memory:
        raise HTTPException(status_code=404, detail="Mémoire non trouvée")
    
    db.delete(memory)
    db.commit()
    
    return {"message": "Mémoire supprimée"}


# --- Endpoint centralisé pour le chat avec persistance ---

@router.post("/chat/message", response_model=schemas.EnhancedAIAnalysisResponse)
@track(name="api_chat_with_memory")
async def send_chat_message(
    chat_request: schemas.ChatWithHistoryRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Endpoint centralisé qui:
    1. Crée/récupère une conversation
    2. Sauvegarde le message utilisateur
    3. Charge l'historique depuis la DB
    4. Appelle le coach IA avec tout le contexte
    5. Sauvegarde la réponse
    6. Retourne tout avec les metadata
    """
    # 1. Gérer la conversation
    if chat_request.conversation_id:
        conversation = db.query(models.Conversation).filter(
            models.Conversation.id == chat_request.conversation_id,
            models.Conversation.user_id == current_user.id
        ).first()
        if not conversation:
            raise HTTPException(status_code=404, detail="Conversation non trouvée")
    else:
        # Créer nouvelle conversation
        conversation = models.Conversation(
            user_id=current_user.id,
            title=f"Chat du {datetime.utcnow().strftime('%d/%m/%Y')}"
        )
        db.add(conversation)
        db.commit()
        db.refresh(conversation)
    
    # 2. Sauvegarder le message utilisateur
    user_message = models.Message(
        conversation_id=conversation.id,
        role="user",
        content=chat_request.user_message
    )
    db.add(user_message)
    db.commit()
    db.refresh(user_message)
    
    # 3. Charger l'historique depuis la DB (si demandé)
    history = []
    if chat_request.load_history_from_db:
        db_messages = db.query(models.Message).filter(
            models.Message.conversation_id == conversation.id
        ).order_by(models.Message.timestamp.asc()).all()
        
        # Limiter à 10 derniers messages pour le contexte
        for msg in db_messages[-10:]:
            history.append(schemas.ChatMessage(role=msg.role, content=msg.content))
    
    # 4. Enrichir le contexte avec les données temps réel
    snapshot = chat_request.snapshot
    
    # Calcul des stats glycémie temps réel (7 derniers jours)
    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    glucose_entries = db.query(models.GlucoseEntry).filter(
        models.GlucoseEntry.user_id == current_user.id,
        models.GlucoseEntry.timestamp >= seven_days_ago
    ).all()
    
    # Calcul TIR 7 jours
    if glucose_entries:
        total = len(glucose_entries)
        low = sum(1 for e in glucose_entries if e.value < 70)
        normal = sum(1 for e in glucose_entries if 70 <= e.value <= 180)
        high = sum(1 for e in glucose_entries if e.value > 180)
        
        # Ajouter au contexte
        glucose_context = f"\n\n📊 STATS GLYCÉMIE (7 derniers jours):\n"
        glucose_context += f"- TIR: {round((normal/total)*100, 1)}% (Cible: >70%)\n"
        glucose_context += f"- Temps bas (<70): {round((low/total)*100, 1)}%\n"
        glucose_context += f"- Temps haut (>180): {round((high/total)*100, 1)}%\n"
        glucose_context += f"- Moyenne: {round(sum(e.value for e in glucose_entries)/total, 0)} mg/dL\n"
    else:
        glucose_context = "\n\n📊 STATS: Pas de données glycémie récentes."
    
    # 5. Charger la User Memory
    user_memories = db.query(models.UserMemory).filter(
        models.UserMemory.user_id == current_user.id
    ).all()
    
    memory_context = "\n\n🧠 MÉMOIRE UTILISATEUR:\n"
    if user_memories:
        for mem in user_memories:
            memory_context += f"- {mem.memory_key}: {mem.memory_value}\n"
    else:
        memory_context += "Aucune préférence enregistrée.\n"
    
    # Contexte complet
    full_context = glucose_context + memory_context
    
    # 6. Appeler le coach IA
    snapshot = chat_request.snapshot
    ninety_days_ago = datetime.utcnow() - timedelta(days=90)
    avg_result = db.query(func.avg(models.GlucoseEntry.value)).filter(
        models.GlucoseEntry.user_id == current_user.id,
        models.GlucoseEntry.timestamp >= ninety_days_ago
    ).scalar()
    rolling_avg = float(avg_result) if avg_result else float(snapshot.lab_data.fasting_glucose)
    
    # Analyse de stabilité
    user_results = analyze_stability(snapshot.lab_data, snapshot.lifestyle, rolling_avg)
    
    # Enrichir avec stats et meals
    today = datetime.utcnow().date()
    db_stats = db.query(models.DailyStats).filter(
        models.DailyStats.user_id == current_user.id,
        func.date(models.DailyStats.date) == today
    ).first()
    if db_stats:
        snapshot.recent_activity.append(schemas.DailyStats.model_validate(db_stats))
    
    db_meals = db.query(models.Meal).filter(
        models.Meal.user_id == current_user.id
    ).order_by(models.Meal.timestamp.desc()).limit(3).all()
    if db_meals:
        snapshot.recent_meals = [schemas.Meal.model_validate(m) for m in db_meals]
    
    # Injecter goals
    if current_user.questionnaire:
        snapshot.target_hba1c = current_user.questionnaire.target_hba1c
        snapshot.target_hba1c_date = current_user.questionnaire.target_hba1c_date
    
    health_ctx_str = ai_service.format_health_context(snapshot) + full_context
    
    # Decoder image
    image_bytes = None
    if chat_request.image_base64:
        try:
            b64_str = chat_request.image_base64
            if "," in b64_str:
                b64_str = b64_str.split(",")[1]
            image_bytes = base64.b64decode(b64_str)
        except Exception as e:
            print(f"⚠️ Erreur décodage image: {e}")
    
    # Appel IA
    try:
        ai_response = await ai_service.generate_coach_advice(
            user_results,
            history=history,
            user_message=chat_request.user_message,
            health_context=health_ctx_str,
            image_bytes=image_bytes
        )
    except ValueError as e:
        if "Safety Violation" in str(e):
            return schemas.EnhancedAIAnalysisResponse(
                advice="Je ne peux pas te donner de conseil sur ce sujet pour des raisons de sécurité.",
                actions=[],
                debug_results=user_results,
                conversation_id=conversation.id,
                message_id=user_message.id
            )
        raise e
    
    # 7. Sauvegarder la réponse du coach
    assistant_message = models.Message(
        conversation_id=conversation.id,
        role="model",
        content=ai_response.get("advice", ""),
        extra_data={"actions": ai_response.get("actions", [])}
    )
    db.add(assistant_message)
    
    # Mettre à jour la conversation
    conversation.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(assistant_message)
    
    # 8. Retourner la réponse enrichie
    return schemas.EnhancedAIAnalysisResponse(
        advice=ai_response.get("advice", ""),
        actions=ai_response.get("actions", []),
        debug_results=user_results,
        conversation_id=conversation.id,
        message_id=assistant_message.id
    )


