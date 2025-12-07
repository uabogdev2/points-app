# 🔔 Vérification des Notifications FCM

## ✅ Points vérifiés

### 1. Configuration Firebase Messaging
- ✅ Firebase Messaging initialisé dans `main.dart`
- ✅ Handler de notifications en arrière-plan configuré
- ✅ Écoute des notifications en foreground
- ✅ Écoute des notifications qui ouvrent l'app
- ✅ Permissions demandées (iOS)

### 2. Mise à jour du token FCM

Le token FCM est mis à jour automatiquement dans les cas suivants :

1. **Au démarrage de l'app** (si l'utilisateur est déjà connecté)
   - Fichier : `lib/providers/auth_provider.dart` → `initialize()`
   - Ligne : 36

2. **Après la connexion Google**
   - Fichier : `lib/providers/auth_provider.dart` → `signInWithGoogle()`
   - Ligne : 84

3. **Après la connexion Apple**
   - Fichier : `lib/providers/auth_provider.dart` → `signInWithApple()`
   - Ligne : 113

4. **Lors du rafraîchissement du token FCM**
   - Fichier : `lib/services/notification_service.dart` → `_onTokenRefresh()`
   - Ligne : 160
   - Se déclenche automatiquement quand Firebase rafraîchit le token

### 3. Logs de débogage

Les logs suivants sont disponibles pour vérifier le fonctionnement :

```
🔄 Vérification du token FCM...
📱 Token FCM obtenu: [premiers 20 caractères]...
📱 Mise à jour token FCM: [URL]
📱 Headers: Authorization présent
📡 Réponse FCM token: [status code] - [body]
✅ Token FCM mis à jour avec succès
```

### 4. Gestion des erreurs

- Les erreurs de mise à jour du token FCM ne bloquent pas l'app
- Les logs détaillés permettent de diagnostiquer les problèmes
- Le token est mis à jour silencieusement en arrière-plan

## 🔍 Comment vérifier que le token est à jour

### Depuis l'app Flutter

1. **Vérifier les logs** :
   - Ouvrez la console Flutter
   - Connectez-vous à l'app
   - Cherchez les logs : `✅ Token FCM mis à jour avec succès`

2. **Forcer la mise à jour** :
   - Le token est automatiquement mis à jour après chaque connexion
   - Le token est automatiquement mis à jour lors du rafraîchissement

### Depuis le dashboard

1. **Vérifier le token dans la base de données** :
   - Allez dans **Utilisateurs** dans Filament
   - Ouvrez un utilisateur
   - Vérifiez le champ **Token FCM**
   - Le token doit être présent et récent

2. **Tester avec un token** :
   - Copiez le token FCM depuis un utilisateur
   - Allez dans **Configuration > Configuration FCM**
   - Collez le token dans "Token FCM de test"
   - Cliquez sur "Tester la notification"

## ⚠️ Problèmes courants

### 1. Token non mis à jour

**Symptômes** :
- Le token FCM dans la base de données est vide ou ancien
- Les notifications ne sont pas reçues

**Solutions** :
1. Vérifiez les logs de l'app pour voir si la mise à jour échoue
2. Reconnectez-vous à l'app pour forcer la mise à jour
3. Vérifiez que l'utilisateur est bien authentifié (token présent)

### 2. "Requested entity was not found"

**Symptômes** :
- Erreur lors du test de notification
- Le token utilisé est invalide ou expiré

**Solutions** :
1. Utilisez un token FCM récent depuis un utilisateur connecté
2. Reconnectez-vous à l'app pour obtenir un nouveau token
3. Vérifiez que le token n'a pas été supprimé (déconnexion)

### 3. Notifications envoyées mais non reçues

**Symptômes** :
- Les logs indiquent `"success":1` mais la notification n'arrive pas

**Solutions** :
1. Vérifiez que l'app est ouverte ou en arrière-plan
2. Vérifiez les permissions de notification dans les paramètres de l'appareil
3. Vérifiez les logs de l'app Flutter pour voir si la notification est reçue
4. Vérifiez que le token FCM dans la base de données est à jour

## 📝 Checklist de vérification

- [ ] Firebase Messaging est initialisé dans `main.dart`
- [ ] Les permissions de notification sont demandées
- [ ] Le token FCM est mis à jour après la connexion
- [ ] Le token FCM est mis à jour au démarrage si l'utilisateur est connecté
- [ ] Le token FCM est mis à jour lors du rafraîchissement
- [ ] Le token FCM est supprimé lors de la déconnexion
- [ ] Les logs montrent que le token est bien mis à jour
- [ ] Le token FCM est présent dans la base de données pour les utilisateurs connectés

## 🚀 Test rapide

1. **Connectez-vous à l'app Flutter**
2. **Vérifiez les logs** : Vous devriez voir `✅ Token FCM mis à jour avec succès`
3. **Vérifiez dans le dashboard** : Le token FCM doit être présent dans la table `users`
4. **Testez une notification** : Utilisez le token FCM pour tester depuis le dashboard

