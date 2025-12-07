import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../services/storage_service.dart';

class DuoGameProvider with ChangeNotifier {
  Game? _currentGame;
  bool _isLoading = false;
  String? _error;
  bool _isMyTurn = true;
  int? _currentPlayerId;
  int _player1Id = 1;
  int _player2Id = 2;
  
  // Timer
  Timer? _turnTimer;
  int _remainingSeconds = 20;
  bool _isTimerRunning = false;
  
  // Compteurs de carrés complétés pour numérotation individuelle par joueur
  Map<int, int> _squareCounters = {}; // playerId -> counter

  Game? get currentGame => _currentGame;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isMyTurn => _isMyTurn;
  int? get currentPlayerId => _currentPlayerId;
  int get remainingSeconds => _remainingSeconds;
  bool get isTimerRunning => _isTimerRunning;

  DuoGameProvider() {
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    _currentPlayerId = await StorageService.getUserId() ?? _player1Id;
  }

  /// Démarre une nouvelle partie duo
  Future<void> startDuoGame(int gridSize) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadCurrentUserId();
      
      _currentGame = Game(
        id: DateTime.now().millisecondsSinceEpoch,
        status: 'active',
        gridSize: gridSize,
        boardState: {},
        completedSquares: {},
        currentPlayerId: _player1Id,
        totalSegments: gridSize * (gridSize + 1) * 2,
        startedAt: DateTime.now(),
        finishedAt: null,
        players: [
          GamePlayer(
            id: _player1Id,
            gameId: 0,
            userId: _player1Id,
            score: 0,
            position: 1,
          ),
          GamePlayer(
            id: _player2Id,
            gameId: 0,
            userId: _player2Id,
            score: 0,
            position: 2,
          ),
        ],
        moves: [],
      );
      
      _squareCounters = {}; // Réinitialiser les compteurs de carrés par joueur
      _currentPlayerId = _player1Id;
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

  /// Effectue un mouvement
  Future<bool> makeMove(int fromRow, int fromCol, int toRow, int toCol) async {
    if (_currentGame == null || !_isMyTurn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final segmentKey = '$fromRow-$fromCol-$toRow-$toCol';
      final reverseKey = '$toRow-$toCol-$fromRow-$fromCol';
      
      if (_currentGame!.boardState?.containsKey(segmentKey) == true ||
          _currentGame!.boardState?.containsKey(reverseKey) == true) {
        _error = 'Ce segment existe déjà';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newBoardState = Map<String, int>.from(_currentGame!.boardState ?? {});
      newBoardState[segmentKey] = _currentPlayerId!;
      newBoardState[reverseKey] = _currentPlayerId!;

      // Vérifier si des carrés ont été complétés et les numéroter individuellement
      final (squaresCompleted, completedSquaresInfo) = _countAndNumberSquaresCompleted(
        newBoardState,
        fromRow,
        fromCol,
        toRow,
        toCol,
        _currentPlayerId!,
      );

      // Mettre à jour les carrés complétés avec numérotation individuelle
      final updatedCompletedSquares = Map<String, CompletedSquare>.from(_currentGame!.completedSquares ?? {});
      for (final entry in completedSquaresInfo.entries) {
        // Chaque carré obtient son propre numéro unique individuel
        updatedCompletedSquares[entry.key] = CompletedSquare(
          ownerId: _currentPlayerId!,
          number: entry.value,
        );
      }

      final updatedPlayers = _currentGame!.players.map((p) {
        if (p.id == _currentPlayerId) {
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

      // Changer de joueur si aucun carré n'a été complété
      final nextPlayerId = squaresCompleted > 0
          ? _currentPlayerId
          : (_currentPlayerId == _player1Id ? _player2Id : _player1Id);

      _currentGame = Game(
        id: _currentGame!.id,
        status: _currentGame!.status,
        gridSize: _currentGame!.gridSize,
        boardState: newBoardState,
        completedSquares: updatedCompletedSquares,
        currentPlayerId: nextPlayerId,
        totalSegments: _currentGame!.totalSegments,
        startedAt: _currentGame!.startedAt,
        finishedAt: _currentGame!.finishedAt,
        players: updatedPlayers,
        moves: _currentGame!.moves,
      );

      _currentPlayerId = nextPlayerId;
      _isMyTurn = true; // Toujours le tour de quelqu'un en mode duo
      _isLoading = false;
      
      // Arrêter le timer actuel et redémarrer pour le nouveau joueur
      _stopTurnTimer();
      if (_currentGame!.status == 'active') {
        _startTurnTimer();
      }
      
      notifyListeners();

      _checkGameOver();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Compte les carrés complétés par un mouvement et les numérote individuellement
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
          // Vérifier que ce carré n'a pas déjà été numéroté (numéro individuel unique)
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
          // Vérifier que ce carré n'a pas déjà été numéroté (numéro individuel unique)
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
          // Vérifier que ce carré n'a pas déjà été numéroté (numéro individuel unique)
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
          // Vérifier que ce carré n'a pas déjà été numéroté (numéro individuel unique)
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

  void _checkGameOver() {
    if (_currentGame == null) return;

    final gridSize = _currentGame!.gridSize;
    final boardState = _currentGame!.boardState ?? {};
    
    // Vérifier si tous les segments sont placés
    // Pour une grille de taille N, il y a N*(N+1)*2 segments au total
    // Mais chaque segment est stocké deux fois (dans les deux sens), donc on divise par 2
    final segmentsPlaced = boardState.length ~/ 2;
    final int totalSegments = _currentGame!.totalSegments ?? (gridSize * (gridSize + 1) * 2);
    
    // Vérifier aussi si tous les carrés sont complétés
    final totalPossibleSquares = (gridSize - 1) * (gridSize - 1);
    final totalCompleted = _currentGame!.players.fold<int>(
      0,
      (sum, player) => sum + player.score,
    );

    debugPrint('🔍 [DUO] Vérification fin: $segmentsPlaced/$totalSegments segments, $totalCompleted/$totalPossibleSquares carrés');

    // La partie se termine si tous les segments sont placés OU tous les carrés sont complétés
    if (segmentsPlaced >= totalSegments || totalCompleted >= totalPossibleSquares) {
      debugPrint('🏁 [DUO] Partie terminée!');
      _endGame();
    }
  }
  
  /// Termine la partie avec détermination du gagnant
  void _endGame() {
    if (_currentGame == null || _currentGame!.status == 'finished') return;
    
    final player1 = _currentGame!.players.firstWhere((p) => p.position == 1);
    final player2 = _currentGame!.players.firstWhere((p) => p.position == 2);
    
    // Déterminer le gagnant basé sur les scores
    final isDraw = player1.score == player2.score;
    GamePlayer? winner;
    
    if (!isDraw) {
      winner = player1.score > player2.score ? player1 : player2;
    }

    final updatedPlayers = _currentGame!.players.map((p) {
      return GamePlayer(
        id: p.id,
        gameId: p.gameId,
        userId: p.userId,
        score: p.score,
        isWinner: !isDraw && p.id == winner?.id,
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
    _stopTurnTimer();
    notifyListeners();
  }
  
  /// Termine la partie sans gagnant/perdant (quand on quitte)
  void endGameWithoutWinner() {
    if (_currentGame == null || _currentGame!.status == 'finished') return;
    
    debugPrint('🏳️ [DUO] Partie terminée sans gagnant (abandon)');
    
    // Ne pas marquer de gagnant/perdant
    final updatedPlayers = _currentGame!.players.map((p) {
      return GamePlayer(
        id: p.id,
        gameId: p.gameId,
        userId: p.userId,
        score: p.score,
        isWinner: false, // Pas de gagnant
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
    _stopTurnTimer();
    notifyListeners();
  }

  /// Démarre le timer du tour
  void _startTurnTimer() {
    _stopTurnTimer();
    _remainingSeconds = 20;
    _isTimerRunning = true;
    
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // Temps écoulé - passer au joueur suivant
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

  /// Gère l'expiration du timer
  void _onTimerExpired() {
    _stopTurnTimer();
    
    if (_currentGame != null && _currentGame!.status == 'active') {
      // Passer au joueur suivant
      _currentPlayerId = _currentPlayerId == _player1Id ? _player2Id : _player1Id;
      _startTurnTimer(); // Redémarrer le timer pour le nouveau joueur
      notifyListeners();
    }
  }

  void reset() {
    _squareCounters = {}; // Réinitialiser les compteurs
    _stopTurnTimer();
    _currentGame = null;
    _isLoading = false;
    _error = null;
    _isMyTurn = true;
    _currentPlayerId = _player1Id;
    _remainingSeconds = 20;
    _isTimerRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTurnTimer();
    super.dispose();
  }
}

