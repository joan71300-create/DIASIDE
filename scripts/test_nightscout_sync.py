import asyncio
import httpx
import sys
import os

# Add root to path
sys.path.append(os.getcwd())

from app.models.database import SessionLocal
from app.models import models
from app.services.nightscout_service import nightscout_service

async def manual_sync():
    db = SessionLocal()
    try:
        user = db.query(models.User).filter(models.User.email == "patient@diaside.com").first()
        if not user:
            print("User not found")
            return

        url = "https://web-production-bd395.up.railway.app/"
        token = "3893UDJDJ29ZJFJSI2DJS"
        
        print(f"Starting sync from Nightscout: {url}")
        result = await nightscout_service.sync_user_data(db, user, url, token)
        print(f"Sync Result: {result}")
        
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(manual_sync())
