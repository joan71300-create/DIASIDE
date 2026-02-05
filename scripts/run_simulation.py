import sys
import os
from datetime import datetime, timedelta
import random

# Add project root to path
sys.path.append(os.getcwd())

from app.models.database import SessionLocal
from app.models import models

def seed_simulation():
    db = SessionLocal()
    user = db.query(models.User).first()
    if not user:
        print("Aucun utilisateur trouve. Creez un compte d'abord.")
        return

    print(f"Generation de donnees pour {user.email}...")
    
    # Target ~7.2% HbA1c => Avg Glucose 160
    target_avg = 160
    days = 90
    start_date = datetime.utcnow() - timedelta(days=days)
    entries = []

    for day in range(days):
        day_date = start_date + timedelta(days=day)
        for hour in [8, 13, 19, 23]:
            val = target_avg + random.randint(-30, 30)
            if hour == 13: val += 40 # Lunch spike
            
            entry = models.GlucoseEntry(
                user_id=user.id,
                value=float(val),
                timestamp=day_date.replace(hour=hour, minute=0),
                note="Simulation Script"
            )
            entries.append(entry)
    
    db.add_all(entries)
    db.commit()
    print(f"✅ {len(entries)} mesures ajoutées !")

if __name__ == "__main__":
    seed_simulation()
