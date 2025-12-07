# 🐛 Guide de Débogage API

## 🔍 Problèmes identifiés et corrections

### 1. URL de l'API

**Configuration actuelle :**
```dart
baseUrl = 'https://api.cdn-aboapp.online/api'
```

**Si l'API retourne 404, essayez :**
```dart
baseUrl = 'https://api.cdn-aboapp.online'  // Sans /api
```

### 2. Logs de débogage ajoutés

Tous les appels API affichent maintenant des logs dans la console :
- 🔐 Tentative de connexion
- 📡 Réponse du serveur
- ✅ Succès
- ❌ Erreurs
- ⚠️ Avertissements (non bloquants)

### 3. Gestion des erreurs FCM

Le token FCM ne bloque plus la connexion si l'endpoint n'existe pas (404). C'est maintenant non-bloquant.

## 📋 Vérifications à faire

### 1. Vérifier l'URL de l'API

Testez manuellement dans un navigateur ou avec curl :

```bash
# Test de l'endpoint de login (sans token)
curl -X POST https://api.cdn-aboapp.online/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"token":"test"}'

# Ou sans /api
curl -X POST https://api.cdn-aboapp.online/auth/login \
  -H "Content-Type: application/json" \
  -d '{"token":"test"}'
```

### 2. Vérifier les logs dans l'app

Lorsque vous essayez de vous connecter, regardez les logs dans :
- Android Studio / VS Code console
- `flutter run` output

Vous devriez voir :
```
🔐 Tentative de connexion: https://api.cdn-aboapp.online/api/auth/login
📡 Réponse login: 200 - {...}
✅ Connexion réussie pour: Nom Utilisateur
```

### 3. Vérifier l'endpoint FCM

Si vous voyez `404` pour FCM, c'est normal si l'endpoint n'existe pas encore. L'app continuera de fonctionner.

## 🔧 Corrections appliquées

1. ✅ URL de base corrigée (ajout de `/api`)
2. ✅ Logs de débogage ajoutés partout
3. ✅ Gestion d'erreurs améliorée
4. ✅ FCM ne bloque plus la connexion
5. ✅ Messages d'erreur affichés dans l'UI

## 🚀 Prochaines étapes

1. **Tester la connexion** et regarder les logs
2. **Vérifier l'URL** si vous voyez des 404
3. **Ajuster `config.dart`** si nécessaire selon votre configuration backend

