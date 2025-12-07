import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_service.dart';

class StatisticsProvider with ChangeNotifier {
  Statistic? _statistics;
  LeaderboardResponse? _leaderboard;
  bool _isLoading = false;
  String? _error;

  Statistic? get statistics => _statistics;
  LeaderboardResponse? get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger les statistiques
  Future<void> loadStatistics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statistics = await ApiService.getStatistics();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger le classement
  Future<void> loadLeaderboard({int limit = 50, int offset = 0}) async {
    _isLoading = true;
    _error = null;
    _leaderboard = null; // Réinitialiser pour éviter d'afficher d'anciennes données
    notifyListeners();

    try {
      debugPrint('📊 [STATS] Chargement du classement...');
      _leaderboard = await ApiService.getLeaderboard(limit: limit, offset: offset);
      debugPrint('✅ [STATS] Classement chargé: ${_leaderboard?.leaderboard.length ?? 0} joueurs');
    } catch (e, stackTrace) {
      debugPrint('❌ [STATS] Erreur chargement classement: $e');
      debugPrint('❌ [STATS] Stack trace: $stackTrace');
      _error = e.toString();
      _leaderboard = null; // S'assurer qu'il est null en cas d'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

