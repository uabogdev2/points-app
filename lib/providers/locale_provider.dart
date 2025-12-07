import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  bool _isLoading = true;
  static const String _localeKey = 'app_locale';

  LocaleProvider() {
    _loadLocale();
  }

  bool get isLoading => _isLoading;

  Locale get locale => _locale ?? _getSystemLocale();

  Future<void> _loadLocale() async {
    try {
      _isLoading = true;
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      
      debugPrint('🌐 [LOCALE] Chargement de la locale sauvegardée: $localeCode');
      
      if (localeCode != null) {
        if (localeCode == 'system') {
          _locale = null; // Utiliser la langue du système
          debugPrint('🌐 [LOCALE] Utilisation de la langue système');
        } else {
          _locale = Locale(localeCode);
          debugPrint('🌐 [LOCALE] Locale chargée: ${_locale!.languageCode}');
        }
      } else {
        _locale = null; // Par défaut, utiliser la langue du système
        debugPrint('🌐 [LOCALE] Aucune locale sauvegardée, utilisation du système');
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [LOCALE] Erreur lors du chargement de la locale: $e');
      _locale = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (locale == null) {
        // Utiliser la langue du système
        await prefs.setString(_localeKey, 'system');
        _locale = null;
        debugPrint('🌐 [LOCALE] Langue changée vers: système');
      } else {
        await prefs.setString(_localeKey, locale.languageCode);
        _locale = locale;
        debugPrint('🌐 [LOCALE] Langue changée vers: ${locale.languageCode}');
      }
      
      // Forcer la notification immédiatement
      notifyListeners();
      
      // Vérifier que la sauvegarde a bien fonctionné
      final saved = await prefs.getString(_localeKey);
      debugPrint('🌐 [LOCALE] Vérification sauvegarde: $saved');
    } catch (e) {
      debugPrint('❌ [LOCALE] Erreur lors de la sauvegarde de la locale: $e');
    }
  }

  Locale _getSystemLocale() {
    // Obtenir la locale du système
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    
    // Vérifier si on supporte cette langue, sinon utiliser le français par défaut
    if (systemLocale.languageCode == 'en') {
      return const Locale('en');
    } else {
      return const Locale('fr'); // Français par défaut
    }
  }

  String get currentLanguageCode {
    if (_locale == null) {
      return _getSystemLocale().languageCode;
    }
    return _locale!.languageCode;
  }

  String get currentLanguageName {
    final code = currentLanguageCode;
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return 'Français';
    }
  }

  bool get isUsingSystemLocale => _locale == null;

  Locale get systemLocale => _getSystemLocale();
}

