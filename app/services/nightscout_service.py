import httpx
import hashlib
from datetime import datetime
from opik import track
from app.models import models
from sqlalchemy.orm import Session
from app.core.config import settings

class NightscoutService:
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=30.0)

    @track(name="nightscout_fetch")
    async def fetch_entries(self, url: str, limit: int = 288, token: str = None) -> list[dict]:
        """
        Fetches the latest glucose entries from Nightscout API v1.
        """
        api_url = f"{url.rstrip('/')}/api/v1/entries.json"
        params = {"count": limit}
        headers = {}
        
        if token:
            # Nightscout requires SHA1 hash of the API SECRET for the api-secret header
            sha1_token = hashlib.sha1(token.encode()).hexdigest()
            headers["api-secret"] = sha1_token

        try:
            response = await self.client.get(api_url, params=params, headers=headers)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"Nightscout Fetch Error: {e}")
            raise e

    @track(name="nightscout_sync_db")
    async def sync_user_data(self, db: Session, user: models.User, url: str, token: str = None):
        """
        Fetches data from Nightscout and saves new entries to the database.
        """
        entries = await self.fetch_entries(url, token=token)
        count = 0
        
        for entry in entries:
            # Nightscout fields: sgv (value), dateString (timestamp), device
            try:
                sgv = entry.get("sgv")
                if not sgv:
                    continue

                timestamp_str = entry.get("dateString")
                timestamp = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
                
                # Check if exists (deduplication)
                exists = db.query(models.GlucoseEntry).filter(
                    models.GlucoseEntry.user_id == user.id,
                    models.GlucoseEntry.timestamp == timestamp
                ).first()
                
                if not exists:
                    new_entry = models.GlucoseEntry(
                        user_id=user.id,
                        value=sgv,
                        timestamp=timestamp,
                        note=f"Nightscout ({entry.get('device', 'Unknown')})"
                    )
                    db.add(new_entry)
                    count += 1
            except Exception as e:
                print(f"⚠️ Error parsing entry: {e}")
                continue
        
        db.commit()
        return {"synced": count, "total_fetched": len(entries)}

nightscout_service = NightscoutService()
