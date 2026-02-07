# TICKETS - DIASIDE Project

Plan d'action pour la mise en production (Lundi Matin).

## ✅ Completed (Done)

- [x] **CLEAN-01** : Nettoyage du Codebase
  - Suppression des fichiers temporaires, logs, images générées.
  - Déplacement des scripts de test `test_ticket_*.py` vers `tests/archive/`.
  - Suppression des scripts de debug inutiles (`debug_imports.py`).

- [x] **AI-FIX-01** : Intégration des Objectifs Utilisateur (HbA1c 2026)
  - Ajout des champs `target_hba1c` et `target_hba1c_date` au schéma `UserHealthSnapshot`.
  - Mise à jour de l'endpoint `/api/ai/coach` pour injecter ces valeurs depuis la base de données.
  - Mise à jour du `AIService` pour inclure l'objectif dans le prompt contextuel de Gemini.
  - *Impact* : Le coach peut désormais dire "Pour atteindre ton objectif de 6.5% d'ici décembre...".

## 🚀 To Do (High Priority - For Monday)

### Backend & Data
- [ ] **DATA-01** : Validation EasyView (Medtrum)
  - Tester la connexion réelle avec des identifiants valides via l'endpoint `/api/medtrum/connect`.
  - Vérifier que le scraping (MedtrumService) est résilient aux changements mineurs du site Medtrum.
  - *Note* : Le code est en place, reste à valider avec un vrai compte.

- [ ] **DATA-02** : Calcul HbA1c vs Objectif
  - Vérifier l'affichage dans l'application mobile (Graphique HbA1c).
  - S'assurer que la comparaison "Actuel vs Objectif" est claire pour l'utilisateur.

### Mobile App (Flutter)
- [ ] **MOB-01** : Test sur Simulateur Android
  - Vérifier le build complet (`flutter build apk`).
  - Tester le parcours critique : Login -> Dashboard -> Coach -> Connexion EasyView.
  - S'assurer que les écrans ne crash pas si les données sont vides.

- [ ] **MOB-02** : UX Review Coach
  - Vérifier que les conseils du coach s'affichent correctement (Markdown rendering).
  - Tester l'envoi d'images de repas au coach.

### Documentation & Quality
- [ ] **DOC-01** : README & Setup Guide
  - Mettre à jour le README avec les instructions pour lancer le backend et le mobile.
  - Documenter les variables d'environnement requises (`.env`).

## 🔮 Backlog (Post-Monday)

- [ ] **FEAT-01** : Notifications Push (Rappel prise de mesure).
- [ ] **FEAT-02** : Mode Hors-Ligne (Mise en cache des conseils coach).
- [ ] **TECH-01** : Migration complète des tests unitaires vers `pytest` dans `tests/`.
