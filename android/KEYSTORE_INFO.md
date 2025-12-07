# 🔐 Informations sur les Keystores

## ✅ Keystores créés

### 1. Keystore Debug
- **Emplacement** : Géré automatiquement par Android SDK
- **Chemin** : `%USERPROFILE%\.android\debug.keystore` (Windows) ou `~/.android/debug.keystore` (macOS/Linux)
- **Alias** : `androiddebugkey`
- **Mot de passe** : `android` (par défaut)
- **Utilisation** : Builds de développement

### 2. Keystore Release
- **Emplacement** : `android/app/release.keystore`
- **Alias** : `release`
- **Mot de passe** : `points_points_release_2024`
- **Validité** : 10000 jours (jusqu'en 2053)
- **Utilisation** : Builds de production (APK/AAB pour Google Play)

## 📝 Configuration

### Fichier `key.properties`
Les informations du keystore release sont stockées dans `android/key.properties` :
```
storePassword=points_points_release_2024
keyPassword=points_points_release_2024
keyAlias=release
storeFile=app/release.keystore
```

⚠️ **IMPORTANT** : Ce fichier est dans `.gitignore` et ne doit JAMAIS être commité !

### Configuration dans `build.gradle.kts`
Le fichier `android/app/build.gradle.kts` est configuré pour :
- Utiliser automatiquement le keystore debug pour les builds debug
- Utiliser le keystore release pour les builds release
- Fallback sur debug si `key.properties` n'existe pas

## 🔒 Sécurité

### ⚠️ INFORMATIONS CRITIQUES

**MOT DE PASSE DU KEYSTORE RELEASE** : `points_points_release_2024`

**⚠️ GARDEZ CES INFORMATIONS EN SÉCURITÉ !**

- Perdre le keystore de release = **IMPOSSIBLE de mettre à jour l'application sur Google Play**
- Faites plusieurs sauvegardes sécurisées du fichier `release.keystore`
- Ne partagez JAMAIS le keystore ou son mot de passe
- Stockez une copie dans un coffre-fort sécurisé (1Password, LastPass, etc.)

## 📋 Fingerprints

### Debug
- **SHA1** : `AA:3B:B4:CD:0C:72:BC:3E:E9:8A:0C:03:B7:95:05:24:A6:DA:39:FE`
- **SHA256** : `5D:7D:9B:EC:23:62:C7:25:52:5D:F0:36:BB:9D:1C:F3:99:45:D7:BD:22:9D:83:DF:4B:71:70:E3:70:A6:AD:5F`

### Release
- **SHA1** : `FA:2E:E2:BE:C9:2B:49:45:9B:70:6D:37:1D:E0:E6:37:18:C3:C5:38`
- **SHA256** : `B2:DC:8F:96:4C:F9:0A:CE:D6:AB:DF:FA:E0:7F:2F:D3:A2:44:44:85:8E:E5:CB:B9:2C:C4:6F:83:CE:14:0C:95`

## 🚀 Utilisation

### Build Debug
```bash
flutter build apk --debug
# ou
flutter run
```
Utilise automatiquement le keystore debug.

### Build Release
```bash
flutter build apk --release
# ou
flutter build appbundle --release
```
Utilise le keystore release configuré.

## ✅ Vérification

Pour vérifier que le keystore release est correctement configuré :

```bash
cd android
./gradlew assembleRelease
```

Si tout est correct, l'APK sera signé avec le keystore release.

## 🔄 Récupération des fingerprints

Pour obtenir à nouveau les fingerprints :

**Debug:**
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release:**
```bash
cd android/app
keytool -list -v -keystore release.keystore -alias release -storepass points_points_release_2024
```

## 📝 Notes

- Le keystore debug est géré automatiquement par Android SDK
- Le keystore release doit être créé manuellement (déjà fait ✅)
- Les deux keystores sont maintenant configurés et prêts à être utilisés
- Les fingerprints doivent être ajoutés dans Firebase Console pour Google Sign In

