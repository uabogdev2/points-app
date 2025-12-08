class User {
  final int id;
  final String name;
  final String email;
  final String firebaseUid;
  final String? avatarUrl;
  final String? deviceType;
  final String? deviceId;
  final String? appVersion;
  final String? country;
  final DateTime? lastActiveAt;
  final Statistic? statistic;
  final bool adsRemoved;
  final DateTime? adsRemovedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.firebaseUid,
    this.avatarUrl,
    this.deviceType,
    this.deviceId,
    this.appVersion,
    this.country,
    this.lastActiveAt,
    this.statistic,
    this.adsRemoved = false,
    this.adsRemovedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      firebaseUid: json['firebase_uid'] as String,
      avatarUrl: json['avatar_url'] as String?,
      deviceType: json['device_type'] as String?,
      deviceId: json['device_id'] as String?,
      appVersion: json['app_version'] as String?,
      country: json['country'] as String?,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      statistic: json['statistic'] != null
          ? Statistic.fromJson(json['statistic'] as Map<String, dynamic>)
          : null,
      adsRemoved: json['ads_removed'] as bool? ?? false,
      adsRemovedAt: json['ads_removed_at'] != null
          ? DateTime.parse(json['ads_removed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'firebase_uid': firebaseUid,
      'avatar_url': avatarUrl,
      'device_type': deviceType,
      'device_id': deviceId,
      'app_version': appVersion,
      'country': country,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'statistic': statistic?.toJson(),
      'ads_removed': adsRemoved,
      'ads_removed_at': adsRemovedAt?.toIso8601String(),
    };
  }
}

class Statistic {
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int totalSquaresCompleted;
  final int bestScore;
  final int currentStreak;
  final int longestStreak;
  final double? winRate;
  // Stats matchmaking (pour le classement)
  final int gamesPlayedMatchmaking;
  final int gamesWonMatchmaking;
  final int gamesLostMatchmaking;
  final int currentStreakMatchmaking;
  final int longestStreakMatchmaking;
  final double? winRateMatchmaking;

  Statistic({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.gamesLost,
    required this.totalSquaresCompleted,
    required this.bestScore,
    required this.currentStreak,
    required this.longestStreak,
    this.winRate,
    this.gamesPlayedMatchmaking = 0,
    this.gamesWonMatchmaking = 0,
    this.gamesLostMatchmaking = 0,
    this.currentStreakMatchmaking = 0,
    this.longestStreakMatchmaking = 0,
    this.winRateMatchmaking,
  });

  factory Statistic.fromJson(Map<String, dynamic> json) {
    return Statistic(
      gamesPlayed: json['games_played'] as int? ?? 0,
      gamesWon: json['games_won'] as int? ?? 0,
      gamesLost: json['games_lost'] as int? ?? 0,
      totalSquaresCompleted: json['total_squares_completed'] as int? ?? 0,
      bestScore: json['best_score'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      winRate: json['win_rate'] != null
          ? (json['win_rate'] as num).toDouble()
          : null,
      gamesPlayedMatchmaking: json['games_played_matchmaking'] as int? ?? 0,
      gamesWonMatchmaking: json['games_won_matchmaking'] as int? ?? 0,
      gamesLostMatchmaking: json['games_lost_matchmaking'] as int? ?? 0,
      currentStreakMatchmaking: json['current_streak_matchmaking'] as int? ?? 0,
      longestStreakMatchmaking: json['longest_streak_matchmaking'] as int? ?? 0,
      winRateMatchmaking: json['win_rate_matchmaking'] != null
          ? (json['win_rate_matchmaking'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'games_lost': gamesLost,
      'total_squares_completed': totalSquaresCompleted,
      'best_score': bestScore,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'win_rate': winRate,
      'games_played_matchmaking': gamesPlayedMatchmaking,
      'games_won_matchmaking': gamesWonMatchmaking,
      'games_lost_matchmaking': gamesLostMatchmaking,
      'current_streak_matchmaking': currentStreakMatchmaking,
      'longest_streak_matchmaking': longestStreakMatchmaking,
      'win_rate_matchmaking': winRateMatchmaking,
    };
  }
}

