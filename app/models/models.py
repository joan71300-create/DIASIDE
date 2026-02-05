from sqlalchemy import Boolean, Column, Float, Integer, String, ForeignKey, DateTime
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
