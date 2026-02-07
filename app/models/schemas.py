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
    gender: Optional[str] = "Male" # Added default for backward comp
    daily_step_goal: int = 10000

class UserHealthSnapshot(BaseModel):
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