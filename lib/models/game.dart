import 'user.dart';

/// Représente un carré complété avec son propriétaire et numéro
class CompletedSquare {
  final int ownerId;
  final int number;

  CompletedSquare({required this.ownerId, required this.number});

  factory CompletedSquare.fromJson(dynamic json) {
    if (json is Map) {
      return CompletedSquare(
        ownerId: json['owner_id'] as int? ?? 0,
        number: json['number'] as int? ?? 1,
      );
    }
    // Ancien format: juste un numéro
    if (json is int) {
      return CompletedSquare(ownerId: 0, number: json);
    }
    return CompletedSquare(ownerId: 0, number: 1);
  }
}

class Game {
  final int id;
  final String status; // waiting, active, finished
  final int gridSize;
  final String? roomCode; // Code de la salle pour parties privées
  final bool isPrivate; // Indique si c'est une partie privée
  final Map<String, int>? boardState; // "row-col-row-col": user_id
  final Map<String, CompletedSquare>? completedSquares; // "row-col": {owner_id, number}
  final int? currentPlayerId;
  final int? totalSegments;
  final int? remainingSeconds; // Temps restant pour le tour actuel (depuis le serveur)
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<GamePlayer> players;
  final List<Move>? moves;

  Game({
    required this.id,
    required this.status,
    required this.gridSize,
    this.roomCode,
    this.isPrivate = false,
    this.boardState,
    this.completedSquares,
    this.currentPlayerId,
    this.totalSegments,
    this.remainingSeconds,
    this.startedAt,
    this.finishedAt,
    required this.players,
    this.moves,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Gérer is_private qui peut être un bool, un int (0/1), ou null
    bool parseIsPrivate(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return false;
    }
    
    return Game(
      id: json['id'] as int,
      status: json['status'] as String,
      gridSize: json['grid_size'] as int,
      roomCode: json['room_code'] as String?,
      isPrivate: parseIsPrivate(json['is_private']),
      boardState: json['board_state'] != null && json['board_state'] is Map
          ? Map<String, int>.from(
              (json['board_state'] as Map).map(
                (key, value) => MapEntry(key.toString(), value as int),
              ),
            )
          : null,
      completedSquares: json['completed_squares'] != null && json['completed_squares'] is Map
          ? Map<String, CompletedSquare>.from(
              (json['completed_squares'] as Map).map(
                (key, value) => MapEntry(key.toString(), CompletedSquare.fromJson(value)),
              ),
            )
          : null,
      currentPlayerId: json['current_player_id'] as int?,
      totalSegments: json['total_segments'] as int?,
      remainingSeconds: json['remaining_seconds'] as int?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      players: (json['players'] as List)
          .map((p) => GamePlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      moves: json['moves'] != null
          ? (json['moves'] as List)
              .map((m) => Move.fromJson(m as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'grid_size': gridSize,
      'room_code': roomCode,
      'is_private': isPrivate,
      'board_state': boardState,
      'completed_squares': completedSquares?.map((key, value) => MapEntry(key, {
        'owner_id': value.ownerId,
        'number': value.number,
      })),
      'current_player_id': currentPlayerId,
      'total_segments': totalSegments,
      'remaining_seconds': remainingSeconds,
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'players': players.map((p) => p.toJson()).toList(),
      'moves': moves?.map((m) => m.toJson()).toList(),
    };
  }
}

class GamePlayer {
  final int id;
  final int gameId;
  final int userId;
  final User? user;
  final int score;
  final bool? isWinner;
  final int position;
  final int? squaresCompleted;

  GamePlayer({
    required this.id,
    required this.gameId,
    required this.userId,
    this.user,
    required this.score,
    this.isWinner,
    required this.position,
    this.squaresCompleted,
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    // Gérer is_winner qui peut être un bool, un int (0/1), ou null
    bool? parseIsWinner(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return null;
    }
    
    return GamePlayer(
      id: json['id'] as int,
      gameId: json['game_id'] as int? ?? 0,
      userId: json['user_id'] as int,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      score: json['score'] as int? ?? 0,
      isWinner: parseIsWinner(json['is_winner']),
      position: json['position'] as int? ?? 1,
      squaresCompleted: json['squares_completed'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_id': gameId,
      'user_id': userId,
      'user': user?.toJson(),
      'score': score,
      'is_winner': isWinner,
      'position': position,
      'squares_completed': squaresCompleted,
    };
  }
}

class Move {
  final int id;
  final int gameId;
  final int userId;
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final int squaresCompleted;
  final DateTime createdAt;

  Move({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.squaresCompleted,
    required this.createdAt,
  });

  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      id: json['id'] as int,
      gameId: json['game_id'] as int,
      userId: json['user_id'] as int,
      fromRow: json['from_row'] as int,
      fromCol: json['from_col'] as int,
      toRow: json['to_row'] as int,
      toCol: json['to_col'] as int,
      squaresCompleted: json['squares_completed'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_id': gameId,
      'user_id': userId,
      'from_row': fromRow,
      'from_col': fromCol,
      'to_row': toRow,
      'to_col': toCol,
      'squares_completed': squaresCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get segmentKey => '$fromRow-$fromCol-$toRow-$toCol';
}

