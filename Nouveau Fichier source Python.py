import requests
from datetime import datetime, timedelta
import json

# Configuration
username = 'pluriface@gmail.com'
password = 'Lepape78!'
header = {
    'DevInfo': 'Android 12;Xiamoi vayu;Android 12',
    'AppTag': 'v=1.2.70(112);n=eyfo;p=android',
    'User-Agent': 'okhttp/3.5.0'
}

# URLs pour la France (.fr)
base_url = 'https://easyview.medtrum.fr'
login_url = f'{base_url}/mobile/ajax/login'
logindata_url = f'{base_url}/mobile/ajax/logindata'
download_url = f'{base_url}/mobile/ajax/download'

data = {
    'apptype': 'Follow',
    'user_name': username, 
    'password': password,
    'platform': 'google',
    'user_type': 'M',
}

# Utilisation d'une session pour gérer les cookies automatiquement
s = requests.Session()

print(f"Tentative de connexion vers {login_url}...")
r = s.post(login_url, data=data, headers=header)
print(f"Statut connexion: {r.status_code}")
print(f"Réponse connexion: {r.text}")

if r.status_code == 200:
    # Récupération des données de login
    r2 = s.get(logindata_url, headers=header)
    print(f"Réponse logindata: {r2.text}")
    
    try:
        json_data = r2.json()
        if 'monitorlist' in json_data and len(json_data['monitorlist']) > 0:
            target_username = json_data['monitorlist'][0]['username']
            
            # Dates dynamiques (hier à aujourd'hui)
            now = datetime.now()
            yesterday = now - timedelta(days=1)
            
            et = now.strftime("%Y-%m-%d %H:%M:%S")
            st = yesterday.strftime("%Y-%m-%d %H:%M:%S")
            
            params = {
                'flag': 'sg',
                'st': st,
                'et': et,
                'user_name': target_username
            }
            
            print(f"Téléchargement des données pour {target_username}...")
            r3 = s.get(download_url, headers=header, params=params)
            
            # Sauvegarde dans un fichier
            filename = f"medtrum_data_{now.strftime('%Y-%m-%d')}.json"
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(r3.text)
                
            print(f"Données reçues (taille): {len(r3.text)} caractères")
            print(f"Données sauvegardées dans le fichier : {filename}")
        else:
            print("Erreur: Pas de 'monitorlist' trouvé dans la réponse logindata.")
    except Exception as e:
        print(f"Erreur lors du traitement JSON: {e}")
else:
    print("Échec de la connexion.")
