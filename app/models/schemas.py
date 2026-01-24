from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List
from datetime import datetime
from enum import Enum

# --- Token ---
class Token(BaseModel):
    access_token: str
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
    weight: float
    height: float
    diabetes_type: str
    target_glucose_min: float
    target_glucose_max: float

class QuestionnaireCreate(QuestionnaireBase):
    pass

class Questionnaire(QuestionnaireBase):
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

# --- Analysis ---
class AIAnalysisResponse(BaseModel):
    analysis: str
    hba1c_adjusted: float
    correction_factor: float
    stability_summary: str

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

class UserHealthSnapshot(BaseModel):
    age: int = Field(..., ge=0, le=120, description="Age in years")
    weight: float = Field(..., gt=0, description="Weight in kg")
    height: float = Field(..., gt=0, description="Height in cm")
    diabetes_type: str = Field(..., pattern="^(Type 1|Type 2|Gestational)$", description="Type of diabetes")
    lab_data: LabData
    lifestyle: LifestyleProfile

    model_config = ConfigDict(from_attributes=True)

class HealthSnapshotResponse(BaseModel):
    message: str
    temp_id: str
    data: UserHealthSnapshot
