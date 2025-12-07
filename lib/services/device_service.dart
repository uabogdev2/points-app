import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static PackageInfo? _packageInfo;

  // Initialiser le service (appeler au démarrage de l'app)
  static Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de PackageInfo: $e');
    }
  }

  // Obtenir le type d'appareil (android, ios)
  static String getDeviceType() {
    return Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
  }

  // Obtenir l'ID unique de l'appareil
  static Future<String?> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor; // IDFV
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de l\'ID appareil: $e');
    }
    return null;
  }

  // Obtenir la version de l'app
  static String getAppVersion() {
    return _packageInfo?.version ?? '1.0.0';
  }

  // Obtenir le code de build
  static String getBuildNumber() {
    return _packageInfo?.buildNumber ?? '1';
  }

  // Obtenir le pays (via la locale)
  static Future<String?> getCountry() async {
    try {
      // Utiliser directement Platform.localeName qui fonctionne sur toutes les plateformes
      final locale = Platform.localeName;
      if (locale.isNotEmpty) {
        // Format: "fr_FR", "en_US", etc.
        final parts = locale.split('_');
        if (parts.length > 1) {
          // Retourner le code pays (ex: "FR", "US")
          return parts.last.toUpperCase();
        }
        // Si pas de séparateur, prendre les 2 derniers caractères
        if (locale.length >= 2) {
          return locale.substring(locale.length - 2).toUpperCase();
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du pays: $e');
    }
    return null;
  }

  // Obtenir toutes les informations de l'appareil
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    await initialize(); // S'assurer que PackageInfo est initialisé
    
    return {
      'device_type': getDeviceType(),
      'device_id': await getDeviceId(),
      'app_version': getAppVersion(),
      'country': await getCountry(),
    };
  }
}

