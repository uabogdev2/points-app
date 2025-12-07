import 'dart:async';
import 'dart:math';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/services.dart';
import '../utils/config.dart';
import '../models/game.dart';
import 'storage_service.dart';

/// Service Socket.IO Singleton pour la communication temps réel
/// OPTIMISÉ POUR COMPÉTITION - Ultra réactif pour tous les appareils
class SocketService {
  // Singleton
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  bool _isConnecting = false;
  int _currentGameId = 0;
  
  // Heartbeat pour maintenir la connexion active (important pour iOS)
  Timer? _heartbeatTimer;
  DateTime? _lastPongReceived;
  static const Duration _heartbeatInterval = Duration(seconds: 15); // Ping toutes les 15s
  static const Duration _heartbeatTimeout = Duration(seconds: 30); // Timeout après 30s sans pong

  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;

  // Callbacks
  Function(Game)? onGameUpdated;
  Function(Map<String, dynamic>)? onMoveMade;
  Function(String)? onError;
  Function(Game)? onMatchFound;
  Function(Game)? onOpponentJoined;
  Function(Game)? onGameFinished;
  Function()? onAuthenticated;

  /// Connecte au serveur Socket.IO et authentifie
  Future<void> connect() async {
    if (_isConnecting) {
      debugPrint('⏳ [SOCKET] Connexion déjà en cours...');
      return;
    }
    
    if (_socket != null && _isConnected && _isAuthenticated) {
      debugPrint('✅ [SOCKET] Déjà connecté et authentifié');
      return;
    }

    _isConnecting = true;
    debugPrint('🔌 [SOCKET] Connexion à ${ApiConfig.socketUrl}...');

    try {
      // Déconnecter l'ancienne socket si elle existe
      if (_socket != null) {
        _socket!.dispose();
        _socket = null;
      }

      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            // OPTIMISATION ULTRA-RAPIDE : transports intelligents
            // iOS : websocket peut être mis en pause, polling comme fallback immédiat
            // Android : websocket prioritaire pour latence minimale
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(15) // Plus de tentatives pour stabilité
            .setReconnectionDelay(300) // Reconnexion ultra-rapide (300ms)
            .setReconnectionDelayMax(3000) // Max 3s avec exponential backoff + jitter
            // SÉCURITÉ : Exponential backoff avec jitter pour éviter les tempêtes de reconnexion
            // Si le serveur tombe, les reconnexions sont espacées progressivement (300ms → 3s)
            // Le jitter aléatoire évite que tous les clients se reconnectent simultanément
            .setTimeout(3000) // Timeout ultra-court : 3s (au lieu de 5s)
            // OPTIMISATIONS PERFORMANCE
            // L'upgrade automatique de polling vers websocket est géré par défaut par Socket.IO
            .build(),
      );

      _setupListeners();
      _socket!.connect();
      
      // Attendre la connexion
      await _waitForConnection();
      
    } catch (e) {
      debugPrint('❌ [SOCKET] Erreur de connexion: $e');
      _isConnecting = false;
      onError?.call('Erreur de connexion Socket.IO: $e');
    }
  }

  Future<void> _waitForConnection() async {
    // Timeout ultra-court : 2 secondes max pour compétition
    for (int i = 0; i < 20; i++) { // Max 2 secondes (20 * 100ms)
      if (_isAuthenticated) {
        _isConnecting = false;
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _isConnecting = false;
    if (!_isAuthenticated) {
      debugPrint('⚠️ [SOCKET] Timeout en attendant l\'authentification (non bloquant)');
      // Ne pas bloquer - la connexion peut se faire en arrière-plan
    }
  }

  void _setupListeners() {
    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('✅ [SOCKET] Connecté au serveur');
      _authenticate();
      _startHeartbeat(); // Démarrer le heartbeat pour maintenir la connexion
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ [SOCKET] Déconnecté du serveur');
      _isConnected = false;
      _isAuthenticated = false;
      _stopHeartbeat(); // Arrêter le heartbeat
    });

    _socket!.on('authenticated', (data) {
      _isAuthenticated = true;
      debugPrint('✅ [SOCKET] Authentification réussie');
      
      // Rejoindre automatiquement la room du jeu en cours
      if (_currentGameId > 0) {
        _joinGameRoom(_currentGameId);
        debugPrint('📤 [SOCKET] Rejoint automatiquement la room game:$_currentGameId après auth');
      }
      
      _startHeartbeat(); // Démarrer le heartbeat après authentification
      onAuthenticated?.call();
    });
    
    // Heartbeat pong (réponse du serveur)
    _socket!.on('pong', (_) {
      _lastPongReceived = DateTime.now();
      debugPrint('💓 [SOCKET] Pong reçu - connexion active');
    });

    _socket!.on('auth_error', (data) {
      _isAuthenticated = false;
      final errorMsg = data['message'] ?? 'Erreur d\'authentification';
      debugPrint('❌ [SOCKET] Erreur d\'authentification: $errorMsg');
      onError?.call(errorMsg);
    });

    _socket!.on('game-room-joined', (data) {
      debugPrint('✅ [SOCKET] Room rejointe: game:${data['gameId']}, clients: ${data['clientCount']}');
    });

    // Événements de jeu
    _socket!.on('game-updated', (data) {
      debugPrint('📥 [SOCKET] game-updated reçu');
      _handleGameData(data, onGameUpdated);
    });

    _socket!.on('move-made', (data) {
      debugPrint('📥 [SOCKET] move-made reçu');
      if (data != null) {
        onMoveMade?.call(data as Map<String, dynamic>);
      }
    });

    _socket!.on('game-started', (data) {
      debugPrint('📥 [SOCKET] game-started reçu');
      _handleGameData(data, (game) {
        // Notifier à la fois onGameUpdated et onOpponentJoined
        // car 'game-started' signifie qu'un adversaire a rejoint
        onGameUpdated?.call(game);
        onOpponentJoined?.call(game);
      });
    });

    _socket!.on('game-finished', (data) {
      debugPrint('📥 [SOCKET] game-finished reçu');
      _handleGameData(data, (game) {
        onGameFinished?.call(game);
        onGameUpdated?.call(game);
      });
    });

    _socket!.on('match-found', (data) {
      debugPrint('📥 [SOCKET] match-found reçu');
      _handleGameData(data, onMatchFound);
    });

    _socket!.on('opponent-joined', (data) {
      debugPrint('📥 [SOCKET] opponent-joined reçu');
      _handleGameData(data, onOpponentJoined);
    });

    _socket!.onError((error) {
      debugPrint('❌ [SOCKET] Erreur: $error');
      onError?.call(error.toString());
    });

    _socket!.onReconnect((_) {
      debugPrint('🔄 [SOCKET] Reconnexion réussie');
      _isConnected = true;
      _authenticate();
      _startHeartbeat(); // Redémarrer le heartbeat après reconnexion
    });

    _socket!.onReconnectAttempt((attempt) {
      debugPrint('🔄 [SOCKET] Tentative de reconnexion #$attempt');
    });

    _socket!.onReconnectError((error) {
      debugPrint('❌ [SOCKET] Erreur de reconnexion: $error');
    });
  }

  void _handleGameData(dynamic data, Function(Game)? callback) {
    if (data == null || callback == null) return;
    
    try {
      Map<String, dynamic>? gameData;
      if (data is Map<String, dynamic>) {
        gameData = data['game'] as Map<String, dynamic>?;
      }
      
      if (gameData != null) {
        final game = Game.fromJson(gameData);
        debugPrint('📥 [SOCKET] Game parsed: id=${game.id}, status=${game.status}');
        callback(game);
      } else {
        debugPrint('⚠️ [SOCKET] Données de jeu manquantes dans: $data');
      }
    } catch (e) {
      debugPrint('❌ [SOCKET] Erreur parsing game: $e');
    }
  }

  Future<void> _authenticate() async {
    try {
      String? token;
      
      // Essayer d'obtenir le token Firebase ID
      try {
        final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          token = await firebaseUser.getIdToken();
          debugPrint('🔐 [SOCKET] Token Firebase obtenu');
        }
      } catch (e) {
        debugPrint('⚠️ [SOCKET] Impossible d\'obtenir le token Firebase: $e');
      }
      
      // Fallback: utiliser le firebase_uid
      if (token == null) {
        token = await StorageService.getFirebaseUid();
        if (token != null) {
          debugPrint('🔐 [SOCKET] Utilisation Firebase UID comme fallback');
        }
      }
      
      if (token != null && _socket != null) {
        _socket!.emit('authenticate', {'token': token});
        debugPrint('🔐 [SOCKET] Authentification envoyée');
      } else {
        debugPrint('⚠️ [SOCKET] Impossible d\'authentifier: token=$token, socket=${_socket != null}');
      }
    } catch (e) {
      debugPrint('❌ [SOCKET] Erreur authentification: $e');
    }
  }

  /// Rejoint la room d'une partie
  Future<void> joinGame(int gameId) async {
    _currentGameId = gameId;
    
    // S'assurer d'être connecté - connexion non-bloquante
    if (!_isConnected || !_isAuthenticated) {
      debugPrint('⏳ [SOCKET] Connexion nécessaire avant de rejoindre la partie $gameId');
      // Démarrer la connexion mais ne pas attendre indéfiniment
      connect().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⚠️ [SOCKET] Timeout connexion, tentative de rejoindre quand même');
        },
      );
      
      // Attendre un peu pour la connexion (max 2s)
      for (int i = 0; i < 20; i++) {
        if (_isAuthenticated) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    // Rejoindre la room même si pas encore authentifié (sera fait automatiquement après auth)
    if (_isAuthenticated) {
      _joinGameRoom(gameId);
    } else {
      debugPrint('⚠️ [SOCKET] Authentification en attente, rejoindra la room automatiquement');
      // Rejoindre quand même - sera validé après authentification
      _joinGameRoom(gameId);
    }
  }

  void _joinGameRoom(int gameId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_game', {'gameId': gameId});
      debugPrint('📤 [SOCKET] join_game émis pour la partie $gameId (authenticated: $_isAuthenticated)');
    } else {
      debugPrint('⚠️ [SOCKET] Impossible de rejoindre la room - socket non connecté');
    }
  }

  void leaveGame(int gameId) {
    if (_socket != null) {
      _socket!.emit('leave_game', {'gameId': gameId});
      debugPrint('📤 [SOCKET] leave_game émis pour la partie $gameId');
    }
    if (_currentGameId == gameId) {
      _currentGameId = 0;
    }
  }

  void searchMatch(int gridSize) {
    if (_socket != null && _isAuthenticated) {
      _socket!.emit('search_match', {'gridSize': gridSize});
    }
  }

  void cancelSearch(int gridSize) {
    if (_socket != null) {
      _socket!.emit('cancel_search', {'gridSize': gridSize});
    }
  }

  /// Heartbeat pour maintenir la connexion active (critique pour iOS)
  void _startHeartbeat() {
    _stopHeartbeat();
    _lastPongReceived = DateTime.now();
    
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_socket == null || !_socket!.connected) {
        _stopHeartbeat();
        return;
      }
      
      // Vérifier si on a reçu un pong récemment
      if (_lastPongReceived != null) {
        final timeSinceLastPong = DateTime.now().difference(_lastPongReceived!);
        if (timeSinceLastPong > _heartbeatTimeout) {
          debugPrint('⚠️ [SOCKET] Pas de pong depuis ${timeSinceLastPong.inSeconds}s - reconnexion...');
          _socket?.disconnect();
          _socket?.connect();
          _lastPongReceived = DateTime.now();
          return;
        }
      }
      
      // Envoyer un ping
      try {
        _socket?.emit('ping');
        debugPrint('💓 [SOCKET] Ping envoyé');
      } catch (e) {
        debugPrint('❌ [SOCKET] Erreur heartbeat: $e');
      }
    });
  }
  
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Préconnexion au démarrage de l'app (pour réduire la latence)
  Future<void> preconnect() async {
    if (_socket == null || (!_isConnected && !_isConnecting)) {
      debugPrint('🚀 [SOCKET] Préconnexion pour compétition...');
      // Connexion en arrière-plan, non-bloquante
      connect().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ [SOCKET] Timeout préconnexion (non bloquant)');
        },
      );
    }
  }

  void disconnect() {
    _stopHeartbeat();
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _isAuthenticated = false;
      _currentGameId = 0;
    }
  }
}
