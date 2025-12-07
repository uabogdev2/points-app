import 'package:flutter/foundation.dart';
import 'user.dart';

class LeaderboardEntry {
  final int rank;
  final User user;
  final Statistic statistic;

  LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.statistic,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    try {
      return LeaderboardEntry(
        rank: json['rank'] as int,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        statistic: Statistic.fromJson(json['statistic'] as Map<String, dynamic>),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [LEADERBOARD] Erreur parsing LeaderboardEntry: $e');
      debugPrint('❌ [LEADERBOARD] JSON: $json');
      debugPrint('❌ [LEADERBOARD] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class LeaderboardResponse {
  final List<LeaderboardEntry> leaderboard;
  final int total;
  final int limit;
  final int offset;
  final int? userRank;

  LeaderboardResponse({
    required this.leaderboard,
    required this.total,
    required this.limit,
    required this.offset,
    this.userRank,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('📊 [LEADERBOARD] Parsing LeaderboardResponse...');
      debugPrint('📊 [LEADERBOARD] Total: ${json['total']}, Limit: ${json['limit']}, Offset: ${json['offset']}');
      debugPrint('📊 [LEADERBOARD] Leaderboard count: ${(json['leaderboard'] as List?)?.length ?? 0}');
      
      final leaderboardList = (json['leaderboard'] as List?)
          ?.map((e) {
            try {
              return LeaderboardEntry.fromJson(e as Map<String, dynamic>);
            } catch (e) {
              debugPrint('❌ [LEADERBOARD] Erreur parsing entry: $e');
              rethrow;
            }
          })
          .toList() ?? [];
      
      debugPrint('✅ [LEADERBOARD] ${leaderboardList.length} entrées parsées avec succès');
      
      return LeaderboardResponse(
        leaderboard: leaderboardList,
        total: json['total'] as int? ?? 0,
        limit: json['limit'] as int? ?? 50,
        offset: json['offset'] as int? ?? 0,
        userRank: json['user_rank'] as int?,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [LEADERBOARD] Erreur parsing LeaderboardResponse: $e');
      debugPrint('❌ [LEADERBOARD] JSON: $json');
      debugPrint('❌ [LEADERBOARD] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

