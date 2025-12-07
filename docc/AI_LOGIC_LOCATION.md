# 📍 Localisation de la Logique de l'IA

## 🎯 Fichiers Principaux

### 1. **Service de l'IA** - `lib/services/ai_service.dart`
**C'est ici que se trouve TOUTE la logique de réflexion de l'IA.**

#### Structure du fichier :
- **Ligne 11-31** : Classe `AIService` avec les paramètres de difficulté
  - `_maxDepthEasy = 2` : Profondeur de recherche pour débutant
  - `_maxDepthMedium = 3` : Profondeur de recherche pour moyen
  - `_maxDepthHard = 4` : Profondeur de recherche pour expert
  - `_maxTimeMs = 15000` : Temps maximum de réflexion (15 secondes)
  - `_maxMovesToEvaluate = 15` : Maximum de mouvements à évaluer

- **Ligne 35-61** : `getBestMove()` - **Point d'entrée principal**
  - Méthode principale appelée pour obtenir le meilleur mouvement
  - Gère les erreurs et retourne un mouvement aléatoire en cas d'échec

- **Ligne 92-145** : `_getEasyMove()` - **Mode Débutant**
  - Logique simple : évite de donner des carrés gratuits
  - Si aucun mouvement sûr, choisit aléatoirement
  - Limite : analyse maximum 15 mouvements

- **Ligne 147-223** : `_getMediumMove()` - **Mode Moyen**
  - Priorité 1 : Compléter un carré (rejouer)
  - Priorité 2 : Éviter de donner des carrés à l'adversaire
  - Priorité 3 : Créer des menaces
  - Limite : analyse maximum 15 mouvements

- **Ligne 225-322** : `_getHardMove()` - **Mode Expert**
  - Utilise l'algorithme Minimax avec Alpha-Beta Pruning
  - Priorité 1 : Compléter un carré
  - Priorité 2 : Éviter de donner des carrés
  - Priorité 3 : Minimax pour trouver le meilleur mouvement
  - Limite : profondeur 4, maximum 15 mouvements évalués

- **Ligne 352-450** : `_minimaxWithTimeout()` - **Algorithme Minimax**
  - Algorithme récursif pour évaluer les positions futures
  - Vérifie le timeout à chaque itération
  - Limite la profondeur pour éviter les plantages
  - Protection contre les récursions infinies

- **Ligne 456-493** : `_evaluatePositionAdvanced()` - **Évaluation de position**
  - Calcule un score pour une position donnée
  - Prend en compte : carrés complétés, menaces, carrés dangereux

### 2. **Provider du Jeu Solo** - `lib/providers/solo_game_provider.dart`
**C'est ici que l'IA est appelée et que ses mouvements sont exécutés.**

- **Ligne 202-320** : `_makeAIMove()` - **Méthode qui appelle l'IA**
  - Démarre le timer de l'IA
  - Appelle `_aiService!.getBestMove()` avec timeout de 15 secondes
  - Gère les erreurs et utilise un fallback si nécessaire
  - Attend minimum 7 secondes pour simuler la réflexion

- **Ligne 13** : `AIService? _aiService` - Instance du service IA
- **Ligne 14** : `AIDifficulty _difficulty` - Difficulté actuelle

## 🔄 Flux d'Exécution

1. **Démarrage du tour de l'IA** :
   - `solo_game_provider.dart` ligne 202 : `_makeAIMove()` est appelée
   - Timer démarré ligne 207

2. **Appel de l'IA** :
   - `solo_game_provider.dart` ligne 230 : `_aiService!.getBestMove(_currentGame!, _aiPlayerId)`
   - Timeout de 15 secondes ligne 243

3. **Réflexion de l'IA** :
   - `ai_service.dart` ligne 35 : `getBestMove()` est exécutée
   - Selon la difficulté, appelle :
     - `_getEasyMove()` (ligne 47) pour débutant
     - `_getMediumMove()` (ligne 49) pour moyen
     - `_getHardMove()` (ligne 51) pour expert

4. **Calcul du mouvement** :
   - Mode Facile/Moyen : Analyse simple des mouvements
   - Mode Expert : Minimax avec profondeur limitée (ligne 352)

5. **Retour du mouvement** :
   - Le mouvement est retourné à `solo_game_provider.dart`
   - Exécuté ligne 272-320

## 🛡️ Protections Anti-Plantage

1. **Limites strictes** :
   - Profondeur maximale : 2-4 selon difficulté
   - Temps maximum : 15 secondes
   - Mouvements évalués : maximum 15

2. **Gestion d'erreurs** :
   - Try-catch dans toutes les méthodes
   - Fallback vers mouvement aléatoire en cas d'erreur
   - Vérifications de null partout

3. **Timeouts** :
   - Timeout global de 15 secondes
   - Vérification du temps dans minimax à chaque itération

4. **Limitation de récursion** :
   - Protection contre profondeurs trop grandes
   - Limite du nombre de mouvements évalués

## 📝 Notes Importantes

- **Toute la logique de réflexion** se trouve dans `ai_service.dart`
- **L'appel et l'exécution** se font dans `solo_game_provider.dart`
- Les **paramètres de difficulté** sont définis ligne 17-20 de `ai_service.dart`
- Pour modifier la difficulté, changer les constantes `_maxDepthEasy`, `_maxDepthMedium`, `_maxDepthHard`

