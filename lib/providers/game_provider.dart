import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import '../services/audio_controller.dart';

/// Provider pour gérer l'état du jeu en temps réel
class GameProvider with ChangeNotifier {
  final SocketService _socketService = SocketService(); // Singleton
  
  Game? _currentGame;
  bool _isLoading = false;
  String? _error;
  bool _isMyTurn = false;
  int? _currentUserId;
  bool _isInRoom = false;
  
  // Timer - toujours actif pour les 2 joueurs
  Timer? _turnTimer;
  static const int timerDuration = 30; // Réduit à 30s pour plus de dynamisme
  int _remainingSeconds = timerDuration;
  bool _isTimerRunning = false;

  // Getters
  Game? get currentGame => _currentGame;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isMyTurn => _isMyTurn;
  int get remainingSeconds => _remainingSeconds;
  bool get isTimerRunning => _isTimerRunning;
  int? get currentUserId => _currentUserId;

  GameProvider() {
    _initializeSocketListeners();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await StorageService.getUserId();
    debugPrint('👤 [GAME] User ID chargé: $_currentUserId');
  }

  void _initializeSocketListeners() {
    debugPrint('🔧 [GAME] Configuration des listeners Socket.IO');
    
    // Quand authentifié, rejoindre la room si nécessaire
    _socketService.onAuthenticated = () {
      debugPrint('🔄 [GAME] Socket authentifié');
      if (_currentGame != null && !_isInRoom) {
        _socketService.joinGame(_currentGame!.id);
      }
    };

    // Mise à jour du jeu
    _socketService.onGameUpdated = (Game game) {
      if (_currentGame?.id == game.id) {
        debugPrint('📥 [GAME] game-updated reçu pour ${game.id}, status: ${game.status}');
        _handleGameUpdate(game);
      }
    };

    // Coup effectué - utiliser directement les données reçues
    _socketService.onMoveMade = (Map<String, dynamic> data) {
      if (_currentGame != null && data['game'] != null) {
        debugPrint('📥 [GAME] move-made reçu - mise à jour directe');
        try {
          final gameData = data['game'] as Map<String, dynamic>;
          final game = Game.fromJson(gameData);
          if (game.id == _currentGame!.id) {
            _handleGameUpdate(game);
            // Réinitialiser le timer après un coup (synchronisation)
            if (game.status == 'active') {
              _resetTimer();
            }
          }
        } catch (e) {
          debugPrint('❌ [GAME] Erreur parsing move-made: $e');
          _reloadGameFromApi();
        }
      }
    };

    // Partie terminée
    _socketService.onGameFinished = (Game game) {
      if (_currentGame?.id == game.id) {
        debugPrint('🏁 [GAME] game-finished reçu pour ${game.id}');
        _handleGameFinished(game);
      }
    };

    // Adversaire rejoint
    _socketService.onOpponentJoined = (Game game) {
      if (_currentGame?.id == game.id) {
        debugPrint('👥 [GAME] opponent-joined reçu pour ${game.id}');
        _reloadGameFromApi();
      }
    };

    // Erreurs
    _socketService.onError = (String error) {
      debugPrint('❌ [GAME] Erreur Socket: $error');
      _error = error;
      notifyListeners();
    };
  }

  void _handleGameUpdate(Game game) {
    final wasWaiting = _currentGame?.status == 'waiting';
    final previousPlayerId = _currentGame?.currentPlayerId;
    final previousStatus = _currentGame?.status;
    final wasFinished = _currentGame?.status == 'finished';
    
    // PROTECTION : Si la partie était déjà terminée, ignorer TOUTES les mises à jour
    // Cela évite que des événements Socket.IO tardifs déclenchent des rebuilds inutiles
    if (wasFinished) {
      debugPrint('⚠️ [GAME] Mise à jour ignorée - partie déjà terminée (status: ${game.status})');
      return; // Ne pas notifier les listeners pour éviter les rebuilds
    }
    
    _currentGame = game;
    _updateTurnStatus();
    
    // Jouer le son de clic si l'adversaire a joué (tour changé et ce n'est pas mon tour)
    if (previousPlayerId != null && 
        previousPlayerId != game.currentPlayerId && 
        game.currentPlayerId != _currentUserId &&
        game.status == 'active') {
      AudioController.playClickSound();
      debugPrint('🔊 [GAME] Son de clic joué - adversaire a joué');
    }
    
    if (wasWaiting && game.status == 'active') {
      debugPrint('🎮 [GAME] Partie démarrée!');
      _startTurnTimer(); // Démarrer le timer pour les 2 joueurs
      _reloadGameFromApi();
    } else if (game.status == 'finished' && !wasFinished) {
      // Seulement si la partie vient de se terminer (pas déjà terminée)
      _handleGameFinished(game);
    } else if (game.status == 'active') {
      // Synchroniser le timer avec le serveur
      if (game.remainingSeconds != null) {
        _remainingSeconds = game.remainingSeconds!;
      }
      
      // Réinitialiser le timer quand le tour change OU quand on reçoit une mise à jour du serveur
      // Cela synchronise le timer entre les joueurs
      if (previousPlayerId != game.currentPlayerId || previousStatus != 'active') {
        // Le tour a changé - réinitialiser complètement le timer
        _resetTimer();
        debugPrint('🔄 [GAME] Timer réinitialisé - tour changé ou partie reprise');
      } else {
        // Le tour n'a pas changé mais on reçoit une mise à jour - synchroniser le timer
        // Si le timer n'est pas en cours, le démarrer
        if (!_isTimerRunning) {
          _startTurnTimer();
        } else {
          // Le timer est déjà en cours, juste mettre à jour la valeur
          notifyListeners();
        }
      }
    }
  }

  void _handleGameFinished(Game game) {
    // Éviter les appels multiples - vérification plus stricte
    if (_currentGame != null && 
        _currentGame!.status == 'finished' && 
        _currentGame!.id == game.id) {
      debugPrint('⚠️ [GAME] _handleGameFinished déjà appelé pour cette partie ${game.id}');
      return;
    }
    
    // Protection supplémentaire : si on reçoit un événement pour une partie différente
    // de celle actuellement chargée, l'ignorer
    if (_currentGame != null && _currentGame!.id != game.id) {
      debugPrint('⚠️ [GAME] _handleGameFinished ignoré - ID différent (actuel: ${_currentGame!.id}, reçu: ${game.id})');
      return;
    }
    
    debugPrint('🏁 [GAME] Partie terminée: ${game.id}');
    _currentGame = game;
    _stopTurnTimer();
    _updateTurnStatus();
    
    // Notifier UNE SEULE FOIS après avoir mis à jour l'état
    notifyListeners();
  }

  Future<void> _reloadGameFromApi() async {
    if (_currentGame == null) return;
    
    try {
      final previousPlayerId = _currentGame?.currentPlayerId;
      final game = await ApiService.getGame(_currentGame!.id);
      _currentGame = game;
      _updateTurnStatus();
      
      // Démarrer ou réinitialiser le timer si la partie est active
      if (game.status == 'active') {
        // Synchroniser avec le temps serveur
        if (game.remainingSeconds != null) {
          _remainingSeconds = game.remainingSeconds!;
        }
        
        // Si le tour a changé, réinitialiser le timer
        if (previousPlayerId != null && previousPlayerId != game.currentPlayerId) {
          _resetTimer();
        } else if (!_isTimerRunning) {
          // Si le timer n'est pas en cours, le démarrer
          _startTurnTimer();
        } else {
          // Mettre à jour le timer même s'il est déjà en cours
          notifyListeners();
        }
      } else {
        // Si la partie n'est plus active, arrêter le timer
        _stopTurnTimer();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [GAME] Erreur rechargement: $e');
    }
  }

  void _updateTurnStatus() {
    if (_currentGame == null || _currentUserId == null) {
      _isMyTurn = false;
      return;
    }
    
    _isMyTurn = _currentGame!.currentPlayerId == _currentUserId;
    debugPrint('🔄 [GAME] Tour: currentPlayerId=${_currentGame!.currentPlayerId}, myUserId=$_currentUserId, isMyTurn=$_isMyTurn');
  }

  /// Démarre le timer - synchronisé avec le serveur
  /// Le timer est visible pour tous les joueurs et se synchronise depuis le serveur
  void _startTurnTimer() {
    _stopTurnTimer();
    _isTimerRunning = true;
    _updateTurnStatus(); // Mettre à jour le statut du tour
    
    // Initialiser avec la valeur du serveur si disponible
    if (_currentGame?.remainingSeconds != null) {
      _remainingSeconds = _currentGame!.remainingSeconds!;
    } else {
      _remainingSeconds = timerDuration;
    }
    
    debugPrint('⏱️ [GAME] Timer démarré (${_remainingSeconds}s) - isMyTurn=$_isMyTurn, currentPlayerId=${_currentGame?.currentPlayerId}');
    
    // Timer local qui décrémente chaque seconde
    // Synchronisation avec le serveur toutes les 5 secondes pour éviter la surcharge
    int syncCounter = 0;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_currentGame == null || _currentGame!.status != 'active') {
        _stopTurnTimer();
        return;
      }
      
      // Décrémenter localement chaque seconde
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else if (_isMyTurn) {
        // Timer expiré - passer le tour automatiquement
        _onTimerExpired();
        return;
      }
      
      // Synchroniser avec le serveur toutes les 5 secondes
      syncCounter++;
      if (syncCounter >= 5) {
        syncCounter = 0;
        try {
          final game = await ApiService.getGame(_currentGame!.id);
          if (game.remainingSeconds != null) {
            // Synchroniser avec le serveur (corriger la dérive)
            _remainingSeconds = game.remainingSeconds!;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('⚠️ [GAME] Erreur synchronisation timer: $e');
          // En cas d'erreur, continuer avec le timer local
        }
      }
    });
    
    notifyListeners();
  }

  /// Réinitialise le timer (quand le tour change)
  /// Utilise la valeur du serveur si disponible
  void _resetTimer() {
    _updateTurnStatus(); // Mettre à jour le statut du tour
    
    // Utiliser la valeur du serveur si disponible
    if (_currentGame?.remainingSeconds != null) {
      _remainingSeconds = _currentGame!.remainingSeconds!;
    } else {
      _remainingSeconds = timerDuration;
    }
    
    // Redémarrer le timer si ce n'est pas déjà en cours
    if (!_isTimerRunning) {
      _startTurnTimer();
    } else {
      // Le timer est déjà en cours, juste mettre à jour le compteur
      notifyListeners();
    }
    
    debugPrint('🔄 [GAME] Timer réinitialisé (${_remainingSeconds}s) - isMyTurn=$_isMyTurn');
  }

  void _stopTurnTimer() {
    if (_turnTimer != null) {
      _turnTimer!.cancel();
      _turnTimer = null;
      _isTimerRunning = false;
    }
  }

  void _onTimerExpired() async {
    debugPrint('⏰ [GAME] Timer expiré - passage automatique du tour à l\'adversaire');
    
    // Vérifier que c'est bien mon tour (sinon le timer ne devrait pas expirer)
    if (!_isMyTurn || _currentGame == null) {
      _stopTurnTimer();
      return;
    }
    
    // Passer le tour automatiquement à l'adversaire
    await _skipTurn();
  }
  
  /// Passe le tour automatiquement à l'adversaire (quand le timer expire)
  Future<void> _skipTurn() async {
    if (_currentGame == null) return;
    
    // Arrêter le timer pendant l'appel API
    _stopTurnTimer();
    
    try {
      debugPrint('🔄 [GAME] Passage automatique du tour à l\'adversaire...');
      
      // Appeler l'API pour passer le tour
      final result = await ApiService.skipTurn(_currentGame!.id);
      
      if (result['game'] != null) {
        final game = Game.fromJson(result['game'] as Map<String, dynamic>);
        _handleGameUpdate(game);
        debugPrint('✅ [GAME] Tour passé automatiquement à l\'adversaire');
        
        // Le timer sera réinitialisé automatiquement dans _handleGameUpdate
        // car le currentPlayerId a changé
      }
    } catch (e) {
      debugPrint('❌ [GAME] Erreur lors du passage automatique du tour: $e');
      // En cas d'erreur, recharger le jeu depuis l'API
      _reloadGameFromApi();
    }
  }

  /// Charge une partie et rejoint la room Socket.IO
  Future<void> loadGame(int gameId) async {
    debugPrint('📂 [GAME] Chargement de la partie $gameId...');
    
    // PROTECTION : Si on charge une partie différente de celle actuellement chargée,
    // s'assurer qu'on quitte d'abord l'ancienne room Socket.IO et qu'on nettoie l'état
    if (_currentGame != null && _currentGame!.id != gameId) {
      debugPrint('🔄 [GAME] Changement de partie: ${_currentGame!.id} -> $gameId. Nettoyage de l\'ancienne partie.');
      _stopTurnTimer();
      _socketService.leaveGame(_currentGame!.id);
    }
    
    _isLoading = true;
    _error = null;
    _isInRoom = false;
    notifyListeners();

    try {
      // Charger l'ID utilisateur
      await _loadCurrentUserId();
      
      // Charger le jeu depuis l'API
      final loadedGame = await ApiService.getGame(gameId);
      debugPrint('✅ [GAME] Partie chargée: status=${loadedGame.status}, players=${loadedGame.players.length}');
      
      // PROTECTION : Si la partie est terminée et qu'on vient de la charger,
      // on la charge quand même mais on ne rejoint pas la room Socket.IO
      // (car elle est déjà terminée)
      _currentGame = loadedGame;
      
      // Connecter et rejoindre la room Socket.IO seulement si la partie n'est pas terminée
      // (pour les parties terminées, pas besoin de rejoindre la room)
      if (loadedGame.status != 'finished') {
        await _socketService.connect();
        await _socketService.joinGame(gameId);
        _isInRoom = true;
      } else {
        debugPrint('⚠️ [GAME] Partie terminée, pas de connexion Socket.IO nécessaire');
      }
      
      _updateTurnStatus();
      
      // Démarrer le timer si la partie est active (pour les 2 joueurs)
      if (_currentGame?.status == 'active') {
        _startTurnTimer();
      }
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [GAME] Erreur: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Effectue un mouvement
  Future<bool> makeMove(int fromRow, int fromCol, int toRow, int toCol) async {
    if (_currentGame == null) return false;
    if (!_isMyTurn) {
      debugPrint('⚠️ [GAME] Ce n\'est pas mon tour');
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🎯 [GAME] Coup: ($fromRow,$fromCol) -> ($toRow,$toCol)');
      
      final result = await ApiService.makeMove(
        _currentGame!.id,
        fromRow,
        fromCol,
        toRow,
        toCol,
      );

      _currentGame = result['game'] as Game;
      _updateTurnStatus();
      
      debugPrint('✅ [GAME] Coup effectué, status=${_currentGame!.status}');
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [GAME] Erreur coup: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Abandonne la partie
  Future<bool> forfeitGame() async {
    if (_currentGame == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🏳️ [GAME] Abandon de la partie ${_currentGame!.id}');
      
      final result = await ApiService.forfeitGame(_currentGame!.id);
      _stopTurnTimer();
      
      // Recharger le jeu pour avoir l'état final
      await _reloadGameFromApi();
      debugPrint('✅ [GAME] Partie abandonnée, status=${_currentGame?.status}');
      
      _updateTurnStatus();
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [GAME] Erreur abandon: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Quitte la partie (sans abandonner) - Nettoie complètement l'état
  void leaveGame() {
    debugPrint('🚪 [GAME] Quitter la partie - nettoyage complet');
    
    // Arrêter le timer
    _stopTurnTimer();
    
    // Quitter la room Socket.IO
    if (_currentGame != null) {
      _socketService.leaveGame(_currentGame!.id);
    }
    
    // Nettoyer complètement l'état
    _currentGame = null;
    _isMyTurn = false;
    _isInRoom = false;
    _error = null;
    _isLoading = false;
    _remainingSeconds = timerDuration;
    _isTimerRunning = false;
    
    debugPrint('✅ [GAME] État nettoyé complètement');
    
    // Notifier immédiatement (synchrone) pour que le nettoyage soit visible tout de suite
    notifyListeners();
  }

  /// Nettoie et réinitialise l'état du provider avant de commencer une NOUVELLE partie
  /// Cette méthode doit être appelée avant de lancer une nouvelle recherche de partie
  void resetStateForNewGame() {
    debugPrint('✨ [GAME] Réinitialisation de l\'état pour un nouveau jeu.');
    
    // Assurez-vous d'arrêter tout ce qui tourne
    _stopTurnTimer();
    
    // Quitter la room Socket.IO de l'ancienne partie si elle existe
    if (_currentGame != null) {
      _socketService.leaveGame(_currentGame!.id);
    }
    
    // Nettoyer tous les champs d'état
    _currentGame = null;
    _isMyTurn = false;
    _isInRoom = false;
    _error = null;
    _isLoading = false;
    _remainingSeconds = timerDuration;
    _isTimerRunning = false;

    // Notifier immédiatement les auditeurs.
    // Cela garantit que toute UI persistante (comme l'écran d'accueil) voit un état propre.
    notifyListeners();
    
    debugPrint('✅ [GAME] État réinitialisé pour nouveau jeu');
  }

  @override
  void dispose() {
    _stopTurnTimer();
    super.dispose();
  }
}
