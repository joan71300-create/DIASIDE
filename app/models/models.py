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

class Questionnaire(Base):
    __tablename__ = "questionnaires"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    age = Column(Integer)
    weight = Column(Float)
    height = Column(Float)
    diabetes_type = Column(String) # "Type 1", "Type 2", "Gestational"
    target_glucose_min = Column(Float)
    target_glucose_max = Column(Float)
    
    user = relationship("User", back_populates="questionnaire")

class GlucoseEntry(Base):
    __tablename__ = "glucose_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    value = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow)
    note = Column(String, nullable=True)
    
    user = relationship("User", back_populates="glucose_entries")
