import sys
import os
sys.path.append(os.getcwd())

from app.models.database import SessionLocal, engine, Base
from app.models import models
from app.core import security
from datetime import datetime, timedelta
import random
import math

# Configuration
DAYS_HISTORY = 90
POINTS_PER_DAY = 288 # Every 5 mins
USER_EMAIL = "patient@diaside.com"
USER_PASSWORD = "password123"

def generate_glucose_data(start_date, num_days):
    data = []
    current_time = start_date
    
    print(f"Generating {num_days} days of data (~{num_days * POINTS_PER_DAY} points)...")
    
    for day in range(num_days):
        # Daily variations
        base_glucose = 120 + random.uniform(-10, 10)
        
        for i in range(POINTS_PER_DAY):
            # Time of day effect (Sine wave)
            # Peak at noon (i=144), trough at midnight
            hour_factor = math.sin((i / POINTS_PER_DAY) * 2 * math.pi - math.pi/2) * 20
            
            # Random noise
            noise = random.uniform(-5, 5)
            
            # Meal spikes (3 times a day roughly)
            meal_spike = 0
            hour = (i * 5) / 60
            if 7 <= hour <= 9 or 12 <= hour <= 14 or 19 <= hour <= 21:
                if random.random() < 0.3: # Chance of spike during meal window
                    meal_spike = random.uniform(30, 80)
            
            value = base_glucose + hour_factor + noise + meal_spike
            
            # Clamp
            value = max(40, min(400, value))
            
            data.append({
                "value": value,
                "timestamp": current_time,
                "note": "Simulated (Nightscout Mock)"
            })
            
            current_time += timedelta(minutes=5)
            
    return data

def seed():
    # Create Tables
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        # 1. Create User
        user = db.query(models.User).filter(models.User.email == USER_EMAIL).first()
        if not user:
            print(f"Creating user {USER_EMAIL}...")
            hashed = security.get_password_hash(USER_PASSWORD)
            user = models.User(email=USER_EMAIL, hashed_password=hashed, is_active=True)
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            print(f"User {USER_EMAIL} exists.")
            
        # 2. Check existing data
        count = db.query(models.GlucoseEntry).filter(models.GlucoseEntry.user_id == user.id).count()
        if count > 1000:
            print(f"Data already exists ({count} entries). Skipping generation.")
            return

        # 3. Generate Data
        start_date = datetime.utcnow() - timedelta(days=DAYS_HISTORY)
        points = generate_glucose_data(start_date, DAYS_HISTORY)
        
        # 4. Bulk Insert
        print("Inserting data into DB...")
        # SQLAlchemy core bulk insert is faster
        db.bulk_insert_mappings(
            models.GlucoseEntry,
            [
                {"user_id": user.id, "value": p["value"], "timestamp": p["timestamp"], "note": p["note"]}
                for p in points
            ]
        )
        db.commit()
        print("Seeding Complete!") # Removed emoji
        
    except Exception as e:
        print(f"Error seeding data: {e}") # Removed emoji
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()