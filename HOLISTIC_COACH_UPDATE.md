# DIASIDE - Holistic Life Coach Update

## 🚀 Overview
We have transformed the DIASIDE Coach from a simple diabetes advisor into a **Holistic Life & Health Coach**. The system now tracks and advises on:
- **Activity:** Steps, Calories, Distance.
- **Nutrition:** Meal logging and Carb estimation.
- **Profile:** Gender, Activity Level, Personal Goals.
- **Mindset:** Motivation and sleep advice.

## 🛠 Backend Changes (Python/FastAPI)
1.  **Database Models:**
    -   Added `DailyStats` table for activity tracking.
    -   Added `Meal` table for nutrition logs.
    -   Expanded `Questionnaire` to `HealthProfile` (Gender, Goals, Preferences).
2.  **API Endpoints:**
    -   `POST /api/log/activity`: Log daily steps/stats.
    -   `POST /api/log/meal`: Log meals.
    -   `POST /api/ai/coach`: Now automatically fetches recent activity/meals from DB to enrich the AI context.
3.  **AI Service:**
    -   Updated `COACH_SYSTEM_PROMPT` to act as a supportive Life Coach.
    -   Context injection now includes "Recent Activity" and "Last Meals".

## 📱 Mobile App Changes (Flutter)
1.  **Coach Screen:**
    -   Added **Quick Action Chips** (`Activité`, `Repas`) for fast logging.
    -   Added **Dialogs** to input Steps and Meal details.
    -   Updated **Settings Sheet** to configure Profile (Gender, Activity Level).
2.  **Service Integration:**
    -   Connected to the new logging endpoints.

## ⚠️ Notes
- A database migration was applied (`5926ed0820b6`).
- If you run into `firebase_admin` errors locally, ensure `pip install firebase-admin` is run (it was added to imports recently).
