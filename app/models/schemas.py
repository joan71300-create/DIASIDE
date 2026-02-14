from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List
from datetime import datetime
from enum import Enum

# --- Token ---
class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# --- User ---
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool

    class Config:
        from_attributes = True

# --- Questionnaire ---
class QuestionnaireBase(BaseModel):
    age: int
    gender: Optional[str] = None
    weight: float
    height: float
    activity_level: Optional[str] = "moderate"
    daily_step_goal: Optional[int] = 10000
    dietary_preferences: Optional[str] = None
    diabetes_type: str
    physical_limitations: Optional[str] = None # e.g. "boiteux", "douleur genou"
    name: Optional[str] = None # First name or nickname
    target_glucose_min: float
    target_glucose_max: float
    # HbA1c Goals
    target_hba1c: Optional[float] = 7.0
    target_hba1c_date: Optional[datetime] = None
    last_lab_hba1c: Optional[float] = None # La valeur réelle de la prise de sang
    hba1c_offset: Optional[float] = 0.0

class QuestionnaireCreate(QuestionnaireBase):
    pass

class Questionnaire(QuestionnaireBase):
    id: int
    user_id: int
    
    class Config:
        from_attributes = True

# --- Activity & Meals ---
class DailyStatsBase(BaseModel):
    date: datetime
    steps: int
    calories_burned: float
    distance_km: float

class DailyStatsCreate(DailyStatsBase):
    pass

class DailyStats(DailyStatsBase):
    id: int
    user_id: int
    class Config:
        from_attributes = True

class MealBase(BaseModel):
    timestamp: datetime
    name: str
    calories: Optional[float] = None
    carbs: Optional[float] = None
    protein: Optional[float] = None
    fat: Optional[float] = None
    image_url: Optional[str] = None

class MealCreate(MealBase):
    pass

class Meal(MealBase):
    id: int
    user_id: int
    class Config:
        from_attributes = True

# --- Glucose ---
class GlucoseDataBase(BaseModel):
    value: float = Field(..., gt=0, description="Glucose level in mg/dL")
    note: Optional[str] = None

class GlucoseDataCreate(GlucoseDataBase):
    questionnaire: dict = Field(default_factory=dict, description="User questionnaire data for adjustment")

class GlucoseEntry(GlucoseDataBase):
    id: int
    user_id: int
    timestamp: datetime
    
    class Config:
        from_attributes = True

class CGMPing(BaseModel):
    value: float = Field(..., gt=0, description="Glucose value in mg/dL")
    timestamp: Optional[datetime] = Field(default_factory=datetime.utcnow)
    device_id: Optional[str] = "unknown"
    trend: Optional[str] = None # e.g. "stable", "rising", "falling"
    questionnaire: Optional[QuestionnaireBase] = Field(None, description="Contextual questionnaire data")

# --- Analysis ---
class CoachAction(BaseModel):
    label: str
    type: str # "sport", "diet", "check", "medical"

class AIAnalysisResponse(BaseModel):
    advice: str
    actions: List[CoachAction] = []
    debug_results: dict

# --- Health Profile (Ticket 03) ---
class ActivityLevel(str, Enum):
    sedentary = "sedentary"
    moderate = "moderate"
    active = "active"

class LabData(BaseModel):
    hba1c: float = Field(..., ge=4.0, le=15.0, description="HbA1c level in % (4-15)")
    fasting_glucose: int = Field(..., ge=50, le=400, description="Fasting glucose in mg/dL (50-400)")
    ferritin: Optional[float] = Field(None, description="Ferritin level in ng/mL")
    blood_event: bool = Field(False, description="Recent blood loss or donation")

class LifestyleProfile(BaseModel):
    activity_level: ActivityLevel
    diet_type: str = Field(..., min_length=2, description="Type of diet (e.g. Keto, Vegan, Balanced)")
    is_smoker: bool
    is_athlete: bool = Field(False, description="Professional or high-intensity athlete status")
    physical_limitations: Optional[str] = Field(None, description="Physical limitations or injuries")
    gender: Optional[str] = "Male" # Added default for backward comp
    daily_step_goal: int = 10000

class UserHealthSnapshot(BaseModel):
    name: Optional[str] = Field(None, description="User's name")
    age: int = Field(..., ge=0, le=120, description="Age in years")
    weight: float = Field(..., gt=0, description="Weight in kg")
    height: float = Field(..., gt=0, description="Height in cm")
    diabetes_type: str = Field(..., pattern="^(Type 1|Type 2|Gestational)$", description="Type of diabetes")
    lab_data: LabData
    lifestyle: LifestyleProfile
    recent_activity: List[DailyStats] = []
    recent_meals: List[Meal] = []
    
    # Goals (Added for Coach Context)
    target_hba1c: Optional[float] = Field(None, description="User's target HbA1c goal")
    target_hba1c_date: Optional[datetime] = Field(None, description="Date by which the user wants to achieve the target")

    model_config = ConfigDict(from_attributes=True)

class HealthSnapshotResponse(BaseModel):
    message: str
    temp_id: str
    data: UserHealthSnapshot

# --- Chat / Context Awareness (AI-001) ---
class ChatMessage(BaseModel):
    role: str # "user" or "model"
    content: str

class ChatRequest(BaseModel):
    snapshot: UserHealthSnapshot
    history: List[ChatMessage] = []
    user_message: Optional[str] = None
    image_base64: Optional[str] = Field(None, description="Base64 encoded image for analysis")

class NightscoutSyncRequest(BaseModel):
    url: str = Field(..., description="URL of the Nightscout instance (e.g. https://my-ns.herokuapp.com)")
    token: Optional[str] = Field(None, description="API Secret or Token for authentication")

class MedtrumConnectRequest(BaseModel):
    username: str
    password: str
    region: str = "fr" # ou "com"

# For Food Recognition Request
class FoodRecognitionRequest(BaseModel):
    image_base64: str = Field(..., description="Base64 encoded image of the food")
    current_glucose: float = Field(..., description="Current glucose level in mg/dL")
    trend: str = Field(..., description="Glucose trend (e.g., 'stable', 'rising', 'falling')")
    
# For Food Recognition Response
class FoodRecognitionResponse(BaseModel):
    carbs: float = Field(..., description="Estimated carbohydrates in grams")
    advice: str = Field(..., description="AI-generated advice based on the analysis")

# ==================== NOUVEAUX SCHEMAS POUR LA MEMOIRE DU CHATBOT ====================

class MessageCreate(BaseModel):
    """Schema pour créer un nouveau message"""
    role: str = Field(..., description="Role: 'user' ou 'model'")
    content: str = Field(..., description="Contenu du message")
    metadata: Optional[dict] = Field(None, description="Métadonnées supplémentaires")


class MessageResponse(BaseModel):
    """Schema pour répondre un message"""
    id: int
    conversation_id: int
    role: str
    content: str
    timestamp: datetime
    extra_data: Optional[dict] = None
    
    class Config:
        from_attributes = True


class ConversationCreate(BaseModel):
    """Schema pour créer une nouvelle conversation"""
    title: Optional[str] = Field(None, description="Titre de la conversation")


class ConversationResponse(BaseModel):
    """Schema pour répondre une conversation"""
    id: int
    user_id: int
    title: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    messages: List[MessageResponse] = []
    
    class Config:
        from_attributes = True


class ConversationListResponse(BaseModel):
    """Schema pour la liste des conversations"""
    id: int
    title: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    message_count: int = 0
    
    class Config:
        from_attributes = True


class UserMemoryCreate(BaseModel):
    """Schema pour créer une mémoire utilisateur"""
    memory_key: str = Field(..., description="Clé de mémoire (ex: 'food_preferences', 'allergies')")
    memory_value: str = Field(..., description="Valeur de la mémoire (JSON stringifié)")


class UserMemoryResponse(BaseModel):
    """Schema pour répondre une mémoire utilisateur"""
    id: int
    user_id: int
    memory_key: str
    memory_value: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ChatWithHistoryRequest(BaseModel):
    """Schema pour envoyer un message avec gestion de l'historique côté serveur"""
    conversation_id: Optional[int] = Field(None, description="ID de conversation existante (None pour nouvelle)")
    snapshot: UserHealthSnapshot
    user_message: str = Field(..., description="Message de l'utilisateur")
    image_base64: Optional[str] = Field(None, description="Image en base64")
    # Option pour charger l'historique récent depuis la DB
    load_history_from_db: bool = Field(True, description="Charger l'historique depuis la DB")


class EnhancedAIAnalysisResponse(BaseModel):
    """Réponse enrichie du coach avec metadata"""
    advice: str
    actions: List[CoachAction] = []
    debug_results: dict
    conversation_id: int = Field(..., description="ID de la conversation")
    message_id: int = Field(..., description="ID du message de l'assistant")
    summary: Optional[str] = Field(None, description="Résumé automatique de la conversation")
