# 📱 Points Master - Documentation API Mobile

**Version API:** v1  
**Base URL:** `https://votre-domaine.com/api`  
**Socket.IO:** `https://votre-domaine.com:3001` ou `https://socket.votre-domaine.com` (selon configuration)

**Note:** Socket.IO peut être hébergé sur le même domaine, un sous-domaine, ou un domaine complètement différent. Consultez `NGINX_SEPARATE_DOMAIN_WEBSOCKET.md` pour la configuration.

---

## 📋 Table des matières

1. [Introduction](#introduction)
2. [Authentification](#authentification)
3. [Endpoints API](#endpoints-api)
   - [Authentification](#-authentification)
   - [Gestion du token FCM](#-gestion-du-token-fcm)
   - [Notifications Push (FCM)](#-notifications-push-fcm)
   - [Vérification de version](#-vérification-de-version)
   - [Matchmaking](#-matchmaking)
   - [Invitations](#-invitations)
   - [Parties](#-parties)
   - [Statistiques](#-statistiques)
4. [Socket.IO Events](#socketio-events)
5. [Modèles de données](#modèles-de-données)
6. [Codes d'erreur](#codes-derreur)
7. [Exemples d'intégration](#exemples-dintégration)

---

## 🎯 Introduction

Points Master est un jeu mobile compétitif inspiré du jeu classique "Points et Carrés". Cette documentation décrit l'API REST et les événements Socket.IO nécessaires pour intégrer l'application mobile Flutter.

### Fonctionnalités principales

- ✅ Authentification Firebase (Google & Apple uniquement)
- ✅ Gestion du token FCM pour les notifications push
- ✅ Notifications push automatiques (invitations, tours de jeu, fin de partie)
- ✅ Matchmaking automatique
- ✅ Invitations privées entre joueurs
- ✅ Parties multijoueur en temps réel
- ✅ Statistiques et classements
- ✅ Gestion des versions d'application avec force update

---

## 🔐 Authentification

### Format

Tous les endpoints protégés nécessitent un token Firebase dans le header :

```
Authorization: Bearer <firebase_uid>
```

**Note:** Après la connexion via `/api/auth/login`, le `firebase_uid` retourné doit être utilisé comme token pour les requêtes suivantes.

### Flux d'authentification

1. L'utilisateur se connecte avec Firebase (Google/Apple)
2. Récupérer le token Firebase ID
3. Appeler `/api/auth/login` avec ce token
4. Utiliser le `firebase_uid` retourné pour les requêtes suivantes

---

## 📡 Endpoints API

### 🔑 Authentification

#### POST `/api/auth/login`

Authentifie un utilisateur avec un token Firebase et crée/met à jour son profil.

**Request:**
```json
{
  "token": "firebase_id_token_here"
}
```

**Response 200:**
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "firebase_uid": "abc123xyz",
    "avatar_url": "https://example.com/avatar.jpg",
    "device_type": "android",
    "device_id": "device_unique_id",
    "app_version": "1.0.0",
    "country": "FR",
    "last_active_at": "2025-11-22T10:00:00Z",
    "statistic": {
      "games_played": 10,
      "games_won": 5,
      "games_lost": 5,
      "total_squares_completed": 42,
      "best_score": 15,
      "current_streak": 3,
      "longest_streak": 5
    }
  },
  "token": "abc123xyz"
}
```

**Response 401:**
```json
{
  "error": "Token invalide"
}
```

**Utilisation:**
- Stocker le `token` (firebase_uid) pour les requêtes suivantes
- Mettre à jour les informations utilisateur si nécessaire

---

#### GET `/api/auth/me`

Récupère les informations de l'utilisateur connecté.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Response 200:**
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "firebase_uid": "abc123xyz",
    "statistic": {
      "games_played": 10,
      "games_won": 5,
      "games_lost": 5,
      "total_squares_completed": 42,
      "best_score": 15,
      "current_streak": 3,
      "longest_streak": 5
    }
  }
}
```

---

### 📱 Gestion du token FCM

#### POST `/api/fcm/token`

Enregistre ou met à jour le token FCM de l'utilisateur pour recevoir les notifications push.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Request:**
```json
{
  "fcm_token": "fcm_token_from_firebase_messaging"
}
```

**Response 200:**
```json
{
  "message": "Token FCM mis à jour avec succès",
  "fcm_token": "fcm_token_from_firebase_messaging"
}
```

**Utilisation:**
- Appeler après l'obtention du token FCM depuis Firebase Messaging
- Appeler à chaque connexion pour s'assurer que le token est à jour
- Le token peut changer, il faut le mettre à jour régulièrement

---

#### DELETE `/api/fcm/token`

Supprime le token FCM de l'utilisateur (lors de la déconnexion).

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Response 200:**
```json
{
  "message": "Token FCM supprimé avec succès"
}
```

**Utilisation:**
- Appeler lors de la déconnexion de l'utilisateur
- Empêche l'envoi de notifications à un appareil déconnecté

---

### 🔔 Notifications Push (FCM)

**📚 Documentation complète :** Pour la configuration détaillée du serveur avec APNS pour iOS et Android, consultez [`CONFIGURATION_SERVEUR_NOTIFICATIONS.md`](./CONFIGURATION_SERVEUR_NOTIFICATIONS.md).

Le backend envoie automatiquement des notifications push via Firebase Cloud Messaging (FCM) dans les cas suivants :

#### Types de notifications

1. **Nouvelle invitation** (`type: "invitation"`)
   - Envoyée quand un joueur reçoit une invitation
   - Données : `invitation_id`, `from_user_id`, `grid_size`

2. **Tour de jeu** (`type: "game_turn"`)
   - Envoyée quand c'est le tour du joueur
   - Données : `game_id`, `current_player_id`

3. **Fin de partie** (`type: "game_finished"`)
   - Envoyée quand une partie se termine
   - Données : `game_id`, `winner_id`, `final_score`

4. **Notification globale** (`type: "global"`)
   - Envoyée par l'administrateur
   - Données : `notification_id`, `title`, `message`

#### Format des notifications FCM

```json
{
  "notification": {
    "title": "Nouvelle invitation",
    "body": "John Doe vous a invité à jouer"
  },
  "data": {
    "type": "invitation",
    "invitation_id": "1",
    "from_user_id": "2",
    "grid_size": "5"
  }
}
```

#### Gestion des notifications dans Flutter

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// Écouter les notifications en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Notification reçue en arrière-plan: ${message.data}');
  
  // Traiter selon le type
  switch (message.data['type']) {
    case 'invitation':
      // Naviguer vers l'écran d'invitations
      break;
    case 'game_turn':
      // Naviguer vers la partie
      break;
    case 'game_finished':
      // Afficher les résultats
      break;
  }
}

// Initialiser Firebase Messaging
void initFirebaseMessaging() {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Demander la permission
  messaging.requestPermission();
  
  // Écouter les notifications en foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Notification reçue: ${message.notification?.title}');
    // Afficher une notification locale
  });
  
  // Gérer les notifications en arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Obtenir le token FCM
  messaging.getToken().then((token) {
    print('Token FCM: $token');
    // Envoyer le token au backend via POST /api/fcm/token
  });
  
  // Écouter les changements de token
  messaging.onTokenRefresh.listen((newToken) {
    print('Nouveau token FCM: $newToken');
    // Mettre à jour le token au backend
  });
}
```

---

### 📱 Vérification de version

#### GET `/api/version/check`

Vérifie si une mise à jour de l'application est disponible.

**Query Parameters:**
- `platform` (required): `android` ou `ios`
- `version` (required): Version actuelle (ex: `1.0.0`)

**Example:**
```
GET /api/version/check?platform=android&version=1.0.0
```

**Response 200:**
```json
{
  "update_required": false,
  "update_available": true,
  "min_version": "1.0.0",
  "latest_version": "1.1.0",
  "force_update": false,
  "message": "Une nouvelle version est disponible avec de nouvelles fonctionnalités!",
  "update_url": "https://play.google.com/store/apps/details?id=com.pointsmaster.app"
}
```

**Champs:**
- `update_required`: `true` si la mise à jour est obligatoire
- `update_available`: `true` si une version plus récente existe
- `force_update`: Si `true`, l'utilisateur doit mettre à jour
- `update_url`: URL de téléchargement (Play Store/App Store)

**Utilisation:**
- Appeler au démarrage de l'application
- Afficher une popup si `update_required` est `true`
- Proposer la mise à jour si `update_available` est `true`

---

### 🎮 Matchmaking

#### POST `/api/matchmaking/find`

Recherche une partie rapide (matchmaking automatique).

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Request:**
```json
{
  "grid_size": 5
}
```

**Response 200:**
```json
{
  "game": {
    "id": 123,
    "status": "waiting",
    "grid_size": 5,
    "current_player_id": 1,
    "players": [
      {
        "id": 1,
        "user_id": 1,
        "user": {
          "id": 1,
          "name": "John Doe",
          "avatar_url": "https://example.com/avatar.jpg"
        },
        "score": 0,
        "position": 1
      }
    ],
    "created_at": "2025-11-22T10:00:00Z"
  },
  "matched": false
}
```

**Champs:**
- `matched`: `true` si un adversaire a été trouvé, `false` si la partie est en attente
- `status`: `waiting` (en attente) ou `active` (démarrée)

**Utilisation:**
- Si `matched` est `false`, attendre qu'un adversaire rejoigne
- Utiliser Socket.IO pour être notifié quand la partie démarre
- Si `matched` est `true`, la partie est active, commencer le jeu

---

### 💌 Invitations

#### POST `/api/invitations`

Envoie une invitation à un autre joueur.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Request:**
```json
{
  "to_user_id": 2,
  "grid_size": 5
}
```

**Response 201:**
```json
{
  "id": 1,
  "from_user_id": 1,
  "to_user_id": 2,
  "from_user": {
    "id": 1,
    "name": "John Doe",
    "avatar_url": "https://example.com/avatar.jpg"
  },
  "to_user": {
    "id": 2,
    "name": "Jane Doe",
    "avatar_url": "https://example.com/avatar2.jpg"
  },
  "status": "pending",
  "grid_size": 5,
  "created_at": "2025-11-22T10:00:00Z",
  "expires_at": "2025-11-23T10:00:00Z"
}
```

---

#### GET `/api/invitations`

Récupère toutes les invitations de l'utilisateur (reçues et envoyées).

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Response 200:**
```json
[
  {
    "id": 1,
    "from_user_id": 2,
    "to_user_id": 1,
    "from_user": {
      "id": 2,
      "name": "Jane Doe",
      "avatar_url": "https://example.com/avatar.jpg"
    },
    "to_user": {
      "id": 1,
      "name": "John Doe",
      "avatar_url": "https://example.com/avatar2.jpg"
    },
    "status": "pending",
    "grid_size": 5,
    "created_at": "2025-11-22T10:00:00Z",
    "expires_at": "2025-11-23T10:00:00Z"
  }
]
```

---

#### POST `/api/invitations/{invitation_id}/accept`

Accepte une invitation et crée une partie.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Response 200:**
```json
{
  "id": 123,
  "status": "active",
  "grid_size": 5,
  "current_player_id": 1,
  "started_at": "2025-11-22T10:00:00Z",
  "players": [
    {
      "id": 1,
      "user_id": 1,
      "user": {
        "id": 1,
        "name": "John Doe"
      },
      "score": 0,
      "position": 1
    },
    {
      "id": 2,
      "user_id": 2,
      "user": {
        "id": 2,
        "name": "Jane Doe"
      },
      "score": 0,
      "position": 2
    }
  ]
}
```

---

#### POST `/api/invitations/{invitation_id}/reject`

Rejette une invitation.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Response 200:**
```json
{
  "message": "Invitation rejetée"
}
```

---

### 🎯 Parties

#### GET `/api/games`

Récupère la liste des parties de l'utilisateur.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Query Parameters (optionnels):**
- `status`: `waiting`, `active`, `finished`
- `page`: Numéro de page (défaut: 1)
- `per_page`: Nombre de résultats par page (défaut: 20)

**Response 200:**
```json
{
  "data": [
    {
      "id": 123,
      "status": "active",
      "grid_size": 5,
      "current_player_id": 1,
      "total_segments": 10,
      "started_at": "2025-11-22T10:00:00Z",
      "players": [
        {
          "id": 1,
          "user": {
            "id": 1,
            "name": "John Doe"
          },
          "score": 5,
          "is_winner": false
        }
      ]
    }
  ],
  "current_page": 1,
  "per_page": 20,
  "total": 10
}
```

---

#### POST `/api/games`

Crée une nouvelle partie avec un adversaire spécifique.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Request:**
```json
{
  "grid_size": 5,
  "opponent_id": 2
}
```

**Response 201:**
```json
{
  "id": 123,
  "status": "waiting",
  "grid_size": 5,
  "current_player_id": 1,
  "players": [
    {
      "id": 1,
      "user_id": 1,
      "user": {
        "id": 1,
        "name": "John Doe"
      },
      "score": 0,
      "position": 1
    },
    {
      "id": 2,
      "user_id": 2,
      "user": {
        "id": 2,
        "name": "Jane Doe"
      },
      "score": 0,
      "position": 2
    }
  ]
}
```

---

#### GET `/api/games/{game_id}`

Récupère les détails d'une partie spécifique.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Response 200:**
```json
{
  "id": 123,
  "status": "active",
  "grid_size": 5,
  "board_state": {
    "0-0-0-1": 1,
    "0-1-1-1": 2
  },
  "current_player_id": 1,
  "total_segments": 10,
  "started_at": "2025-11-22T10:00:00Z",
  "players": [
    {
      "id": 1,
      "user": {
        "id": 1,
        "name": "John Doe"
      },
      "score": 5,
      "is_winner": false,
      "position": 1
    },
    {
      "id": 2,
      "user": {
        "id": 2,
        "name": "Jane Doe"
      },
      "score": 3,
      "is_winner": false,
      "position": 2
    }
  ],
  "moves": [
    {
      "id": 1,
      "user_id": 1,
      "from_row": 0,
      "from_col": 0,
      "to_row": 0,
      "to_col": 1,
      "squares_completed": 1,
      "created_at": "2025-11-22T10:01:00Z"
    }
  ]
}
```

**Champs importants:**
- `board_state`: Objet avec les segments posés (clé: `row-col-row-col`, valeur: `user_id`)
- `current_player_id`: ID du joueur dont c'est le tour
- `status`: `waiting`, `active`, `finished`

---

#### POST `/api/games/{game_id}/move`

Effectue un mouvement dans une partie.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Request:**
```json
{
  "from_row": 0,
  "from_col": 0,
  "to_row": 0,
  "to_col": 1
}
```

**Response 200:**
```json
{
  "move": {
    "id": 1,
    "game_id": 123,
    "user_id": 1,
    "from_row": 0,
    "from_col": 0,
    "to_row": 0,
    "to_col": 1,
    "squares_completed": 1,
    "created_at": "2025-11-22T10:01:00Z"
  },
  "game": {
    "id": 123,
    "status": "active",
    "current_player_id": 1,
    "board_state": {
      "0-0-0-1": 1
    },
    "players": [
      {
        "id": 1,
        "score": 5,
        "squares_completed": 1
      },
      {
        "id": 2,
        "score": 3,
        "squares_completed": 0
      }
    ],
    "is_game_over": false
  }
}
```

**Règles importantes:**
- Si `squares_completed > 0`, le joueur rejoue (ne changez pas de joueur)
- Si `squares_completed === 0`, passez au joueur suivant
- Si `is_game_over === true`, la partie est terminée

**Response 400:**
```json
{
  "error": "Ce n'est pas votre tour"
}
```

ou

```json
{
  "error": "Coup invalide"
}
```

---

### 📊 Statistiques

#### GET `/api/statistics`

Récupère les statistiques de l'utilisateur connecté.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Response 200:**
```json
{
  "games_played": 10,
  "games_won": 5,
  "games_lost": 5,
  "total_squares_completed": 42,
  "best_score": 15,
  "current_streak": 3,
  "longest_streak": 5,
  "win_rate": 50.0
}
```

---

#### GET `/api/leaderboard`

Récupère le classement global des joueurs.

**Headers:**
```
Authorization: Bearer <firebase_uid>
```

**Query Parameters (optionnels):**
- `limit`: Nombre de résultats (défaut: 50, max: 100)
- `offset`: Offset pour la pagination (défaut: 0)

**Response 200:**
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "user": {
        "id": 1,
        "name": "John Doe",
        "avatar_url": "https://example.com/avatar.jpg"
      },
      "statistic": {
        "games_played": 100,
        "games_won": 75,
        "games_lost": 25,
        "total_squares_completed": 500,
        "best_score": 20,
        "current_streak": 10,
        "longest_streak": 15,
        "win_rate": 75.0
      }
    }
  ],
  "total": 1000,
  "limit": 50,
  "offset": 0,
  "user_rank": 42
}
```

---

## 🔌 Socket.IO Events

### Connexion

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io('https://votre-domaine.com:3001', <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false,
});
```

### Authentification

**Émettre:**
```dart
socket.emit('authenticate', {
  'token': firebaseIdToken, // Token Firebase ID
});
```

**Écouter:**
```dart
socket.on('authenticated', (data) {
  print('Authentifié: ${data['userId']}');
});

socket.on('auth_error', (data) {
  print('Erreur d\'authentification: ${data['message']}');
});
```

### Rejoindre une partie

**Émettre:**
```dart
socket.emit('join_game', {
  'gameId': gameId,
});
```

**Écouter les mises à jour:**
```dart
socket.on('game-updated', (data) {
  final game = data['game'];
  // Mettre à jour l'état du jeu
});

socket.on('move-made', (data) {
  final move = data['move'];
  // Afficher le mouvement de l'adversaire
});
```

### Événements disponibles

| Événement | Direction | Description |
|-----------|-----------|-------------|
| `authenticate` | Client → Serveur | Authentifie l'utilisateur |
| `authenticated` | Serveur → Client | Confirmation d'authentification |
| `auth_error` | Serveur → Client | Erreur d'authentification |
| `join_game` | Client → Serveur | Rejoint une room de partie |
| `leave_game` | Client → Serveur | Quitte une room de partie |
| `game-updated` | Serveur → Client | Mise à jour de l'état du jeu |
| `move-made` | Serveur → Client | Un mouvement a été effectué |

---

## 📦 Modèles de données

### User

```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "firebase_uid": "abc123xyz",
  "avatar_url": "https://example.com/avatar.jpg",
  "device_type": "android",
  "device_id": "device_unique_id",
  "app_version": "1.0.0",
  "country": "FR",
  "last_active_at": "2025-11-22T10:00:00Z",
  "fcm_token": "fcm_token_from_firebase_messaging"
}
```

**Champs:**
- `fcm_token`: Token FCM pour recevoir les notifications push (peut être `null`)

### Game

```json
{
  "id": 123,
  "status": "active",
  "grid_size": 5,
  "board_state": {
    "0-0-0-1": 1,
    "0-1-1-1": 2
  },
  "current_player_id": 1,
  "total_segments": 10,
  "started_at": "2025-11-22T10:00:00Z",
  "finished_at": null
}
```

**Status:**
- `waiting`: En attente d'un adversaire
- `active`: Partie en cours
- `finished`: Partie terminée

### GamePlayer

```json
{
  "id": 1,
  "game_id": 123,
  "user_id": 1,
  "score": 5,
  "is_winner": false,
  "position": 1
}
```

### Move

```json
{
  "id": 1,
  "game_id": 123,
  "user_id": 1,
  "from_row": 0,
  "from_col": 0,
  "to_row": 0,
  "to_col": 1,
  "squares_completed": 1,
  "created_at": "2025-11-22T10:01:00Z"
}
```

### Statistic

```json
{
  "games_played": 10,
  "games_won": 5,
  "games_lost": 5,
  "total_squares_completed": 42,
  "best_score": 15,
  "current_streak": 3,
  "longest_streak": 5,
  "win_rate": 50.0
}
```

---

## ⚠️ Codes d'erreur

| Code | Signification | Description |
|------|---------------|-------------|
| 200 | OK | Requête réussie |
| 201 | Created | Ressource créée |
| 400 | Bad Request | Requête invalide |
| 401 | Unauthorized | Token manquant ou invalide |
| 403 | Forbidden | Accès refusé |
| 404 | Not Found | Ressource non trouvée |
| 429 | Too Many Requests | Limite de requêtes dépassée |
| 503 | Service Unavailable | API en maintenance |

### Exemples de réponses d'erreur

**400 Bad Request:**
```json
{
  "error": "Validation failed",
  "message": "The grid_size field is required."
}
```

**401 Unauthorized:**
```json
{
  "error": "Token invalide"
}
```

**429 Too Many Requests:**
```json
{
  "error": "Too Many Requests",
  "message": "Vous avez dépassé la limite de requêtes. Veuillez réessayer plus tard."
}
```

---

## 💡 Exemples d'intégration

### Flutter - Authentification

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<Map<String, dynamic>> login(String firebaseToken) async {
  final response = await http.post(
    Uri.parse('https://votre-domaine.com/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'token': firebaseToken}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    
    // Enregistrer le token FCM après la connexion
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await updateFCMToken(data['token'], fcmToken);
    }
    
    return data;
  } else {
    throw Exception('Échec de la connexion');
  }
}
```

### Flutter - Mise à jour du token FCM

```dart
Future<void> updateFCMToken(String authToken, String fcmToken) async {
  final response = await http.post(
    Uri.parse('https://votre-domaine.com/api/fcm/token'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    },
    body: jsonEncode({'fcm_token': fcmToken}),
  );

  if (response.statusCode != 200) {
    print('Erreur lors de la mise à jour du token FCM');
  }
}
```

### Flutter - Effectuer un mouvement

```dart
Future<Map<String, dynamic>> makeMove(
  String token,
  int gameId,
  int fromRow,
  int fromCol,
  int toRow,
  int toCol,
) async {
  final response = await http.post(
    Uri.parse('https://votre-domaine.com/api/games/$gameId/move'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'from_row': fromRow,
      'from_col': fromCol,
      'to_row': toRow,
      'to_col': toCol,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Échec du mouvement');
  }
}
```

### Flutter - Socket.IO

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GameSocketService {
  late IO.Socket socket;

  void connect(String firebaseToken) {
    socket = IO.io('https://votre-domaine.com:3001', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connecté au serveur Socket.IO');
      socket.emit('authenticate', {'token': firebaseToken});
    });

    socket.on('authenticated', (data) {
      print('Authentifié: ${data['userId']}');
    });

    socket.on('game-updated', (data) {
      // Mettre à jour l'état du jeu
      final game = data['game'];
      // ...
    });
  }

  void joinGame(int gameId) {
    socket.emit('join_game', {'gameId': gameId});
  }

  void disconnect() {
    socket.disconnect();
  }
}
```

---

## 📝 Notes importantes

1. **Base URL:** Remplacez `https://votre-domaine.com` par votre URL de production
2. **Token:** Le token Firebase expire après 1 heure, renouvelez-le régulièrement
3. **Socket.IO:** Utilisez WebSocket pour la communication temps réel
4. **Rate Limiting:** Limite de 60 requêtes par minute par utilisateur
5. **Format de date:** Toutes les dates sont au format ISO 8601 (UTC)
6. **FCM Token:** Mettez à jour le token FCM à chaque connexion et lors des changements de token
7. **Notifications:** Les notifications push sont envoyées automatiquement par le backend, configurez Firebase Messaging dans Flutter

---

**Dernière mise à jour:** 2025-11-22  
**Version API:** 1.0.0

