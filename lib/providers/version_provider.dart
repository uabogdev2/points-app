import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../models/version_check.dart';

class VersionProvider with ChangeNotifier {
  VersionCheck? _versionCheck;
  bool _isChecking = false;
  String? _error;

  VersionCheck? get versionCheck => _versionCheck;
  bool get isChecking => _isChecking;
  String? get error => _error;
  bool get updateRequired => _versionCheck?.updateRequired ?? false;
  bool get updateAvailable => _versionCheck?.updateAvailable ?? false;

  /// Vérifie la version de l'app
  Future<void> checkVersion() async {
    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
      final version = DeviceService.getAppVersion();
      
      debugPrint('🔍 Vérification de version: platform=$platform, version=$version');
      
      _versionCheck = await ApiService.checkVersion(platform, version);
      
      debugPrint('✅ Vérification de version terminée:');
      debugPrint('   - Update required: ${_versionCheck?.updateRequired}');
      debugPrint('   - Update available: ${_versionCheck?.updateAvailable}');
      debugPrint('   - Latest version: ${_versionCheck?.latestVersion}');
      debugPrint('   - Min version: ${_versionCheck?.minVersion}');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de version: $e');
      _error = e.toString();
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}

