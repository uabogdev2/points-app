# 🔔 Configuration Serveur : Notifications Push avec Firebase et APNS pour iOS

**Version :** 1.0  
**Date :** 2024  
**Application :** Points Master

---

## 📋 Table des matières

1. [Introduction](#introduction)
2. [Configuration Firebase Cloud Messaging](#configuration-firebase-cloud-messaging)
   - [Configuration APNS pour iOS](#configuration-apns-pour-ios)
   - [Téléchargement des certificats/clés APNS](#téléchargement-des-certificatsclés-apns)
3. [Format des notifications](#format-des-notifications)
   - [Structure du payload](#structure-du-payload)
   - [Notifications iOS avec son personnalisé](#notifications-ios-avec-son-personnalisé)
   - [Notifications Android](#notifications-android)
   - [Notifications multi-plateformes](#notifications-multi-plateformes)
4. [Implémentation serveur](#implémentation-serveur)
   - [Node.js avec Firebase Admin SDK](#nodejs-avec-firebase-admin-sdk)
   - [Python avec Firebase Admin SDK](#python-avec-firebase-admin-sdk)
   - [PHP avec Firebase Admin SDK](#php-avec-firebase-admin-sdk)
   - [Exemple générique (REST API)](#exemple-générique-rest-api)
5. [Types de notifications Points Master](#types-de-notifications-points-master)
6. [Dépannage](#dépannage)
7. [Checklist de déploiement](#checklist-de-déploiement)

---

## 🎯 Introduction

Cette documentation explique comment configurer votre serveur backend pour envoyer des notifications push via Firebase Cloud Messaging (FCM), avec support complet pour iOS via APNS (Apple Push Notification service) et Android.

### Prerequisites

- ✅ Projet Firebase créé et configuré
- ✅ Application iOS configurée avec Firebase
- ✅ Application Android configurée avec Firebase
- ✅ Accès au compte développeur Apple (pour les certificats APNS)
- ✅ Accès à la console Firebase

---

## 🔥 Configuration Firebase Cloud Messaging

### Configuration APNS pour iOS

#### 1. Accéder aux paramètres FCM dans Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. Aller dans **Paramètres du projet** (icône ⚙️)
4. Allez dans l'onglet **Cloud Messaging**

#### 2. Configuration des certificats APNS

Firebase supporte deux méthodes pour APNS :

- **Clé APNS (recommandée)** : Méthode moderne et plus simple
- **Certificat APNS** : Méthode traditionnelle

### Téléchargement des certificats/clés APNS

#### Option A : Clé APNS (Recommandée) ⭐

**Avantages :**
- Plus simple à configurer
- Pas d'expiration (contrairement aux certificats)
- Fonctionne pour le développement ET la production

**Étapes :**

1. **Créer une clé APNS dans Apple Developer :**
   - Allez sur [Apple Developer Portal](https://developer.apple.com/account/)
   - Connectez-vous avec votre compte développeur
   - Allez dans **Certificates, Identifiers & Profiles**
   - Cliquez sur **Keys** dans la sidebar
   - Cliquez sur **+** pour créer une nouvelle clé
   - Donnez un nom (ex: "Firebase APNS Key")
   - Cochez **Apple Push Notifications service (APNs)**
   - Cliquez sur **Continue** puis **Register**
   - **Important :** Téléchargez immédiatement le fichier `.p8` (vous ne pourrez plus le télécharger plus tard)
   - Notez l'**Key ID** affiché

2. **Télécharger votre Team ID :**
   - Dans Apple Developer Portal, allez dans **Membership**
   - Notez votre **Team ID** (ex: `ABCD1234EF`)

3. **Configurer dans Firebase :**
   - Retournez dans Firebase Console → Paramètres → Cloud Messaging
   - Dans la section **Apple app configuration**, cliquez sur **Upload**
   - Sélectionnez **APNs Authentication Key**
   - Uploadez votre fichier `.p8`
   - Entrez votre **Key ID**
   - Entrez votre **Team ID**
   - Cliquez sur **Upload**

#### Option B : Certificat APNS

**Pour le développement :**
- Créez un certificat de développement APNS dans Apple Developer Portal
- Uploadez-le dans Firebase Console (section Cloud Messaging)

**Pour la production :**
- Créez un certificat de production APNS
- Uploadez-le séparément dans Firebase

---

## 📨 Format des notifications

### Structure du payload

Firebase Cloud Messaging utilise un format JSON spécifique pour envoyer des notifications. La structure de base est :

```json
{
  "message": {
    "token": "fcm_token_here",
    "notification": {
      "title": "Titre de la notification",
      "body": "Corps de la notification"
    },
    "data": {
      "type": "invitation",
      "custom_field": "value"
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "clic-square.mp3",
          "badge": 1,
          "alert": {
            "title": "Titre de la notification",
            "body": "Corps de la notification"
          }
        }
      }
    },
    "android": {
      "notification": {
        "sound": "clic_square",
        "channel_id": "points_master_channel_v2"
      }
    }
  }
}
```

### Notifications iOS avec son personnalisé

Pour iOS, le son personnalisé doit être spécifié dans la section `apns.payload.aps.sound`. Le fichier audio doit être présent dans le bundle de l'application iOS.

**Format du payload iOS :**

```json
{
  "message": {
    "token": "fcm_token_ios",
    "notification": {
      "title": "Nouvelle invitation",
      "body": "John Doe vous a invité à jouer"
    },
    "data": {
      "type": "invitation",
      "invitation_id": "1",
      "from_user_id": "2",
      "grid_size": "5"
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "clic-square.mp3",
          "badge": 1,
          "alert": {
            "title": "Nouvelle invitation",
            "body": "John Doe vous a invité à jouer"
          },
          "content-available": 1
        }
      },
      "headers": {
        "apns-priority": "10"
      }
    }
  }
}
```

**Points importants pour iOS :**

1. **Nom du fichier audio** : `clic-square.mp3` (doit correspondre exactement au fichier dans le bundle iOS)
2. **Format audio** : `.mp3`, `.caf`, `.aiff`, ou `.wav` supportés
3. **Durée** : Maximum 30 secondes
4. **Taille** : Recommandé < 5 MB
5. **Badge** : Utilisez un nombre pour le badge de l'app
6. **Priority** : `"10"` pour notifications importantes (affichage immédiat)

### Notifications Android

**Format du payload Android :**

```json
{
  "message": {
    "token": "fcm_token_android",
    "notification": {
      "title": "Nouvelle invitation",
      "body": "John Doe vous a invité à jouer"
    },
    "data": {
      "type": "invitation",
      "invitation_id": "1",
      "from_user_id": "2",
      "grid_size": "5"
    },
    "android": {
      "priority": "high",
      "notification": {
        "sound": "clic_square",
        "channel_id": "points_master_channel_v2",
        "icon": "ic_stat_motification_logo",
        "tag": "invitation_1"
      }
    }
  }
}
```

**Points importants pour Android :**

1. **Nom du fichier audio** : `clic_square` (sans extension, fichier dans `res/raw/`)
2. **Channel ID** : `points_master_channel_v2` (doit correspondre au canal Android)
3. **Priority** : `"high"` pour notifications importantes

### Notifications multi-plateformes

Pour envoyer une notification à un utilisateur sans savoir sa plateforme, ou pour cibler plusieurs appareils :

```json
{
  "message": {
    "token": "fcm_token",
    "notification": {
      "title": "Nouvelle invitation",
      "body": "John Doe vous a invité à jouer"
    },
    "data": {
      "type": "invitation",
      "invitation_id": "1",
      "from_user_id": "2",
      "grid_size": "5"
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "clic-square.mp3",
          "badge": 1
        }
      }
    },
    "android": {
      "notification": {
        "sound": "clic_square",
        "channel_id": "points_master_channel_v2"
      }
    }
  }
}
```

Firebase déterminera automatiquement la plateforme et utilisera les bonnes configurations.

---

## 💻 Implémentation serveur

### Node.js avec Firebase Admin SDK

#### Installation

```bash
npm install firebase-admin
```

#### Configuration initiale

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
```

#### Fonction d'envoi de notification

```javascript
/**
 * Envoie une notification push avec son personnalisé
 * @param {string} fcmToken - Token FCM de l'appareil
 * @param {string} title - Titre de la notification
 * @param {string} body - Corps de la notification
 * @param {Object} data - Données additionnelles
 * @param {string} type - Type de notification (invitation, game_turn, etc.)
 */
async function sendPushNotification(fcmToken, title, body, data, type) {
  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body
    },
    data: {
      type: type,
      ...Object.keys(data).reduce((acc, key) => {
        acc[key] = String(data[key]);
        return acc;
      }, {})
    },
    // Configuration iOS avec son personnalisé
    apns: {
      payload: {
        aps: {
          sound: 'clic-square.mp3',
          badge: 1,
          alert: {
            title: title,
            body: body
          },
          'content-available': 1
        }
      },
      headers: {
        'apns-priority': '10'
      }
    },
    // Configuration Android avec son personnalisé
    android: {
      priority: 'high',
      notification: {
        sound: 'clic_square',
        channelId: 'points_master_channel_v2',
        icon: 'ic_stat_motification_logo',
        tag: `${type}_${data.id || Date.now()}`
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notification envoyée avec succès:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Erreur envoi notification:', error);
    return { success: false, error: error.message };
  }
}
```

#### Exemple d'utilisation

```javascript
// Notification d'invitation
await sendPushNotification(
  userFcmToken,
  'Nouvelle invitation',
  'John Doe vous a invité à jouer',
  {
    invitation_id: 1,
    from_user_id: 2,
    grid_size: 5
  },
  'invitation'
);

// Notification de tour de jeu
await sendPushNotification(
  userFcmToken,
  'C\'est votre tour !',
  'Vous pouvez maintenant jouer',
  {
    game_id: 123,
    current_player_id: 1
  },
  'game_turn'
);
```

#### Envoi à plusieurs appareils

```javascript
async function sendPushNotificationToMultipleDevices(fcmTokens, title, body, data, type) {
  const message = {
    notification: {
      title: title,
      body: body
    },
    data: {
      type: type,
      ...Object.keys(data).reduce((acc, key) => {
        acc[key] = String(data[key]);
        return acc;
      }, {})
    },
    apns: {
      payload: {
        aps: {
          sound: 'clic-square.mp3',
          badge: 1
        }
      }
    },
    android: {
      notification: {
        sound: 'clic_square',
        channelId: 'points_master_channel_v2'
      }
    },
    tokens: fcmTokens // Array de tokens
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ ${response.successCount} notifications envoyées`);
    console.log(`❌ ${response.failureCount} échecs`);
    return response;
  } catch (error) {
    console.error('❌ Erreur:', error);
    throw error;
  }
}
```

### Python avec Firebase Admin SDK

#### Installation

```bash
pip install firebase-admin
```

#### Configuration initiale

```python
import firebase_admin
from firebase_admin import credentials, messaging

cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred)
```

#### Fonction d'envoi de notification

```python
def send_push_notification(fcm_token, title, body, data, notification_type):
    """
    Envoie une notification push avec son personnalisé
    
    Args:
        fcm_token: Token FCM de l'appareil
        title: Titre de la notification
        body: Corps de la notification
        data: Données additionnelles (dict)
        notification_type: Type de notification
    """
    # Convertir les données en strings (requis par FCM)
    data_dict = {str(k): str(v) for k, v in data.items()}
    data_dict['type'] = notification_type
    
    message = messaging.Message(
        token=fcm_token,
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        data=data_dict,
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    sound='clic-square.mp3',
                    badge=1,
                    alert=messaging.ApsAlert(
                        title=title,
                        body=body
                    ),
                    content_available=True
                )
            ),
            headers={
                'apns-priority': '10'
            }
        ),
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                sound='clic_square',
                channel_id='points_master_channel_v2',
                icon='ic_stat_motification_logo',
                tag=f"{notification_type}_{data.get('id', '')}"
            )
        )
    )
    
    try:
        response = messaging.send(message)
        print(f'✅ Notification envoyée: {response}')
        return {'success': True, 'message_id': response}
    except Exception as e:
        print(f'❌ Erreur: {e}')
        return {'success': False, 'error': str(e)}
```

#### Exemple d'utilisation

```python
# Notification d'invitation
send_push_notification(
    user_fcm_token,
    'Nouvelle invitation',
    'John Doe vous a invité à jouer',
    {
        'invitation_id': '1',
        'from_user_id': '2',
        'grid_size': '5'
    },
    'invitation'
)
```

### PHP avec Firebase Admin SDK

#### Installation via Composer

```bash
composer require kreait/firebase-php
```

#### Configuration initiale

```php
<?php
require 'vendor/autoload.php';

use Kreait\Firebase\Factory;

$factory = (new Factory)
    ->withServiceAccount('path/to/serviceAccountKey.json');

$messaging = $factory->createMessaging();
```

#### Fonction d'envoi de notification

```php
function sendPushNotification($fcmToken, $title, $body, $data, $type) {
    global $messaging;
    
    // Convertir les données en strings
    $dataStrings = array_map('strval', $data);
    $dataStrings['type'] = $type;
    
    $message = \Kreait\Firebase\Messaging\CloudMessage::withTarget('token', $fcmToken)
        ->withNotification(\Kreait\Firebase\Messaging\Notification::create($title, $body))
        ->withData($dataStrings)
        ->withApnsConfig([
            'payload' => [
                'aps' => [
                    'sound' => 'clic-square.mp3',
                    'badge' => 1,
                    'alert' => [
                        'title' => $title,
                        'body' => $body
                    ],
                    'content-available' => 1
                ]
            ],
            'headers' => [
                'apns-priority' => '10'
            ]
        ])
        ->withAndroidConfig([
            'priority' => 'high',
            'notification' => [
                'sound' => 'clic_square',
                'channel_id' => 'points_master_channel_v2',
                'icon' => 'ic_stat_motification_logo',
                'tag' => $type . '_' . ($data['id'] ?? time())
            ]
        ]);
    
    try {
        $result = $messaging->send($message);
        return ['success' => true, 'message_id' => $result];
    } catch (\Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}
```

### Exemple générique (REST API)

Si vous n'utilisez pas un SDK Firebase, vous pouvez utiliser directement l'API REST de FCM.

#### Requête HTTP

```bash
POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send
Content-Type: application/json
Authorization: Bearer YOUR_ACCESS_TOKEN
```

#### Corps de la requête

```json
{
  "message": {
    "token": "fcm_token_here",
    "notification": {
      "title": "Nouvelle invitation",
      "body": "John Doe vous a invité à jouer"
    },
    "data": {
      "type": "invitation",
      "invitation_id": "1",
      "from_user_id": "2",
      "grid_size": "5"
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "clic-square.mp3",
          "badge": 1,
          "alert": {
            "title": "Nouvelle invitation",
            "body": "John Doe vous a invité à jouer"
          },
          "content-available": 1
        }
      },
      "headers": {
        "apns-priority": "10"
      }
    },
    "android": {
      "priority": "high",
      "notification": {
        "sound": "clic_square",
        "channel_id": "points_master_channel_v2",
        "icon": "ic_stat_motification_logo"
      }
    }
  }
}
```

---

## 🎮 Types de notifications Points Master

### 1. Notification d'invitation

**Type :** `invitation`

**Payload :**
```json
{
  "notification": {
    "title": "Nouvelle invitation",
    "body": "{{from_user_name}} vous a invité à jouer"
  },
  "data": {
    "type": "invitation",
    "invitation_id": "1",
    "from_user_id": "2",
    "grid_size": "5"
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "clic-square.mp3",
        "badge": 1
      }
    }
  },
  "android": {
    "notification": {
      "sound": "clic_square",
      "channel_id": "points_master_channel_v2"
    }
  }
}
```

### 2. Notification de tour de jeu

**Type :** `game_turn`

**Payload :**
```json
{
  "notification": {
    "title": "C'est votre tour !",
    "body": "Vous pouvez maintenant jouer"
  },
  "data": {
    "type": "game_turn",
    "game_id": "123",
    "current_player_id": "1"
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "clic-square.mp3",
        "badge": 1
      }
    }
  },
  "android": {
    "notification": {
      "sound": "clic_square",
      "channel_id": "points_master_channel_v2"
    }
  }
}
```

### 3. Notification de fin de partie

**Type :** `game_finished`

**Payload :**
```json
{
  "notification": {
    "title": "Partie terminée",
    "body": "{{winner_name}} a gagné avec {{score}} points !"
  },
  "data": {
    "type": "game_finished",
    "game_id": "123",
    "winner_id": "2",
    "final_score": "15"
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "clic-square.mp3",
        "badge": 1
      }
    }
  },
  "android": {
    "notification": {
      "sound": "clic_square",
      "channel_id": "points_master_channel_v2"
    }
  }
}
```

### 4. Notification globale

**Type :** `global`

**Payload :**
```json
{
  "notification": {
    "title": "{{title}}",
    "body": "{{message}}"
  },
  "data": {
    "type": "global",
    "notification_id": "1",
    "title": "Titre",
    "message": "Message"
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "clic-square.mp3",
        "badge": 1
      }
    }
  },
  "android": {
    "notification": {
      "sound": "clic_square",
      "channel_id": "points_master_channel_v2"
    }
  }
}
```

---

## 🔧 Dépannage

### Problème : Les notifications iOS ne fonctionnent pas

**Solutions :**

1. **Vérifier la configuration APNS dans Firebase**
   - Allez dans Firebase Console → Paramètres → Cloud Messaging
   - Vérifiez que la clé APNS ou le certificat est bien uploadé
   - Vérifiez que le Team ID et Key ID sont corrects

2. **Vérifier le token FCM**
   - Assurez-vous que le token FCM est valide et à jour
   - Les tokens FCM peuvent expirer ou changer

3. **Vérifier les permissions iOS**
   - L'utilisateur doit avoir accordé les permissions de notification
   - Vérifiez dans les paramètres iOS de l'appareil

4. **Vérifier le payload**
   - Le nom du fichier audio doit correspondre exactement : `clic-square.mp3`
   - Vérifiez que le fichier est dans le bundle iOS

5. **Vérifier les logs**
   - Regardez les logs Firebase dans la console
   - Vérifiez les erreurs APNS

### Problème : Le son personnalisé ne fonctionne pas sur iOS

**Solutions :**

1. **Vérifier le nom du fichier**
   - Le nom dans le payload APNS doit correspondre EXACTEMENT au nom du fichier dans le bundle
   - Sensible à la casse : `clic-square.mp3` ≠ `Clic-Square.mp3`

2. **Vérifier que le fichier est dans le bundle**
   - Le fichier doit être ajouté au projet Xcode
   - Vérifiez dans Xcode → Build Phases → Copy Bundle Resources

3. **Vérifier le format audio**
   - Format supporté : `.mp3`, `.caf`, `.aiff`, `.wav`
   - Durée max : 30 secondes
   - Taille recommandée : < 5 MB

4. **Tester avec le son par défaut**
   - Remplacez temporairement `"sound": "clic-square.mp3"` par `"sound": "default"`
   - Si ça fonctionne, le problème vient du fichier audio

### Problème : Les notifications fonctionnent en foreground mais pas en background

**Solutions :**

1. **Vérifier le payload APNS**
   - Ajoutez `"content-available": 1` dans `aps`
   - Assurez-vous que `apns-priority` est `"10"`

2. **Vérifier les background modes**
   - Vérifiez que `remote-notification` est dans `UIBackgroundModes` dans `Info.plist`

3. **Vérifier le handler de background**
   - Assurez-vous que `firebaseMessagingBackgroundHandler` est bien configuré

### Codes d'erreur courants

- **InvalidRegistration** : Le token FCM est invalide ou a expiré
- **NotRegistered** : Le token FCM n'est plus valide (app désinstallée)
- **MismatchSenderId** : Le sender ID ne correspond pas
- **InvalidApnsCredential** : Problème avec les certificats/clés APNS

---

## ✅ Checklist de déploiement

### Configuration Firebase

- [ ] Projet Firebase créé
- [ ] Application iOS ajoutée au projet Firebase
- [ ] `GoogleService-Info.plist` ajouté au projet iOS
- [ ] Clé APNS ou certificat APNS uploadé dans Firebase
- [ ] Team ID et Key ID configurés correctement

### Configuration serveur

- [ ] Firebase Admin SDK installé
- [ ] Fichier `serviceAccountKey.json` téléchargé et sécurisé
- [ ] Fonction d'envoi de notification implémentée
- [ ] Son personnalisé configuré dans le payload APNS (`clic-square.mp3`)
- [ ] Son personnalisé configuré dans le payload Android (`clic_square`)

### Tests

- [ ] Notification testée sur iOS (foreground)
- [ ] Notification testée sur iOS (background)
- [ ] Notification testée sur iOS (app fermée)
- [ ] Son personnalisé fonctionne sur iOS
- [ ] Notification testée sur Android
- [ ] Son personnalisé fonctionne sur Android

### Production

- [ ] Certificat/clé APNS de production configuré
- [ ] Application iOS en mode Release testée
- [ ] Monitoring des erreurs FCM configuré
- [ ] Logs d'erreur surveillés

---

## 📚 Ressources supplémentaires

- [Documentation Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Documentation APNS](https://developer.apple.com/documentation/usernotifications)
- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
- [Format des messages FCM](https://firebase.google.com/docs/cloud-messaging/concept-options)

---

## 💡 Notes importantes

1. **Sécurité** : Ne commitez JAMAIS le fichier `serviceAccountKey.json` dans votre repository Git. Utilisez des variables d'environnement ou un gestionnaire de secrets.

2. **Tokens FCM** : Les tokens FCM peuvent changer. Mettez-les à jour régulièrement via l'endpoint `/api/fcm/token`.

3. **Rate Limiting** : Firebase a des limites de débit. Pour de gros volumes, utilisez `sendEachForMulticast` ou `sendAll`.

4. **Badge iOS** : Gérer correctement le badge pour ne pas laisser des badges obsolètes.

5. **Tests** : Toujours tester sur des appareils réels, pas seulement sur simulateur/émulateur.

---

**Dernière mise à jour :** 2024  
**Version de la documentation :** 1.0

