import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

/// Provider simplifié pour le matchmaking
/// Logique propre : API uniquement, Socket.IO pour les notifications uniquement
class MatchmakingProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  
  // État simple
  bool _isSearching = false;
  Game? _waitingGame;
  String? _error;
  int? _currentGridSize;

  // Getters
  bool get isSearching => _isSearching;
  Game? get waitingGame => _waitingGame;
  String? get error => _error;

  MatchmakingProvider() {
    _setupSocketListeners();
  }

  /// Configure les listeners Socket.IO pour les notifications uniquement
  void _setupSocketListeners() {
    // Notification quand un adversaire rejoint
    _socketService.onOpponentJoined = (Game game) {
      if (_waitingGame?.id == game.id) {
        debugPrint('✅ [MATCHMAKING] Adversaire rejoint via Socket.IO - Game ID: ${game.id}, Status: ${game.status}');
        _waitingGame = game;
        if (game.status == 'active') {
          _isSearching = false;
          debugPrint('🎮 [MATCHMAKING] Partie active - matchmaking terminé');
        }
        notifyListeners();
      } else {
        debugPrint('⚠️ [MATCHMAKING] Notification reçue pour une autre partie (attendu: ${_waitingGame?.id}, reçu: ${game.id})');
      }
    };

    // Notification game-started (alternative à opponent-joined)
    _socketService.onGameUpdated = (Game game) {
      if (_waitingGame?.id == game.id && game.status == 'active') {
        debugPrint('✅ [MATCHMAKING] Partie démarrée via game-updated - Game ID: ${game.id}');
        _waitingGame = game;
        _isSearching = false;
        notifyListeners();
      }
    };

    // Notification d'erreur
    _socketService.onError = (String error) {
      debugPrint('❌ [MATCHMAKING] Erreur Socket.IO: $error');
      _error = error;
      notifyListeners();
    };
  }

  /// Recherche une partie - LOGIQUE SIMPLE ET PROPRE
  /// 1. Appeler l'API pour trouver ou créer une partie
  /// 2. Si matched = true, la partie est active
  /// 3. Si matched = false, attendre qu'un adversaire rejoigne (via Socket.IO ou polling)
  Future<Game?> findMatch(int gridSize) async {
    debugPrint('🔍 [MATCHMAKING] Début recherche - GridSize: $gridSize');
    
    // Nettoyer l'état précédent
    _error = null;
    _waitingGame = null;
    _currentGridSize = gridSize;
    _isSearching = true;
    notifyListeners();

    try {
      // S'assurer que Socket.IO est connecté (pour les notifications)
      // Connexion non-bloquante pour ne pas ralentir la recherche
      if (!_socketService.isConnected) {
        debugPrint('🔌 [MATCHMAKING] Connexion Socket.IO...');
        _socketService.connect().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('⚠️ [MATCHMAKING] Timeout connexion Socket.IO, continue quand même');
          },
        );
      }

      // Appeler l'API pour trouver ou créer une partie
      debugPrint('📡 [MATCHMAKING] Appel API findMatch...');
      final result = await ApiService.findMatch(gridSize);
      
      final game = result['game'] as Game;
      final matched = result['matched'] as bool;
      
      debugPrint('✅ [MATCHMAKING] Réponse API - Game ID: ${game.id}, Status: ${game.status}, Matched: $matched');

      _waitingGame = game;

      // Rejoindre la room Socket.IO immédiatement pour recevoir les notifications
      // Même si pas encore connecté, la connexion se fera en arrière-plan
      _socketService.joinGame(game.id);
      debugPrint('📤 [MATCHMAKING] Rejoint la room Socket.IO pour la partie ${game.id}');

      if (matched) {
        // Adversaire trouvé immédiatement, partie active
        debugPrint('🎉 [MATCHMAKING] Adversaire trouvé! Partie active.');
        _isSearching = false;
        notifyListeners();
        return game;
      } else {
        // En attente d'un adversaire
        debugPrint('⏳ [MATCHMAKING] En attente d\'un adversaire...');
        _isSearching = true;
        notifyListeners();
        return null; // La partie sera notifiée via Socket.IO quand un adversaire rejoint
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [MATCHMAKING] Erreur: $e');
      debugPrint('❌ [MATCHMAKING] Stack: $stackTrace');
      _error = e.toString();
      _isSearching = false;
      _waitingGame = null;
      notifyListeners();
      return null;
    }
  }

  /// Annule la recherche - NETTOYAGE PROPRE
  void cancelSearch() {
    debugPrint('🚫 [MATCHMAKING] Annulation recherche');
    _isSearching = false;
    _waitingGame = null;
    _error = null;
    _currentGridSize = null;
    notifyListeners();
  }

  /// Met à jour la partie en attente (appelé depuis l'extérieur, ex: polling)
  void updateWaitingGame(Game game) {
    if (_waitingGame?.id == game.id) {
      _waitingGame = game;
      if (game.status == 'active') {
        _isSearching = false;
      }
      notifyListeners();
    }
  }
}
