import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/audio_controller.dart';

class SoloGameProvider with ChangeNotifier {
  Game? _currentGame;
  bool _isLoading = false;
  String? _error;
  bool _isMyTurn = true;
  int? _currentUserId;
  AIService? _aiService;
  AIDifficulty _difficulty = AIDifficulty.medium;
  int _aiPlayerId = 2; // ID fictif pour l'IA
  
  // Timer
  Timer? _turnTimer;
  Timer? _aiTimer;
  static const int _timerDuration = 45; // 45 secondes par tour
  int _remainingSeconds = _timerDuration;
  int _aiRemainingSeconds = _timerDuration;
  bool _isTimerRunning = false;
  bool _isAITimerRunning = false;
  
  // Compteurs de carrés complétés pour numérotation individuelle par joueur
  Map<int, int> _squareCounters = {}; // playerId -> counter

  Game? get currentGame => _currentGame;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isMyTurn => _isMyTurn;
  AIDifficulty get difficulty => _difficulty;
  int get remainingSeconds => _remainingSeconds;
  bool get isTimerRunning => _isTimerRunning;
  int get aiRemainingSeconds => _aiRemainingSeconds;
  bool get isAITimerRunning => _isAITimerRunning;

  SoloGameProvider() {
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await StorageService.getUserId();
  }

  /// Démarre une nouvelle partie solo
  Future<void> startSoloGame(int gridSize, AIDifficulty difficulty) async {
    _isLoading = true;
    _error = null;
    _difficulty = difficulty;
    _aiService = AIService(difficulty: difficulty);
    notifyListeners();

    try {
      await _loadCurrentUserId();
      
      // Créer une partie locale (pas besoin de backend pour le mode solo)
      _currentGame = Game(
        id: DateTime.now().millisecondsSinceEpoch,
        status: 'active',
        gridSize: gridSize,
        boardState: {},
        completedSquares: {},
        currentPlayerId: _currentUserId,
        totalSegments: gridSize * (gridSize + 1) * 2,
        startedAt: DateTime.now(),
        finishedAt: null,
        players: [
          GamePlayer(
            id: 1,
            gameId: 0,
            userId: _currentUserId!,
            score: 0,
            position: 1,
          ),
          GamePlayer(
            id: 2,
            gameId: 0,
            userId: _aiPlayerId,
            score: 0,
            position: 2,
          ),
        ],
        moves: [],
      );
      
      _squareCounters = {}; // Réinitialiser les compteurs de carrés par joueur
      
      _isMyTurn = true;
      _isLoading = false;
      _startTurnTimer();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Effectue un mouvement du joueur
  Future<bool> makeMove(int fromRow, int fromCol, int toRow, int toCol) async {
    if (_currentGame == null || !_isMyTurn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier que le segment n'existe pas déjà
      final segmentKey = '$fromRow-$fromCol-$toRow-$toCol';
      final reverseKey = '$toRow-$toCol-$fromRow-$fromCol';
      
      if (_currentGame!.boardState?.containsKey(segmentKey) == true ||
          _currentGame!.boardState?.containsKey(reverseKey) == true) {
        _error = 'Ce segment existe déjà';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Ajouter le segment dans les deux sens
      final newBoardState = Map<String, int>.from(_currentGame!.boardState ?? {});
      newBoardState[segmentKey] = _currentUserId!;
      newBoardState[reverseKey] = _currentUserId!;

      // Vérifier si des carrés ont été complétés et les numéroter
      final (squaresCompleted, completedSquaresInfo) = _countAndNumberSquaresCompleted(
        newBoardState,
        fromRow,
        fromCol,
        toRow,
        toCol,
        _currentUserId!,
      );

      // Mettre à jour les carrés complétés avec numérotation
      final updatedCompletedSquares = Map<String, CompletedSquare>.from(_currentGame!.completedSquares ?? {});
      for (final entry in completedSquaresInfo.entries) {
        updatedCompletedSquares[entry.key] = CompletedSquare(
          ownerId: _currentUserId!,
          number: entry.value,
        );
      }

      // Mettre à jour le score
      final updatedPlayers = _currentGame!.players.map((p) {
        if (p.userId == _currentUserId) {
          return GamePlayer(
            id: p.id,
            gameId: p.gameId,
            userId: p.userId,
            score: p.score + squaresCompleted,
            position: p.position,
          );
        }
        return p;
      }).toList();

      _currentGame = Game(
        id: _currentGame!.id,
        status: _currentGame!.status,
        gridSize: _currentGame!.gridSize,
        boardState: newBoardState,
        completedSquares: updatedCompletedSquares,
        currentPlayerId: squaresCompleted > 0 ? _currentUserId : _aiPlayerId,
        totalSegments: _currentGame!.totalSegments,
        startedAt: _currentGame!.startedAt,
        finishedAt: _currentGame!.finishedAt,
        players: updatedPlayers,
        moves: _currentGame!.moves,
      );

      _isMyTurn = squaresCompleted > 0;
      _isLoading = false;
      
      // Arrêter le timer et en démarrer un nouveau si nécessaire
      _stopTurnTimer();
      
      if (squaresCompleted > 0) {
        // Le joueur rejoue, redémarrer le timer
        _startTurnTimer();
      }
      
      notifyListeners();

      // Si le joueur n'a pas complété de carré, c'est le tour de l'IA
      if (squaresCompleted == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _makeAIMove();
      }

      // Vérifier si la partie est terminée
      _checkGameOver();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Effectue un mouvement de l'IA
  Future<void> _makeAIMove() async {
    if (_currentGame == null || _aiService == null) return;
    if (_currentGame!.status != 'active') return;
    
    // Démarrer le timer pour l'IA AVANT de commencer la réflexion
    _startAITimer();

    _isLoading = true;
    notifyListeners();

    // Attendre minimum 15 secondes pour que l'IA réfléchisse
    // Le timer continue à décompter pendant ce temps
    final startTime = DateTime.now();
    const minThinkingTime = Duration(seconds: 7);
    
    try {
      // Calculer le meilleur mouvement avec un timeout de 20 secondes (pour laisser plus de marge)
      Map<String, int>? aiMove;
      try {
        // Exécuter l'IA avec protection maximale contre les plantages
        aiMove = await Future(() {
          try {
            // Vérifier que le jeu est toujours actif
            if (_currentGame == null || _aiService == null || _currentGame!.status != 'active') {
              return null;
            }
            
            // Créer une copie sécurisée du jeu pour éviter les modifications pendant le calcul
            final gameCopy = _currentGame!;
            
            // Exécuter l'IA avec gestion d'erreur renforcée
            final move = _aiService!.getBestMove(gameCopy, _aiPlayerId);
            
            // Vérifier à nouveau après le calcul
            if (_currentGame == null || _currentGame!.status != 'active') {
              return null;
            }
            
            return move;
          } catch (e, stackTrace) {
            debugPrint('❌ IA erreur critique dans getBestMove: $e');
            debugPrint('❌ Stack trace: $stackTrace');
            // Retourner null pour utiliser le fallback
            return null;
          }
        }).timeout(
          const Duration(seconds: 15), // Timeout réduit à 15 secondes
          onTimeout: () {
            debugPrint('⚠️ IA timeout après 15 secondes, utilisation du fallback');
            return _getQuickAIMove();
          },
        );
      } catch (e, stackTrace) {
        // Erreur - utiliser une heuristique rapide
        debugPrint('⚠️ IA erreur: $e');
        debugPrint('⚠️ Stack trace: $stackTrace');
        try {
          aiMove = _getQuickAIMove();
        } catch (e2) {
          debugPrint('❌ Erreur même dans fallback: $e2');
          aiMove = null;
        }
      }
      
      // Attendre le temps minimum de réflexion (7 secondes)
      // Le timer continue à décompter pendant ce temps
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minThinkingTime) {
        await Future.delayed(minThinkingTime - elapsed);
      }
      
      // Vérifier que le timer n'a pas expiré
      if (_aiRemainingSeconds <= 0) {
        debugPrint('⚠️ Timer IA expiré, passage au joueur');
        _stopAITimer();
        _isMyTurn = true;
        _isLoading = false;
        _startTurnTimer();
        notifyListeners();
        return;
      }
      
      if (aiMove == null) {
        // Si l'IA n'a pas trouvé de mouvement (timeout ou pas de mouvement), passer au joueur
        _stopAITimer();
        _isMyTurn = true;
        _isLoading = false;
        _startTurnTimer(); // Démarrer le timer pour le joueur
        notifyListeners();
        return;
      }
      
      // Ne pas arrêter le timer ici - il continuera si l'IA complète un carré

      final fromRow = aiMove['fromRow']!;
      final fromCol = aiMove['fromCol']!;
      final toRow = aiMove['toRow']!;
      final toCol = aiMove['toCol']!;

      final segmentKey = '$fromRow-$fromCol-$toRow-$toCol';
      final reverseKey = '$toRow-$toCol-$fromRow-$fromCol';
      final newBoardState = Map<String, int>.from(_currentGame!.boardState ?? {});
      newBoardState[segmentKey] = _aiPlayerId;
      newBoardState[reverseKey] = _aiPlayerId;
      
      // Jouer le son de clic quand l'IA joue
      AudioController.playClickSound();

      final (squaresCompleted, completedSquaresInfo) = _countAndNumberSquaresCompleted(
        newBoardState,
        fromRow,
        fromCol,
        toRow,
        toCol,
        _aiPlayerId,
      );

      final updatedPlayers = _currentGame!.players.map((p) {
        if (p.userId == _aiPlayerId) {
          return GamePlayer(
            id: p.id,
            gameId: p.gameId,
            userId: p.userId,
            score: p.score + squaresCompleted,
            position: p.position,
          );
        }
        return p;
      }).toList();

      // Mettre à jour les carrés complétés avec numérotation
      final updatedCompletedSquares = Map<String, CompletedSquare>.from(_currentGame!.completedSquares ?? {});
      for (final entry in completedSquaresInfo.entries) {
        updatedCompletedSquares[entry.key] = CompletedSquare(
          ownerId: _aiPlayerId,
          number: entry.value,
        );
      }

      _currentGame = Game(
        id: _currentGame!.id,
        status: _currentGame!.status,
        gridSize: _currentGame!.gridSize,
        boardState: newBoardState,
        completedSquares: updatedCompletedSquares,
        currentPlayerId: squaresCompleted > 0 ? _aiPlayerId : _currentUserId,
        totalSegments: _currentGame!.totalSegments,
        startedAt: _currentGame!.startedAt,
        finishedAt: _currentGame!.finishedAt,
        players: updatedPlayers,
        moves: _currentGame!.moves,
      );

      _isMyTurn = squaresCompleted == 0;
      _isLoading = false;
      
      if (squaresCompleted == 0) {
        // C'est le tour du joueur, arrêter le timer de l'IA et démarrer celui du joueur
        _stopAITimer();
        _startTurnTimer();
      } else {
        // L'IA a complété un carré, le timer continue
        // Vérifier si le timer n'a pas expiré
        if (_aiRemainingSeconds <= 0) {
          _stopAITimer();
          _isMyTurn = true;
          _startTurnTimer();
          notifyListeners();
          return;
        }
      }
      
      notifyListeners();

      // Si l'IA a complété un carré, elle rejoue (le timer continue)
      if (squaresCompleted > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _makeAIMove();
      }

      _checkGameOver();
    } catch (e, stackTrace) {
      // Gestion d'erreur améliorée pour éviter les plantages
      debugPrint('❌ Erreur dans _makeAIMove: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Erreur IA: ${e.toString()}';
      _stopAITimer();
      _isMyTurn = true;
      _isLoading = false;
      _startTurnTimer(); // Passer au joueur en cas d'erreur
      notifyListeners();
    }
  }

  /// Compte les carrés complétés par un mouvement et les numérote
  (int, Map<String, int>) _countAndNumberSquaresCompleted(
    Map<String, int> boardState,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    int playerId,
  ) {
    int count = 0;
    final gridSize = _currentGame!.gridSize;
    final completedSquaresInfo = <String, int>{};

    // Vérifier les carrés adjacents au segment
    if (fromRow == toRow) {
      // Segment horizontal
      final row = fromRow;
      final col = fromCol < toCol ? fromCol : toCol;
      
      // Carré au-dessus
      if (row > 0) {
        final squareKey = '${row - 1}-$col';
        if (_isSquareCompleted(boardState, row - 1, col, playerId, gridSize)) {
          // Vérifier que ce carré n'a pas déjà été numéroté
          if (!(_currentGame!.completedSquares?.containsKey(squareKey) ?? false)) {
            // Incrémenter le compteur individuel pour ce joueur
            _squareCounters[playerId] = (_squareCounters[playerId] ?? 0) + 1;
            completedSquaresInfo[squareKey] = _squareCounters[playerId]!; // Numéro individuel pour ce joueur
            count++;
          }
        }
      }
      
      // Carré en-dessous
      if (row < gridSize) {
        final squareKey = '$row-$col';
        if (_isSquareCompleted(boardState, row, col, playerId, gridSize)) {
          // Vérifier que ce carré n'a pas déjà été numéroté
          if (!(_currentGame!.completedSquares?.containsKey(squareKey) ?? false)) {
            // Incrémenter le compteur individuel pour ce joueur
            _squareCounters[playerId] = (_squareCounters[playerId] ?? 0) + 1;
            completedSquaresInfo[squareKey] = _squareCounters[playerId]!; // Numéro individuel pour ce joueur
            count++;
          }
        }
      }
    } else {
      // Segment vertical
      final row = fromRow < toRow ? fromRow : toRow;
      final col = fromCol;
      
      // Carré à gauche
      if (col > 0) {
        final squareKey = '$row-${col - 1}';
        if (_isSquareCompleted(boardState, row, col - 1, playerId, gridSize)) {
          // Vérifier que ce carré n'a pas déjà été numéroté
          if (!(_currentGame!.completedSquares?.containsKey(squareKey) ?? false)) {
            // Incrémenter le compteur individuel pour ce joueur
            _squareCounters[playerId] = (_squareCounters[playerId] ?? 0) + 1;
            completedSquaresInfo[squareKey] = _squareCounters[playerId]!; // Numéro individuel pour ce joueur
            count++;
          }
        }
      }
      
      // Carré à droite
      if (col < gridSize) {
        final squareKey = '$row-$col';
        if (_isSquareCompleted(boardState, row, col, playerId, gridSize)) {
          // Vérifier que ce carré n'a pas déjà été numéroté
          if (!(_currentGame!.completedSquares?.containsKey(squareKey) ?? false)) {
            // Incrémenter le compteur individuel pour ce joueur
            _squareCounters[playerId] = (_squareCounters[playerId] ?? 0) + 1;
            completedSquaresInfo[squareKey] = _squareCounters[playerId]!; // Numéro individuel pour ce joueur
            count++;
          }
        }
      }
    }

    return (count, completedSquaresInfo);
  }

  /// Compte les carrés complétés par un mouvement (méthode utilitaire pour fallback)
  int _countSquaresCompleted(
    Map<String, int> boardState,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    int playerId,
  ) {
    int count = 0;
    final gridSize = _currentGame!.gridSize;

    // Vérifier les carrés adjacents au segment
    if (fromRow == toRow) {
      // Segment horizontal
      final row = fromRow;
      final col = fromCol < toCol ? fromCol : toCol;
      
      // Carré au-dessus
      if (row > 0) {
        if (_isSquareCompleted(boardState, row - 1, col, playerId, gridSize)) {
          count++;
        }
      }
      
      // Carré en-dessous
      if (row < gridSize) {
        if (_isSquareCompleted(boardState, row, col, playerId, gridSize)) {
          count++;
        }
      }
    } else {
      // Segment vertical
      final row = fromRow < toRow ? fromRow : toRow;
      final col = fromCol;
      
      // Carré à gauche
      if (col > 0) {
        if (_isSquareCompleted(boardState, row, col - 1, playerId, gridSize)) {
          count++;
        }
      }
      
      // Carré à droite
      if (col < gridSize) {
        if (_isSquareCompleted(boardState, row, col, playerId, gridSize)) {
          count++;
        }
      }
    }

    return count;
  }

  /// Vérifie si un carré est complété
  bool _isSquareCompleted(
    Map<String, int> boardState,
    int row,
    int col,
    int playerId,
    int gridSize,
  ) {
    if (row >= gridSize || col >= gridSize) return false;

    final top = boardState['$row-$col-${row}-${col + 1}'] == playerId ||
                boardState['$row-${col + 1}-$row-$col'] == playerId;
    final right = boardState['$row-${col + 1}-${row + 1}-${col + 1}'] == playerId ||
                  boardState['${row + 1}-${col + 1}-$row-${col + 1}'] == playerId;
    final bottom = boardState['${row + 1}-$col-${row + 1}-${col + 1}'] == playerId ||
                   boardState['${row + 1}-${col + 1}-${row + 1}-$col'] == playerId;
    final left = boardState['$row-$col-${row + 1}-$col'] == playerId ||
                 boardState['${row + 1}-$col-$row-$col'] == playerId;

    return top && right && bottom && left;
  }

  /// Vérifie si la partie est terminée
  void _checkGameOver() {
    if (_currentGame == null) return;

    // Vérifier s'il reste des mouvements possibles
    final availableMoves = _getAvailableMoves();
    if (availableMoves.isEmpty) {
      // Plus de mouvements possibles, terminer la partie
      debugPrint('🏁 [SOLO] Plus de mouvements possibles, fin de partie');
      _endGame();
      return;
    }

    // Pour une grille de taille N (N points par côté), il y a (N-1) * (N-1) carrés
    final gridSize = _currentGame!.gridSize;
    final totalPossibleSquares = (gridSize - 1) * (gridSize - 1);
    final totalCompleted = _currentGame!.players.fold<int>(
      0,
      (sum, player) => sum + player.score,
    );

    debugPrint('🔍 [SOLO] Vérification fin: $totalCompleted/$totalPossibleSquares carrés');

    if (totalCompleted >= totalPossibleSquares) {
      debugPrint('🏁 [SOLO] Tous les carrés complétés, fin de partie');
      _endGame();
    }
  }
  
  /// Termine la partie
  void _endGame() {
    if (_currentGame == null || _currentGame!.status == 'finished') return;
    
    // Déterminer le gagnant
    final winner = _currentGame!.players.reduce(
      (a, b) => a.score > b.score ? a : b,
    );

    final updatedPlayers = _currentGame!.players.map((p) {
      return GamePlayer(
        id: p.id,
        gameId: p.gameId,
        userId: p.userId,
        score: p.score,
        isWinner: p.id == winner.id,
        position: p.position,
      );
    }).toList();

    _currentGame = Game(
      id: _currentGame!.id,
      status: 'finished',
      gridSize: _currentGame!.gridSize,
      boardState: _currentGame!.boardState,
      completedSquares: _currentGame!.completedSquares,
      currentPlayerId: null,
      totalSegments: _currentGame!.totalSegments,
      startedAt: _currentGame!.startedAt,
      finishedAt: DateTime.now(),
      players: updatedPlayers,
      moves: _currentGame!.moves,
    );

    _isMyTurn = false;
    _stopTurnTimer(); // Arrêter le timer quand la partie est terminée
    _stopAITimer(); // Arrêter aussi le timer de l'IA
    notifyListeners();
  }

  /// Abandonne la partie (défaite pour le joueur)
  void forfeitGame() {
    if (_currentGame == null || _currentGame!.status == 'finished') return;
    
    debugPrint('🏳️ [SOLO] Le joueur a abandonné la partie');
    
    // Marquer l'IA comme gagnante et le joueur comme perdant
    final updatedPlayers = _currentGame!.players.map((p) {
      return GamePlayer(
        id: p.id,
        gameId: p.gameId,
        userId: p.userId,
        score: p.score,
        isWinner: p.userId == _aiPlayerId, // L'IA gagne par abandon
        position: p.position,
      );
    }).toList();

    _currentGame = Game(
      id: _currentGame!.id,
      status: 'finished',
      gridSize: _currentGame!.gridSize,
      boardState: _currentGame!.boardState,
      completedSquares: _currentGame!.completedSquares,
      currentPlayerId: null,
      totalSegments: _currentGame!.totalSegments,
      startedAt: _currentGame!.startedAt,
      finishedAt: DateTime.now(),
      players: updatedPlayers,
      moves: _currentGame!.moves,
    );

    _isMyTurn = false;
    _stopTurnTimer(); // Arrêter le timer quand la partie est terminée
    _stopAITimer(); // Arrêter aussi le timer de l'IA
    notifyListeners();
  }

  /// Démarre le timer du tour
  void _startTurnTimer() {
    _stopTurnTimer();
    _remainingSeconds = _timerDuration;
    _isTimerRunning = true;
    
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentGame == null || _currentGame!.status != 'active') {
        _stopTurnTimer();
        return;
      }
      
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // Temps écoulé
        _onTimerExpired();
      }
    });
  }

  /// Arrête le timer du tour
  void _stopTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
    _isTimerRunning = false;
  }

  /// Gère l'expiration du timer du joueur
  void _onTimerExpired() {
    _stopTurnTimer();
    
    if (_isMyTurn && _currentGame != null && _currentGame!.status == 'active') {
      // Le joueur a dépassé le temps, passer au tour de l'IA
      _isMyTurn = false;
      _makeAIMove();
    }
  }
  
  /// Démarre le timer de l'IA
  void _startAITimer() {
    _stopAITimer(); // S'assurer qu'aucun timer n'est déjà en cours
    _aiRemainingSeconds = _timerDuration;
    _isAITimerRunning = true;
    notifyListeners(); // Notifier immédiatement pour afficher le timer
    
    _aiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentGame == null || _currentGame!.status != 'active') {
        _stopAITimer();
        return;
      }
      
      if (_aiRemainingSeconds > 0) {
        _aiRemainingSeconds--;
        notifyListeners(); // Notifier à chaque seconde pour mettre à jour l'affichage
      } else {
        // Temps écoulé pour l'IA, passer au joueur
        _onAITimerExpired();
      }
    });
  }
  
  /// Arrête le timer de l'IA
  void _stopAITimer() {
    _aiTimer?.cancel();
    _aiTimer = null;
    _isAITimerRunning = false;
  }
  
  /// Gère l'expiration du timer de l'IA
  void _onAITimerExpired() {
    _stopAITimer();
    
    if (!_isMyTurn && _currentGame != null && _currentGame!.status == 'active') {
      // L'IA a dépassé le temps, passer au joueur
      _isMyTurn = true;
      _startTurnTimer(); // Démarrer le timer pour le joueur
      notifyListeners();
    }
  }

  /// Réinitialise la partie
  void reset() {
    _stopTurnTimer();
    _stopAITimer();
    _currentGame = null;
    _isLoading = false;
    _error = null;
    _isMyTurn = true;
    _aiService = null;
    _remainingSeconds = _timerDuration;
    _aiRemainingSeconds = _timerDuration;
    _isTimerRunning = false;
    _isAITimerRunning = false;
    _squareCounters = {}; // Réinitialiser les compteurs
    notifyListeners();
  }

  /// Obtient un mouvement rapide pour l'IA (fallback en cas de timeout)
  Map<String, int>? _getQuickAIMove() {
    if (_currentGame == null || _aiService == null) return null;
    
    // Utiliser une stratégie simple et rapide
    final availableMoves = _getAvailableMoves();
    if (availableMoves.isEmpty) return null;
    
    // Chercher un mouvement qui complète un carré
    for (final move in availableMoves) {
      final testBoardState = Map<String, int>.from(_currentGame!.boardState ?? {});
      final segmentKey = '${move['fromRow']}-${move['fromCol']}-${move['toRow']}-${move['toCol']}';
      final reverseKey = '${move['toRow']}-${move['toCol']}-${move['fromRow']}-${move['fromCol']}';
      testBoardState[segmentKey] = _aiPlayerId;
      testBoardState[reverseKey] = _aiPlayerId;
      
      final squaresCompleted = _countSquaresCompleted(
        testBoardState,
        move['fromRow']!,
        move['fromCol']!,
        move['toRow']!,
        move['toCol']!,
        _aiPlayerId,
      );
      
      if (squaresCompleted > 0) {
        return move;
      }
    }
    
    // Sinon, retourner le premier mouvement disponible
    return availableMoves.first;
  }
  
  /// Récupère tous les mouvements disponibles (méthode utilitaire)
  List<Map<String, int>> _getAvailableMoves() {
    final moves = <Map<String, int>>[];
    final boardState = _currentGame!.boardState ?? {};
    final gridSize = _currentGame!.gridSize;
    
    for (int row = 0; row <= gridSize; row++) {
      for (int col = 0; col <= gridSize; col++) {
        // Segments horizontaux
        if (col < gridSize) {
          final key1 = '$row-$col-${row}-${col + 1}';
          final key2 = '$row-${col + 1}-$row-$col';
          if (!boardState.containsKey(key1) && !boardState.containsKey(key2)) {
            moves.add({'fromRow': row, 'fromCol': col, 'toRow': row, 'toCol': col + 1});
          }
        }
        // Segments verticaux
        if (row < gridSize) {
          final key1 = '$row-$col-${row + 1}-$col';
          final key2 = '${row + 1}-$col-$row-$col';
          if (!boardState.containsKey(key1) && !boardState.containsKey(key2)) {
            moves.add({'fromRow': row, 'fromCol': col, 'toRow': row + 1, 'toCol': col});
          }
        }
      }
    }
    
    return moves;
  }

  @override
  void dispose() {
    _stopTurnTimer();
    _stopAITimer();
    super.dispose();
  }
}

