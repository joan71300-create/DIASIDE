from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from dotenv import load_dotenv
import os

# Force le chargement des variables depuis .env en écrasant les variables système
load_dotenv(override=True)

class Settings(BaseSettings):
    PROJECT_NAME: str = "DIASIDE"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Secrets
    SECRET_KEY: str = "changeme" # Devrait être chargé depuis .env
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # AI Services
    GEMINI_API_KEY: str
    OPIK_API_KEY: str
    
    # Database
    DATABASE_URL: str = "sqlite:///./diaside.db"

    # Simulation
    ENABLE_SIMULATION_ENDPOINT: bool = False
    
    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "serviceAccountKey.json"

    model_config = ConfigDict(env_file=".env", extra="ignore")

settings = Settings()
