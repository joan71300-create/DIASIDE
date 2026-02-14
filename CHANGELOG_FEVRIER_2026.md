 u# CHANGELOG - DIASIDE
## 14 Février 2026

---

## 🏥 Profil Santé Complet

### Nouveau modèle `HealthProfile`
- Création du modèle complet avec toutes les informations de santé diabète
- Propriétés : type de diabète, traitements, complications, blessures, symptômes, objectifs

### Écran Profil enrichi (`profile_screen.dart`)
- Affichage du diagnostic (type, ancienneté, objectif HbA1c)
- Section CORPS (poids, taille, IMC, niveau d'activité)
- Section TRAITEMENTS avec chips
- Section COMPLICATIONS avec chips
- Section ÉTAT ACTUEL (blessures + symptômes)
- **Ajout du bouton LOGOUT**

### Écran Édition Profil (`edit_profile_screen.dart`)
- Formulaire complet avec :
  - Informations de base (nom, genre, activité)
  - Corps (poids, taille)
  - Diabète (type, insuline, objectif HbA1c)
  - **Traitements** (cases à cocher : Insuline, Metformine, GLP-1, etc.)
  - **Complications** (cases à cocher : Neuropathie, Rétinopathie, etc.)
  - **Blessures/Douleurs** (cases à cocher : Pied gauche, Dorsalgie, etc.)
  - **Symptômes** (cases à cocher : Fatigue, Hypo nocturnes, etc.)
  - Notes

### Provider (`health_profile_provider.dart`)
- Gestion du profil santé avec Riverpod
- Synchronisation automatique avec le backend

---

## 🤖 Coach IA Intégré

### Intégration HealthProfile dans Coach
- Le Coach utilise maintenant automatiquement :
  - Le profil santé (âge, poids, taille, IMC)
  - Le type de diabète
  - Le niveau d'activité
  - Les données glycémiques en temps réel
  - L'objectif HbA1c

### Améliorations Coach Screen
- Le Coach connaît votre profil complet
- Il peut donner des conseils personnalisés selon vos complications et traitements

---

## ⚙️ Corrections Techniques

### Timeouts augmentés
- `glucose_provider.dart` : 10s → 30s
- `coach_service.dart` : 15s → 30s
- `auth_service.dart` : 10s → 30s

### Configuration API
- `api_constants.dart` : Configuration centralisée pour la production (Render)
- Suppression des URLs hardcodées

---

## 🧹 Nettoyage

### Fichiers supprimés
- `Nouveau Fichier source Python.py` (temporaire)
- `Capture d'écran 2026-01-28 212154.png` (temporaire)
- `Capture d'écran 2026-01-28 212223.png` (temporaire)
- `Gemini_Generated_Image_h9xcgph9xcgph9xc.png` (temporaire)

### Dossiers supprimés
- `docs_backup/` (duplicata)
- `temp_backup/` (inutilisé)

### Code supprimé
- `profile_service.dart` (doublon avec `health_profile_provider.dart`)

---

## 📱 APK

- Compilation réussie : `diaside_mobile/build/app/outputs/flutter-apk/app-debug.apk`
