from sqlalchemy import Boolean, Column, Float, Integer, String, ForeignKey, DateTime, Text, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from app.models.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    
    questionnaire = relationship("Questionnaire", back_populates="user", uselist=False)
    glucose_entries = relationship("GlucoseEntry", back_populates="user")
    daily_stats = relationship("DailyStats", back_populates="user")
    meals = relationship("Meal", back_populates="user")
    conversations = relationship("Conversation", back_populates="user")
    user_memories = relationship("UserMemory", back_populates="user")

class Questionnaire(Base):
    __tablename__ = "questionnaires"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    age = Column(Integer)
    gender = Column(String, nullable=True) # "Male", "Female", "Other"
    weight = Column(Float)
    height = Column(Float)
    activity_level = Column(String, nullable=True) # "sedentary", "moderate", "active"
    daily_step_goal = Column(Integer, default=10000)
    dietary_preferences = Column(String, nullable=True) # JSON or comma-separated
    diabetes_type = Column(String) # "Type 1", "Type 2", "Gestational"
    physical_limitations = Column(String, nullable=True) # e.g. "boiteux", "douleur genou"
    name = Column(String, nullable=True) # First name or nickname
    target_glucose_min = Column(Float)
    target_glucose_max = Column(Float)
    
    # HbA1c Goals
    target_hba1c = Column(Float, default=7.0)
    target_hba1c_date = Column(DateTime, nullable=True)
    last_lab_hba1c = Column(Float, nullable=True)
    hba1c_offset = Column(Float, default=0.0) # Différence entre Labo et Capteur
    
    user = relationship("User", back_populates="questionnaire")

class DailyStats(Base):
    __tablename__ = "daily_stats"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    date = Column(DateTime, default=datetime.utcnow)
    steps = Column(Integer, default=0)
    calories_burned = Column(Float, default=0.0)
    distance_km = Column(Float, default=0.0)
    
    user = relationship("User", back_populates="daily_stats")

class Meal(Base):
    __tablename__ = "meals"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    timestamp = Column(DateTime, default=datetime.utcnow)
    name = Column(String)
    calories = Column(Float, nullable=True)
    carbs = Column(Float, nullable=True)
    protein = Column(Float, nullable=True)
    fat = Column(Float, nullable=True)
    image_url = Column(String, nullable=True)
    
    user = relationship("User", back_populates="meals")

class GlucoseEntry(Base):
    __tablename__ = "glucose_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    value = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow)
    note = Column(String, nullable=True)
    
    user = relationship("User", back_populates="glucose_entries")

# ==================== NOUVEAUX MODÈLES POUR LA MÉMOIRE DU CHATBOT ====================

class Conversation(Base):
    """Table de conversation pour la persistence de l'historique du chat"""
    __tablename__ = "conversations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String, nullable=True)  # Titre de la conversation (ex: "Conseil alimentaire")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    user = relationship("User", back_populates="conversations")
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan")


class Message(Base):
    """Table de messages pour l'historique du chat"""
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"))
    role = Column(String)  # "user" ou "model" (assistant)
    content = Column(Text)  # Contenu du message
    timestamp = Column(DateTime, default=datetime.utcnow)
    metadata = Column(JSON, nullable=True)  # Métadonnées supplémentaires (ex: actions suggérées)
    
    conversation = relationship("Conversation", back_populates="messages")


class UserMemory(Base):
    """Table de mémoire utilisateur pour stocker les préférences et contraintes"""
    __tablename__ = "user_memories"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    memory_key = Column(String, index=True)  # Clé de mémoire (ex: "food_preferences", "allergies", "goals")
    memory_value = Column(Text)  # Valeur (ex: JSON stringifié)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    user = relationship("User", back_populates="user_memories")
