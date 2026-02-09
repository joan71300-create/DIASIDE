# Guide de dépannage - Émulateur Android

## 🐛 Problèmes résolus par ce guide

Ce guide vous aide à résoudre les problèmes suivants :
- ⬛ **Écran noir au démarrage de l'application**
- 🐌 **Application très lente ou qui freeze**
- 🎨 **Problèmes d'affichage graphique (Choreographer errors, Graphics HAL)**
- ⏱️ **Timeouts réseau lors de l'initialisation**

---

## ✅ Corrections appliquées dans le code

### 1. Réduction des timeouts réseau
**Fichier : `lib/features/auth/services/auth_service.dart`**
- `connectTimeout`: 60s → **10s**
- `receiveTimeout`: 300s → **30s**

Cela évite d'attendre trop longtemps si le backend n'est pas accessible.

### 2. Splash Screen avec indicateur de chargement
**Fichier : `lib/shared/screens/splash_screen.dart`** (nouveau)

L'application affiche maintenant un écran de chargement avec un `CircularProgressIndicator` au lieu d'un écran noir.

### 3. Meilleure gestion des erreurs
**Fichier : `lib/main.dart`**
- Timeout de session restauration : 8 secondes max
- Logs détaillés pour déboguer
- L'app continue même si la connexion backend échoue

### 4. Configuration réseau
**Fichier : `.env`**
- `BASE_URL=http://10.0.2.2:8000` activé par défaut pour émulateur Android

---

## 🔧 Configuration de l'émulateur Android

### Problème : Graphics HAL / Choreographer Errors

Si vous voyez des erreurs comme :
```
Frame time is ... ms in the future! Check that graphics HAL is generating vsync timestamps...
```

**Solution : Changer le mode graphique de l'émulateur**

#### Étapes à suivre :

1. **Ouvrir Android Studio**

2. **Accéder à l'AVD Manager**
   - Menu : `Tools` → `Device Manager`
   - Ou cliquez sur l'icône 📱 dans la barre d'outils

3. **Éditer votre émulateur**
   - Trouvez votre émulateur dans la liste
   - Cliquez sur l'icône ✏️ (Edit) à côté

4. **Modifier les paramètres graphiques**
   - Cliquez sur `Show Advanced Settings` en bas
   - Scrollez jusqu'à la section **"Emulated Performance"**
   - Trouvez le paramètre **"Graphics"**
   - Changez de `Automatic` à **`Software - GLES 2.0`**
   
   > **Note :** Si `Software` ne résout pas le problème, essayez `Hardware - GLES 2.0`

5. **Ajuster la mémoire (optionnel mais recommandé)**
   - **RAM:** Au moins `2048 MB` (2 GB)
   - **VM Heap:** Au moins `256 MB`
   - **Internal Storage:** Au moins `2048 MB`

6. **Sauvegarder et redémarrer**
   - Cliquez sur `Finish`
   - Fermez complètement l'émulateur s'il est ouvert
   - Relancez-le

---

## 🌐 Vérification de la connexion backend

### Avant de lancer l'application mobile :

1. **Vérifiez que le backend Python est lancé**
   ```bash
   # Depuis le dossier racine DIASIDE
   python main.py
   ```
   
   Le backend devrait afficher :
   ```
   INFO:     Uvicorn running on http://127.0.0.1:8000
   ```

2. **Testez la connexion depuis l'émulateur**
   ```bash
   # Depuis un terminal (avec l'émulateur lancé)
   adb shell curl http://10.0.2.2:8000/docs
   ```
   
   Si ça fonctionne, vous devriez voir du HTML.

### URLs importantes :
- **Backend depuis PC :** `http://127.0.0.1:8000`
- **Backend depuis émulateur Android :** `http://10.0.2.2:8000`
- **Backend depuis iOS Simulator :** `http://127.0.0.1:8000`
- **Backend depuis appareil physique :** `http://[VOTRE_IP_LOCAL]:8000`

---

## 📊 Logs de débogage

### Voir les logs Flutter en temps réel :

```bash
cd diaside_mobile
flutter run
```

### Logs utiles à surveiller :

✅ **Logs de succès :**
```
✅ Firebase initialized successfully
✅ .env file loaded successfully
✅ Session restored successfully
```

⚠️ **Logs d'avertissement (normaux si backend non lancé) :**
```
⚠️ Error loading .env file (using defaults)
ℹ️ No existing session found - user needs to login
⏱️ Session restore timed out - continuing without session
```

❌ **Logs d'erreur (à investiguer) :**
```
Backend Sync Error: DioException [connection timeout]
```
→ Vérifiez que le backend est lancé et accessible

---

## 🚀 Workflow de démarrage recommandé

1. **Lancer le backend Python**
   ```bash
   cd DIASIDE
   python main.py
   ```

2. **Lancer l'émulateur Android**
   - Android Studio → Device Manager → ▶️ Play

3. **Lancer l'application Flutter**
   ```bash
   cd diaside_mobile
   flutter run
   ```

4. **Observer les logs**
   - Vous devriez voir le SplashScreen pendant ~5-8 secondes
   - Puis l'écran de login apparaît
   - Les logs indiquent si la connexion backend fonctionne

---

## 🔍 Problèmes courants et solutions

### Problème : Écran noir > 10 secondes
**Cause :** Backend inaccessible + mauvaise config graphique émulateur
**Solution :**
1. Vérifier que le backend est lancé
2. Changer Graphics de l'émulateur en `Software - GLES 2.0`
3. Vérifier BASE_URL dans `.env`

### Problème : "Skipped X frames"
**Cause :** Émulateur pas assez de ressources
**Solution :**
1. Augmenter la RAM de l'émulateur (2048 MB minimum)
2. Fermer les applications lourdes sur votre PC
3. Utiliser un appareil physique si possible

### Problème : "Backend Sync Error: connection timeout"
**Cause :** Backend non lancé ou inaccessible
**Solution :**
1. Lancer le backend : `python main.py`
2. Vérifier l'URL dans `.env` : `BASE_URL=http://10.0.2.2:8000`
3. Tester la connexion : `adb shell curl http://10.0.2.2:8000/docs`

### Problème : "Bluetooth Hardware Error 0x42"
**Cause :** Bug interne de l'émulateur (sans impact)
**Solution :** Ignorez ce message, il n'affecte pas l'application

---

## 📞 Besoin d'aide ?

Si le problème persiste après avoir suivi ce guide :

1. **Vérifiez les logs complets**
   ```bash
   flutter run --verbose
   ```

2. **Capturez les logs Android**
   ```bash
   adb logcat | grep -i "flutter\|diaside"
   ```

3. **Testez sur un appareil physique** pour vérifier si c'est spécifique à l'émulateur

4. **Vérifiez la version de Flutter**
   ```bash
   flutter doctor -v
   ```

---

## 📝 Résumé des changements

| Fichier | Modification | Objectif |
|---------|-------------|----------|
| `auth_service.dart` | Timeouts réduits (10s/30s) | Éviter l'attente infinie |
| `main.dart` | Ajout SplashScreen + gestion erreur | Afficher un loader pendant init |
| `splash_screen.dart` | Nouveau fichier | Écran de chargement visuel |
| `.env` | BASE_URL activée | Configuration réseau émulateur |

---

**Date de création :** 2026-02-08  
**Version de l'app :** DIASIDE Mobile v1.0  
**Testé sur :** Android Emulator API 33/34
