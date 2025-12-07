import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour gérer les paramètres de notifications
class NotificationSettingsProvider with ChangeNotifier {
  bool _pushNotificationsEnabled = true;

  bool get pushNotificationsEnabled => _pushNotificationsEnabled;

  NotificationSettingsProvider() {
    _loadSettings();
  }

  /// Charge les paramètres depuis le stockage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [NOTIF] Erreur chargement paramètres: $e');
    }
  }

  /// Active/désactive les notifications push
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    _pushNotificationsEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications_enabled', enabled);
      notifyListeners();
      debugPrint('🔔 [NOTIF] Notifications push ${enabled ? "activées" : "désactivées"}');
    } catch (e) {
      debugPrint('❌ [NOTIF] Erreur sauvegarde paramètres: $e');
    }
  }
}

