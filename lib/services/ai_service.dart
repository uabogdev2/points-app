import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game.dart';

enum AIDifficulty {
  easy,    // Fait des erreurs, rate des sabotages
  medium,  // Joue la sécurité, bloque tout, ne sacrifie rien
  hard,    // "Grand Maître" : Calcule loin, piège, utilise le Gambit
}

class AIService {
  final AIDifficulty difficulty;
  final Random _random = Random();
  
  // ⏱️ TIMER OPTIMAL : 900ms.
  // Suffisant pour calculer 6 à 10 coups d'avance sans faire laguer le téléphone.
  static const int _maxTimeMs = 900; 

  AIService({required this.difficulty});

  /// Point d'entrée principal
  Map<String, int>? getBestMove(Game game, int aiPlayerId) {
    try {
      final boardState = Map<String, int>.from(game.boardState ?? {});
      final availableMoves = _getAvailableMoves(game.gridSize, boardState);
      
      if (availableMoves.isEmpty) return null;

      final opponentId = game.players.firstWhere((p) => p.userId != aiPlayerId).userId;
      
      // Mélange initial pour que l'IA ne joue pas toujours la même partie
      availableMoves.shuffle(_random);

      switch (difficulty) {
        case AIDifficulty.easy:
          return _getEasyMove(game.gridSize, boardState, availableMoves, aiPlayerId, opponentId);
        case AIDifficulty.medium:
          return _getMediumMove(game.gridSize, boardState, availableMoves, aiPlayerId, opponentId);
        case AIDifficulty.hard:
          return _getHardMove(game, boardState, availableMoves, aiPlayerId, opponentId);
      }
    } catch (e) {
      debugPrint("⚠️ AI Critical Error: $e");
      // Fallback de sécurité pour ne jamais planter le jeu
      try {
        final fallbackMoves = _getAvailableMoves(game.gridSize, Map<String, int>.from(game.boardState ?? {}));
        return fallbackMoves.isNotEmpty ? fallbackMoves.first : null;
      } catch (_) { return null; }
    }
  }

  // ===========================================================================
  // 👶 NIVEAU 1 : DÉBUTANT (L'humain peut gagner)
  // ===========================================================================
  Map<String, int> _getEasyMove(int size, Map<String, int> board, List<Map<String, int>> moves, int aiId, int opId) {
    // 1. Prend les points gratuits (90% du temps seulement, pour laisser une chance)
    if (_random.nextInt(100) < 90) {
      for (final move in moves) {
        if (_willScorePurePoint(size, board, move, aiId)) return move;
      }
    }

    // 2. Sabote l'adversaire (bloque ses points) seulement 40% du temps.
    // C'est LA faiblesse du mode facile : elle laisse souvent l'adversaire finir ses carrés.
    if (_random.nextInt(100) < 40) {
      for (final move in moves) {
        if (_isSabotageMove(size, board, move, opId)) return move;
      }
    }

    // 3. Sinon joue au hasard complet
    return moves[_random.nextInt(moves.length)];
  }

  // ===========================================================================
  // 🛡️ NIVEAU 2 : NORMAL (Défensif et Solide)
  // ===========================================================================
  Map<String, int> _getMediumMove(int size, Map<String, int> board, List<Map<String, int>> moves, int aiId, int opId) {
    // 1. Prend TOUJOURS le point si possible (Opportuniste)
    for (final move in moves) {
      if (_willScorePurePoint(size, board, move, aiId)) return move;
    }

    // 2. Bloque TOUJOURS l'adversaire (Sabotage systématique)
    // Si l'adversaire a 3 côtés, l'IA joue le 4ème pour "tuer" le carré (le rendre mixte).
    for (final move in moves) {
      if (_isSabotageMove(size, board, move, opId)) return move;
    }

    // 3. Joue "Safe" : Cherche les coups isolés (qui ne créent pas de connexions)
    moves.sort((a, b) {
      int scoreA = _evaluateSafety(size, board, a);
      int scoreB = _evaluateSafety(size, board, b);
      return scoreB.compareTo(scoreA);
    });

    return moves[0];
  }

  // Note la sécurité d'un coup : Isolé = Bien, Connecté = Risqué
  int _evaluateSafety(int size, Map<String, int> board, Map<String, int> move) {
    int score = 0;
    final conns = _countConnections(board, move);
    if (conns == 0) score += 20; // Très sûr
    if (conns == 1) score += 10; // OK
    if (conns >= 2) score -= 10; // Risqué (commence à construire des murs)
    return score;
  }

  // ===========================================================================
  // 🧠 NIVEAU 3 : EXPERT (Stratège & Gambit)
  // ===========================================================================
  Map<String, int> _getHardMove(Game game, Map<String, int> board, List<Map<String, int>> moves, int aiId, int opId) {
    final stopwatch = Stopwatch()..start();
    Map<String, int>? bestMove;
    
    // 1. CHECK RAPIDE : Gagner ou Bloquer immédiatement
    // On le fait avant le minimax pour être sûr de ne rien rater si le temps manque.
    for (final move in moves) {
      if (_willScorePurePoint(game.gridSize, board, move, aiId)) return move;
    }
    for (final move in moves) {
      if (_isSabotageMove(game.gridSize, board, move, opId)) return move;
    }

    // 2. TRI DES COUPS (Move Ordering)
    // Optimisation cruciale : on teste les coups prometteurs en premier.
    // Cela permet à l'IA de couper les mauvaises branches très vite.
    _orderMovesForAlphaBeta(game.gridSize, board, moves, aiId, opId);

    // 3. ITERATIVE DEEPENING (Profondeur progressive)
    // On calcule à 2 coups, puis 4, puis 6... jusqu'à ce que le timer dise STOP.
    int maxDepth = 12; 

    try {
      // On avance par pas de 2 (mon tour + ton tour)
      for (int depth = 2; depth <= maxDepth; depth += 2) {
        if (stopwatch.elapsedMilliseconds > _maxTimeMs) break;

        Map<String, int>? currentBestMove;
        int bestValue = -9999999;
        int alpha = -9999999;
        int beta = 9999999;

        for (final move in moves) {
          // --- SIMULATION ---
          final k = _getKey(move); final rk = _getReverseKey(move);
          
          // Si je joue ce coup, est-ce que je marque ?
          bool isCapture = _willScorePurePoint(game.gridSize, board, move, aiId);
          
          board[k] = aiId; board[rk] = aiId;

          // Minimax appel
          int val = _minimax(game.gridSize, board, depth - 1, false, aiId, opId, alpha, beta, stopwatch);
          
          // Bonus Score
          if (isCapture) val += 2000; // Je priorise la capture immédiate dans le score

          // --- UNDO ---
          board.remove(k); board.remove(rk);

          if (val > bestValue) {
            bestValue = val;
            currentBestMove = move;
          }
          alpha = max(alpha, bestValue);
          
          // Timeout check à l'intérieur de la boucle
          if (stopwatch.elapsedMilliseconds > _maxTimeMs) break;
        }

        // Si on a fini cette profondeur sans timeout, on sauvegarde le résultat
        if (stopwatch.elapsedMilliseconds <= _maxTimeMs) {
          bestMove = currentBestMove;
        }
      }
    } catch (e) {
      // En cas d'erreur, on garde le fallback calculé au début
    }

    return bestMove ?? moves[0];
  }

  // Moteur Minimax avec Alpha-Beta Pruning
  int _minimax(int size, Map<String, int> board, int depth, bool isMax, int aiId, int opId, int alpha, int beta, Stopwatch t) {
    // Timeout immédiat
    if (t.elapsedMilliseconds > _maxTimeMs) return 0; 
    
    // Fin de branche
    if (depth == 0) return _evaluateBoard(size, board, aiId, opId);

    final moves = _getAvailableMoves(size, board);
    if (moves.isEmpty) return _evaluateBoard(size, board, aiId, opId);

    if (isMax) { // C'est à l'IA de jouer (virtuellement)
      int maxEval = -9999999;
      for (final move in moves) {
        final k = _getKey(move); final rk = _getReverseKey(move);
        bool score = _willScorePurePoint(size, board, move, aiId);
        
        board[k] = aiId; board[rk] = aiId;
        
        int eval = _minimax(size, board, depth - 1, false, aiId, opId, alpha, beta, t);
        if (score) eval += 2000; // Récompense

        board.remove(k); board.remove(rk);
        
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else { // C'est à l'ADVERSAIRE de jouer (virtuellement)
      int minEval = 9999999;
      for (final move in moves) {
        final k = _getKey(move); final rk = _getReverseKey(move);
        bool score = _willScorePurePoint(size, board, move, opId);
        
        board[k] = opId; board[rk] = opId;
        
        int eval = _minimax(size, board, depth - 1, true, aiId, opId, alpha, beta, t);
        if (score) eval -= 2000; // Pénalité (l'adversaire gagne un point)

        board.remove(k); board.remove(rk);
        
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  // ===========================================================================
  // ⚖️ FONCTION D'ÉVALUATION (Le Cerveau du Gambit)
  // ===========================================================================
  int _evaluateBoard(int size, Map<String, int> board, int aiId, int opId) {
    int score = 0;

    // 1. SCORE RÉEL (Points Purs) - Facteur x5000
    // C'est l'objectif final.
    int aiPoints = _countPureSquares(size, board, aiId);
    int opPoints = _countPureSquares(size, board, opId);
    score += (aiPoints - opPoints) * 5000;

    // 2. ANALYSE STRATÉGIQUE
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        // Si carré fermé, on passe
        if (_countTotalSides(board, r, c) == 4) continue;

        int aiSides = _countPlayerSides(board, r, c, aiId);
        int opSides = _countPlayerSides(board, r, c, opId);

        // --- DANGER MORTEL (Opponent a 3 côtés) ---
        // C'est ici que le Gambit se joue.
        // Le score baisse de 800. 
        // Si l'IA trouve un autre chemin qui rapporte +2000 plus tard, elle acceptera ce -800.
        if (opSides == 3) score -= 800; 

        // --- OPPORTUNITÉ (J'ai 3 côtés) ---
        if (aiSides == 3) score += 800;

        // --- CONSTRUCTION (2 côtés) ---
        // Avoir 2 côtés à soi est un début de territoire.
        if (aiSides == 2 && opSides == 0) score += 50;
        if (opSides == 2 && aiSides == 0) score -= 50;
      }
    }
    return score;
  }

  // ===========================================================================
  // 🛠️ UTILITAIRES TECHNIQUES
  // ===========================================================================

  // Trie les coups : Captures > Sabotages > Le reste
  void _orderMovesForAlphaBeta(int size, Map<String, int> board, List<Map<String, int>> moves, int aiId, int opId) {
    moves.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;
      
      if (_willScorePurePoint(size, board, a, aiId)) scoreA += 1000;
      if (_willScorePurePoint(size, board, b, aiId)) scoreB += 1000;
      
      if (_isSabotageMove(size, board, a, opId)) scoreA += 500;
      if (_isSabotageMove(size, board, b, opId)) scoreB += 500;
      
      return scoreB.compareTo(scoreA);
    });
  }

  // Vérifie si le coup complète un carré "PUR" (4 côtés à moi)
  bool _willScorePurePoint(int size, Map<String, int> board, Map<String, int> move, int pId) {
    final k = _getKey(move); final rk = _getReverseKey(move);
    board[k] = pId; board[rk] = pId;
    
    bool win = false;
    if (move['fromRow'] == move['toRow']) { // H
      if (move['fromRow']! > 0 && _isPureSquare(board, move['fromRow']! - 1, move['fromCol']!, pId)) win = true;
      if (move['fromRow']! < size && _isPureSquare(board, move['fromRow']!, move['fromCol']!, pId)) win = true;
    } else { // V
      if (move['fromCol']! > 0 && _isPureSquare(board, move['fromRow']!, move['fromCol']! - 1, pId)) win = true;
      if (move['fromCol']! < size && _isPureSquare(board, move['fromRow']!, move['fromCol']!, pId)) win = true;
    }

    board.remove(k); board.remove(rk);
    return win;
  }

  // Vérifie si le coup "tue" un carré adverse (3 côtés à lui -> 4ème à moi = Mixte = 0 point)
  bool _isSabotageMove(int size, Map<String, int> board, Map<String, int> move, int opId) {
    final r = move['fromRow']!; final c = move['fromCol']!;
    bool sabo = false;
    if (move['fromRow'] == move['toRow']) { // H
       if (r > 0 && _countPlayerSides(board, r-1, c, opId) == 3) sabo = true;
       if (r < size && _countPlayerSides(board, r, c, opId) == 3) sabo = true;
    } else { // V
       if (c > 0 && _countPlayerSides(board, r, c-1, opId) == 3) sabo = true;
       if (c < size && _countPlayerSides(board, r, c, opId) == 3) sabo = true;
    }
    return sabo;
  }

  // Compte les carrés purs sur tout le plateau
  int _countPureSquares(int size, Map<String, int> board, int pId) {
    int count = 0;
    for(int r=0; r<size; r++) {
      for(int c=0; c<size; c++) {
        if (_isPureSquare(board, r, c, pId)) count++;
      }
    }
    return count;
  }

  bool _isPureSquare(Map<String, int> board, int r, int c, int pId) {
    return _getOwner(board, r, c, r, c+1) == pId &&
           _getOwner(board, r+1, c, r+1, c+1) == pId &&
           _getOwner(board, r, c, r+1, c) == pId &&
           _getOwner(board, r, c+1, r+1, c+1) == pId;
  }

  int _countPlayerSides(Map<String, int> board, int r, int c, int pId) {
    int n = 0;
    if (_getOwner(board, r, c, r, c+1) == pId) n++;
    if (_getOwner(board, r+1, c, r+1, c+1) == pId) n++;
    if (_getOwner(board, r, c, r+1, c) == pId) n++;
    if (_getOwner(board, r, c+1, r+1, c+1) == pId) n++;
    return n;
  }

  int _countTotalSides(Map<String, int> board, int r, int c) {
    int n = 0;
    if (board.containsKey('$r-$c-$r-${c+1}') || board.containsKey('$r-${c+1}-$r-$c')) n++;
    if (board.containsKey('${r+1}-$c-${r+1}-${c+1}') || board.containsKey('${r+1}-${c+1}-${r+1}-$c')) n++;
    if (board.containsKey('$r-$c-${r+1}-$c') || board.containsKey('${r+1}-$c-$r-$c')) n++;
    if (board.containsKey('$r-${c+1}-${r+1}-${c+1}') || board.containsKey('${r+1}-${c+1}-$r-${c+1}')) n++;
    return n;
  }

  int _countConnections(Map<String, int> board, Map<String, int> m) {
    int c = 0;
    final r = m['fromRow']!; final col = m['fromCol']!;
    // On regarde simplement si le trait touche un autre trait existant
    if (m['fromRow'] == m['toRow']) { // H
      if (board.containsKey('$r-${col-1}-$r-$col') || board.containsKey('$r-$col-$r-${col-1}')) c++;
      if (board.containsKey('$r-${col+1}-$r-${col+2}') || board.containsKey('$r-${col+2}-$r-${col+1}')) c++;
      // (On pourrait ajouter les verticaux pour être plus précis, mais ça suffit pour l'heuristique)
    }
    return c;
  }

  int _getOwner(Map<String, int> board, int r1, int c1, int r2, int c2) {
    if (board.containsKey('$r1-$c1-$r2-$c2')) return board['$r1-$c1-$r2-$c2']!;
    if (board.containsKey('$r2-$c2-$r1-$c1')) return board['$r2-$c2-$r1-$c1']!;
    return -1;
  }

  List<Map<String, int>> _getAvailableMoves(int size, Map<String, int> board) {
    final moves = <Map<String, int>>[];
    for (int r = 0; r <= size; r++) {
      for (int c = 0; c <= size; c++) {
        if (c < size) { // H
          if (!board.containsKey('$r-$c-$r-${c+1}')) moves.add({'fromRow': r, 'fromCol': c, 'toRow': r, 'toCol': c+1});
        }
        if (r < size) { // V
          if (!board.containsKey('$r-$c-${r+1}-$c')) moves.add({'fromRow': r, 'fromCol': c, 'toRow': r+1, 'toCol': c});
        }
      }
    }
    return moves;
  }

  String _getKey(Map<String, int> m) => '${m['fromRow']}-${m['fromCol']}-${m['toRow']}-${m['toCol']}';
  String _getReverseKey(Map<String, int> m) => '${m['toRow']}-${m['toCol']}-${m['fromRow']}-${m['fromCol']}';
}