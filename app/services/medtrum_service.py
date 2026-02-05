import requests
import json
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.models import models
from app.core.config import settings

class MedtrumService:
    BASE_URL = 'https://easyview.medtrum.fr' # Ou .com selon configuration utilisateur
    
    def __init__(self):
        self.session = requests.Session()
        self.headers = {
            'DevInfo': 'Android 12;Xiamoi vayu;Android 12',
            'AppTag': 'v=1.2.70(112);n=eyfo;p=android',
            'User-Agent': 'okhttp/3.5.0'
        }

    def sync_data(self, db: Session, user: models.User, medtrum_username: str, medtrum_password: str, days: int = 1):
        """
        Connecte à Medtrum, télécharge les données et les insère en base.
        """
        # 1. Login
        login_url = f'{self.BASE_URL}/mobile/ajax/login'
        data = {
            'apptype': 'Follow',
            'user_name': medtrum_username,
            'password': medtrum_password,
            'platform': 'google',
            'user_type': 'M',
        }
        
        print(f"🔌 Connexion Medtrum pour {medtrum_username}...")
        r = self.session.post(login_url, data=data, headers=self.headers)
        
        if r.status_code != 200:
            raise Exception(f"Echec connexion Medtrum: {r.status_code} {r.text}")

        # 2. Get Monitor List
        logindata_url = f'{self.BASE_URL}/mobile/ajax/logindata'
        r2 = self.session.get(logindata_url, headers=self.headers)
        json_data = r2.json()
        
        if 'monitorlist' not in json_data or len(json_data['monitorlist']) == 0:
            raise Exception("Aucun moniteur Medtrum associé à ce compte.")
            
        target_username = json_data['monitorlist'][0]['username']
        
        # 3. Download Data
        now = datetime.now()
        start_date = now - timedelta(days=days)
        
        params = {
            'flag': 'sg', # Sensor Glucose
            'st': start_date.strftime("%Y-%m-%d %H:%M:%S"),
            'et': now.strftime("%Y-%m-%d %H:%M:%S"),
            'user_name': target_username
        }
        
        print(f"📥 Téléchargement des données ({days} jours)...")
        r3 = self.session.get(f'{self.BASE_URL}/mobile/ajax/download', headers=self.headers, params=params)
        
        try:
            data_response = r3.json()
            raw_data = data_response.get("data", [])
            
            count_new = 0
            for point in raw_data:
                # Format supposé : ["ID", Timestamp, Raw_Value, Calibrated_Value, "C", Status]
                # Exemple : ["...", 1770120750.0, 11.0, 6.6, "C", 0.0]
                try:
                    # Filtre anti-bruit (Status != 0)
                    if float(point[5]) != 0.0:
                        continue

                    ts = datetime.fromtimestamp(point[1])
                    
                    # On prend l'index 3 (Valeur plus basse/cohérente)
                    val_mmol = float(point[3])
                    val_mgdl = val_mmol * 18.0182 # Conversion
                    
                    # Vérifier doublons
                    exists = db.query(models.GlucoseEntry).filter(
                        models.GlucoseEntry.user_id == user.id,
                        models.GlucoseEntry.timestamp == ts
                    ).first()
                    
                    if not exists:
                        entry = models.GlucoseEntry(
                            user_id=user.id,
                            value=val_mgdl,
                            timestamp=ts,
                            note="Medtrum Auto-Sync"
                        )
                        db.add(entry)
                        count_new += 1
                except Exception as e:
                    print(f"Skipping point {point}: {e}")
            
            db.commit()
            return {"status": "success", "new_entries": count_new}
            
        except json.JSONDecodeError:
            raise Exception("Réponse Medtrum invalide (pas de JSON)")

medtrum_service = MedtrumService()
