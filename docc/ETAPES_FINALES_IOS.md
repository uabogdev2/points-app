# Étapes finales : Test du son de notification iOS

## ✅ Configuration terminée

Le fichier `clic-square.mp3` est maintenant correctement ajouté au projet Xcode.

## Prochaines étapes

### 1. Nettoyer et reconstruire l'application

Pour s'assurer que tout est bien pris en compte :

```bash
# Nettoyer les builds précédents
cd ios
rm -rf build
cd ..
flutter clean
flutter pub get
```

### 2. Rebuild de l'application iOS

```bash
# Pour un build debug
flutter build ios --debug

# OU pour un build release
flutter build ios --release
```

### 3. Tester sur un appareil iOS réel

⚠️ **Important** : Les sons de notification ne fonctionnent pas toujours dans le simulateur iOS. Testez sur un appareil physique.

1. Connectez votre iPhone/iPad
2. Lancez l'application depuis Xcode ou Flutter :
   ```bash
   flutter run
   ```

### 4. Tester les notifications

#### Test des notifications locales (Foreground)

Quand l'application est ouverte, les notifications utilisent le son personnalisé via `flutter_local_notifications`. Le son devrait être `clic-square.mp3`.

#### Test des notifications push (Background/Killed)

Pour tester les notifications push avec le son personnalisé, vous devez vous assurer que votre serveur Firebase envoie le bon payload :

**Format du payload requis :**

```json
{
  "notification": {
    "title": "Titre de la notification",
    "body": "Message de la notification",
    "sound": "clic-square.mp3"
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "clic-square.mp3",
        "badge": 1,
        "alert": {
          "title": "Titre de la notification",
          "body": "Message de la notification"
        }
      }
    }
  },
  "data": {
    "type": "test"
  }
}
```

## Vérifications

### ✅ Checklist

- [x] Fichier audio ajouté au projet Xcode
- [x] Code Dart configuré (`sound: 'clic-square.mp3'`)
- [ ] Application nettoyée et reconstruite
- [ ] Testé sur appareil iOS réel
- [ ] Son fonctionne pour les notifications locales
- [ ] Son fonctionne pour les notifications push (si applicable)

### Si le son ne fonctionne pas

1. **Vérifier que le fichier est dans le bundle** :
   - Ouvrir Xcode
   - Sélectionner le target "Runner"
   - Onglet "Build Phases"
   - Section "Copy Bundle Resources"
   - Vérifier que `clic-square.mp3` est présent ✅

2. **Vérifier les permissions** :
   - Les notifications doivent être autorisées
   - Le son doit être activé dans les permissions

3. **Vérifier les logs** :
   - Regarder les logs de l'application pour voir si le son est bien chargé
   - Vérifier les erreurs éventuelles

4. **Vérifier le nom du fichier** :
   - Le nom dans le code doit correspondre EXACTEMENT au nom du fichier
   - Sensible à la casse : `clic-square.mp3` ≠ `Clic-Square.mp3`

## Configuration serveur (optionnel)

Si vous utilisez Firebase Cloud Messaging pour les notifications push, assurez-vous que votre serveur envoie bien le nom du fichier son dans le payload APNS.

Besoin d'aide pour configurer le serveur ? Je peux vous aider ! 🚀

