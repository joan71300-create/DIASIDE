import sys
import os
sys.path.append(os.getcwd())

from app.models.database import SessionLocal
from app.models import models
from sqlalchemy import func
from datetime import datetime, timedelta

def verify():
    db = SessionLocal()
    try:
        user = db.query(models.User).filter(models.User.email == "patient@diaside.com").first()
        if not user:
            print("User not found.")
            return

        print(f"User ID: {user.id}")
        
        # Count entries
        count = db.query(models.GlucoseEntry).filter(models.GlucoseEntry.user_id == user.id).count()
        print(f"Total Readings: {count}")
        
        # 90 Day Avg
        ninety_days_ago = datetime.utcnow() - timedelta(days=90)
        avg = db.query(func.avg(models.GlucoseEntry.value)).filter(
            models.GlucoseEntry.user_id == user.id,
            models.GlucoseEntry.timestamp >= ninety_days_ago
        ).scalar()
        
        print(f"90-Day Rolling Average: {avg:.2f} mg/dL")
        
        # Estimated HbA1c
        est_hba1c = (avg + 46.7) / 28.7
        print(f"Estimated HbA1c (Miedema): {est_hba1c:.2f}%")
        
    finally:
        db.close()

if __name__ == "__main__":
    verify()
