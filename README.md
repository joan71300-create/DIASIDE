# DIASIDE - AI Diabetes Assistant

DiaSide est une application de gestion du diabète assistée par l'intelligence artificielle générative (Gemini 3.0), avec une traçabilité complète des décisions (Opik).

## 🏗️ Architecture Technique

Le projet suit une architecture client-serveur classique enrichie par des services IA.

### Composants

1.  **Frontend Mobile (`diaside_mobile/`)**
    *   Framework : **Flutter**
    *   State Management : **Riverpod**
    *   HTTP Client : **Dio**
    *   Rôles : Authentification, Dashboard Glycémie, Saisie Repas, Affichage Conseils Coach.

2.  **Backend API (`app/`)**
    *   Framework : **FastAPI** (Python 3.10+)
    *   Database : **SQLite** (Dev) / PostgreSQL (Prod target) via **SQLAlchemy**.
    *   Auth : **JWT** (OAuth2PasswordBearer).

3.  **Moteur IA & Stabilité (`app/core/` & `app/services/`)**
    *   **Stability Engine** : Algorithme déterministe (Miedema) pour l'ajustement clinique des valeurs (HbA1c vs Ferritine).
    *   **Prompt Engine** : Injection dynamique de contexte pour Gemini 3.0.
    *   **Guardrails** : Filtrage Regex + LLM-as-a-Judge pour bloquer les conseils médicaux dangereux.

4.  **Observabilité (`Opik`)**
    *   Traçabilité des appels LLM (entrées/sorties, latence, coût).
    *   Scoring de la sécurité des réponses.

### 🔄 Flux de Données (Data Flow)

1.  **Ingestion CGM** : Le mobile envoie les mesures (`POST /api/cgm`).
2.  **Analyse** : L'utilisateur demande un conseil (`POST /api/ai/coach`).
3.  **Traitement** :
    *   Backend récupère l'historique et le profil.
    *   `StabilityEngine` ajuste les valeurs (ex: correction anémie).
    *   `AIService` construit le prompt et interroge Gemini.
    *   `Guardrails` vérifie la réponse avant renvoi.
4.  **Réponse** : Le mobile affiche le conseil validé.

## 🚀 Installation

### Backend
```bash
# Setup Env
python -m venv .venv
source .venv/bin/activate  # ou .venv\Scripts\activate sur Windows
pip install -r requirements.txt

# Config
cp .env.example .env
# Remplir GEMINI_API_KEY et OPIK_API_KEY

# Run
python main.py
```

### Mobile
```bash
cd diaside_mobile
flutter pub get
flutter run
```

## 📚 API Endpoints Clés

*   `POST /auth/token` : Login.
*   `POST /api/cgm` : Upload données glucose.
*   `POST /api/ai/coach` : Génération de conseil IA contextuel.
*   `POST /api/health/snapshot` : Mise à jour profil biologique.
