# Guide : Configuration du son de notification personnalisé pour iOS

## Vue d'ensemble

Votre application utilise déjà un son personnalisé (`clic-square.mp3`) qui fonctionne parfaitement sur Android. Pour iOS, la configuration est légèrement différente et nécessite quelques étapes supplémentaires.

## 📋 Table des matières

1. [Configuration APNS dans Firebase Console](#1-configuration-apns-dans-firebase-console)
2. [Configuration côté serveur](#2-configuration-côté-serveur)
3. [Notifications locales vs Push](#3-notifications-locales-vs-push)
4. [Vérification et test](#4-vérification-et-test)

## 1. Configuration APNS dans Firebase Console

Pour que Firebase puisse envoyer des notifications push aux appareils iOS, vous devez configurer APNS (Apple Push Notification Service) dans Firebase Console.

### Étape 1 : Créer une clé APNs dans Apple Developer

1. **Connectez-vous à Apple Developer**
   - Allez sur [developer.apple.com](https://developer.apple.com/)
   - Connectez-vous avec votre compte développeur

2. **Accédez aux clés (Keys)**
   - Cliquez sur **Certificates, Identifiers & Profiles**
   - Dans le menu de gauche, sélectionnez **Keys**

3. **Créer une nouvelle clé**
   - Cliquez sur le bouton **+** (en haut à gauche)
   - Donnez un nom à votre clé (ex: "Firebase APNs Key")
   - Cochez la case **Apple Push Notifications service (APNs)**
   - Cliquez sur **Continue**, puis **Register**

4. **Télécharger la clé**
   - ⚠️ **IMPORTANT** : Téléchargez le fichier `.p8` immédiatement (vous ne pourrez le télécharger qu'une seule fois)
   - Notez l'**Key ID** (affiché sur la page)
   - Notez votre **Team ID** (visible en haut à droite de la page Apple Developer)

### Étape 2 : Configurer APNs dans Firebase Console

1. **Accédez à Firebase Console**
   - Allez sur [console.firebase.google.com](https://console.firebase.google.com/)
   - Sélectionnez votre projet (points-points)

2. **Ouvrir les paramètres du projet**
   - Cliquez sur l'icône ⚙️ (Settings) à côté de **Project Overview**
   - Sélectionnez **Project settings**

3. **Configurer Cloud Messaging pour iOS**
   - Allez dans l'onglet **Cloud Messaging**
   - Faites défiler jusqu'à la section **Apple app configuration**
   - Trouvez votre application iOS (ou créez-en une si nécessaire)

4. **Uploader la clé APNs**
   - Sous **APNs authentication key**, cliquez sur **Upload**
   - Téléversez le fichier `.p8` que vous avez téléchargé
   - Entrez le **Key ID** (noté à l'étape 1)
   - Entrez le **Team ID** (noté à l'étape 1)
   - Cliquez sur **Upload**

5. **Vérifier la configuration**
   - Vous devriez voir un message de confirmation
   - L'état devrait passer à "Configured" ou "✓"

**Note importante :** Firebase utilise automatiquement l'environnement APNs approprié (sandbox pour le développement, production pour les apps publiées) en fonction du type de build de votre application.

### Étape 3 : Vérifier le Bundle ID

Assurez-vous que le **Bundle ID** de votre application iOS correspond à celui configuré dans Firebase :
- Bundle ID dans Firebase : `com.pegadev.pointsPoints`
- Vérifiez que c'est le même dans Xcode (Target > General > Bundle Identifier)

## 2. Configuration côté serveur

✅ **Aucune configuration supplémentaire nécessaire !**

Une fois APNs configuré dans Firebase Console, votre serveur Laravel n'a besoin d'aucune configuration supplémentaire. Firebase gère automatiquement la communication avec APNs.

### Ce qui est déjà configuré

Votre serveur utilise déjà :
- ✅ Le fichier de credentials Firebase (`firebase-credentials.json`)
- ✅ Le service FCM configuré dans `app/Services/FCMService.php`
- ✅ La configuration APNS pour le son personnalisé (lignes 79-104)

### Vérification de la configuration serveur

Le service FCM utilise le fichier de credentials Firebase qui contient toutes les informations nécessaires pour communiquer avec Firebase, qui à son tour communique avec APNs.

**Fichier de credentials :**
- Chemin par défaut : `storage/app/firebase-credentials.json`
- Ou configuré via : `FIREBASE_CREDENTIALS_PATH` dans `.env`

**Vérifier que le fichier existe :**
```bash
# Dans le répertoire racine de votre projet Laravel
ls -la storage/app/firebase-credentials.json
```

Si le fichier n'existe pas, téléchargez-le depuis Firebase Console :
1. Firebase Console > Project Settings > Service Accounts
2. Cliquez sur **Generate New Private Key**
3. Téléchargez le fichier JSON
4. Placez-le dans `storage/app/firebase-credentials.json`

## 3. Différences entre notifications locales et push

#### Notifications locales (Foreground)
Les notifications affichées quand l'application est ouverte sont gérées par `flutter_local_notifications`. Le son est déjà configuré dans votre code :

```245:250:lib/services/notification_service.dart
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'clic-square', // Sans extension pour iOS
      );
```

#### Notifications push (Background/Killed)
Pour les notifications push reçues en arrière-plan ou quand l'app est fermée, le son doit être spécifié dans le payload de la notification depuis votre serveur Firebase.

✅ **Configuration serveur** : La configuration a été effectuée dans `app/Services/FCMService.php`. Le service configure automatiquement le son personnalisé pour iOS (APNS) et Android dans toutes les notifications push.

**⚠️ IMPORTANT pour iOS :** Le nom du son dans le payload APNS doit être **sans extension**. iOS cherche automatiquement le fichier avec les extensions `.caf`, `.aif`, `.wav`, `.mp3`.

**Format du payload Firebase configuré côté serveur :**

```json
{
  "notification": {
    "title": "Titre",
    "body": "Message"
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "clic-square",
        "badge": 1,
        "content-available": 1
      }
    },
    "headers": {
      "apns-priority": "10"
    }
  },
  "android": {
    "notification": {
      "sound": "clic-square.mp3"
    }
  }
}
```

**Implémentation serveur :**
- ✅ Configuration APNS pour iOS : `app/Services/FCMService.php` (méthode `configureMessageWithSound`)
  - Nom du son : `clic-square` (sans extension)
  - Priorité haute configurée
  - `content-available: 1` pour les notifications en arrière-plan
- ✅ Configuration Android : `app/Services/FCMService.php` (méthode `configureMessageWithSound`)
  - Nom du son : `clic-square.mp3` (avec extension)
- ✅ Toutes les méthodes d'envoi (`sendToToken`, `sendToTokens`, `sendToTopic`) incluent maintenant le son personnalisé

## 4. Vérification et test

### Vérifier la configuration APNs

1. **Dans Firebase Console**
   - Allez dans Project Settings > Cloud Messaging
   - Vérifiez que l'application iOS affiche "APNs authentication key: ✓"

2. **Tester une notification push**
   - Utilisez l'interface d'administration de votre application
   - Ou envoyez une notification via l'API
   - Vérifiez que l'appareil iOS reçoit la notification avec le son personnalisé

### Dépannage

**Problème : Les notifications ne sont pas reçues sur iOS**
- ✅ Vérifiez que APNs est configuré dans Firebase Console
- ✅ Vérifiez que le Bundle ID correspond
- ✅ Vérifiez que l'application a les permissions de notification
- ✅ Vérifiez que le fichier `firebase-credentials.json` existe côté serveur

**Problème : Le son personnalisé ne joue pas**
- ✅ Vérifiez que le fichier `clic-square.mp3` est dans le bundle iOS (dans `ios/Runner/`)
- ✅ Vérifiez que le fichier est ajouté au projet Xcode
  - Ouvrez le projet dans Xcode
  - Vérifiez que `clic-square.mp3` apparaît dans le projet (dans le dossier Runner)
  - Assurez-vous que le fichier est inclus dans le target "Runner"
- ✅ Vérifiez que le format est correct (`.mp3`, `.aif`, `.caf`, ou `.wav`)
- ✅ **IMPORTANT** : Dans le payload APNS, utilisez le nom sans extension (`clic-square` et non `clic-square.mp3`)
- ✅ Vérifiez que le payload APNS inclut `content-available: 1` pour les notifications en arrière-plan
- ✅ Pour iOS, le son doit être dans le répertoire principal du projet, pas dans un sous-dossier

**Problème : Les notifications arrivent mais sans son sur iOS**
- ✅ Vérifiez que le nom du son dans le payload APNS est **sans extension** (`clic-square` et non `clic-square.mp3`)
- ✅ Vérifiez que le fichier son est bien dans `ios/Runner/` et ajouté au projet Xcode
- ✅ Vérifiez que les permissions de notification incluent le son (`sound: true` dans la demande de permission)
- ✅ Pour les notifications en foreground, vérifiez que `DarwinNotificationDetails` utilise le nom sans extension

**Problème : Erreur "Invalid APNs credentials"**
- ✅ Vérifiez que la clé `.p8` est correctement uploadée dans Firebase
- ✅ Vérifiez que le Key ID et Team ID sont corrects
- ✅ Vérifiez que la clé APNs a les permissions "Apple Push Notifications service (APNs)"

### Résumé de la configuration

| Élément | Statut | Emplacement |
|---------|--------|-------------|
| Code Dart (notifications locales) | ✅ Configuré | `lib/services/notification_service.dart` |
| Configuration serveur (APNS payload) | ✅ Configuré | `app/Services/FCMService.php` |
| Configuration serveur (Android payload) | ✅ Configuré | `app/Services/FCMService.php` |
| Clé APNs dans Apple Developer | ⚠️ À configurer | [developer.apple.com](https://developer.apple.com/) |
| APNs dans Firebase Console | ⚠️ À configurer | [console.firebase.google.com](https://console.firebase.google.com/) |
| Fichier son dans le bundle iOS | ⚠️ À vérifier | Projet Xcode |


