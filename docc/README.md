# Points Master - Application Flutter

Jeu mobile compétitif de Points et Carrés avec authentification Firebase, matchmaking et parties multijoueur en temps réel.

## 🚀 Fonctionnalités

- ✅ Authentification Firebase (Google & Apple)
- ✅ Matchmaking automatique
- ✅ Invitations privées entre joueurs
- ✅ Parties multijoueur en temps réel (Socket.IO)
- ✅ Statistiques et classements
- ✅ Mode solo contre IA (à venir)
- ✅ UI moderne avec Material 3

## 📋 Prérequis

- Flutter SDK 3.8.1 ou supérieur
- Compte Firebase configuré
- Backend API opérationnel (voir `API_MOBILE.md`)

## 🔧 Configuration

### 1. Installation des dépendances

```bash
flutter pub get
```

### 2. Configuration Firebase avec FlutterFire CLI

**FlutterFire CLI** est l'outil officiel recommandé pour configurer Firebase dans Flutter. Il configure automatiquement tous les fichiers nécessaires.

#### Installation de FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

#### Configuration automatique

1. Créez un projet Firebase sur [Firebase Console](https://console.firebase.google.com/)

2. Connectez-vous à Firebase :
```bash
firebase login
```

3. Configurez FlutterFire dans votre projet :
```bash
flutterfire configure
```

Cette commande va :
- Détecter vos plateformes (Android, iOS)
- Vous permettre de sélectionner votre projet Firebase
- Générer automatiquement le fichier `firebase_options.dart`
- Configurer tous les fichiers nécessaires

4. Le fichier `firebase_options.dart` sera créé automatiquement dans `lib/`

5. Firebase est maintenant configuré ! L'initialisation dans `main.dart` utilisera automatiquement ces options.

### 3. Configuration de l'API

Modifiez `lib/utils/config.dart` avec votre URL d'API :

```dart
static const String baseUrl = 'https://votre-domaine.com/api';
static const String socketUrl = 'https://votre-domaine.com:3001';
```

### 4. Configuration iOS (pour Apple Sign In)

Ajoutez dans `ios/Runner/Info.plist` :

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.pegadev.points_points</string>
    </array>
  </dict>
</array>
```

### 5. Vérification de la configuration Android

FlutterFire CLI configure automatiquement `android/app/build.gradle`. Vérifiez que le plugin est présent :

```gradle
apply plugin: 'com.google.gms.google-services'
```

Si ce n'est pas le cas, ajoutez-le manuellement.

## 🎮 Utilisation

### Lancer l'application

```bash
flutter run
```

### Build pour production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📁 Structure du projet

```
lib/
├── models/          # Modèles de données
├── services/        # Services (API, Auth, Socket, Storage)
├── providers/       # Gestion d'état avec Provider
├── screens/         # Écrans de l'application
├── widgets/         # Widgets réutilisables
├── theme/           # Thème et styles
└── utils/           # Utilitaires et configuration
```

## 🔌 API Backend

- **Documentation API Mobile :** Voir `API_MOBILE.md` pour la documentation complète de l'API
- **Configuration Serveur Notifications :** Voir `CONFIGURATION_SERVEUR_NOTIFICATIONS.md` pour configurer Firebase Cloud Messaging avec APNS pour iOS

## 📝 Notes importantes

1. **Firebase**: L'application nécessite Firebase pour l'authentification
2. **Backend**: Assurez-vous que votre backend API est opérationnel
3. **Socket.IO**: Le serveur Socket.IO doit être accessible sur le port 3001
4. **Version**: Vérifiez régulièrement les mises à jour via `/api/version/check`

## 🐛 Dépannage

### Erreur de connexion Firebase
- Vérifiez que `flutterfire configure` a été exécuté avec succès
- Vérifiez que `lib/firebase_options.dart` existe
- Vérifiez que `Firebase.initializeApp()` est appelé dans `main.dart`
- Consultez `FIREBASE_SETUP.md` pour plus de détails

### Erreur de connexion API
- Vérifiez l'URL dans `lib/utils/config.dart`
- Vérifiez que le backend est accessible
- Vérifiez les logs du serveur

### Socket.IO ne se connecte pas
- Vérifiez l'URL Socket.IO dans `config.dart`
- Vérifiez que le serveur Socket.IO est démarré
- Vérifiez les règles de pare-feu

## 📄 Licence

Ce projet est privé.
