import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';

class AdMobService {
  static bool _isInitialized = false;
  static bool _isLoadingIds = false;
  static String? _appIdAndroid;
  static String? _appIdIos;
  static String? _nativeAdvancedAdUnitIdAndroid;
  static String? _nativeAdvancedAdUnitIdIos;
  static String? _interstitialAdUnitIdAndroid;
  static String? _interstitialAdUnitIdIos;
  static String? _interstitialVideoAdUnitIdAndroid;
  static String? _interstitialVideoAdUnitIdIos;
  
  static InterstitialAd? _interstitialAd;
  static InterstitialAd? _interstitialVideoAd;
  static int _gamesPlayed = 0;
  static const int _gamesBeforeAd = 2; // Afficher une pub après 2 parties
  
  /// Vérifie si AdMobService est initialisé
  static bool get isInitialized => _isInitialized;
  
  /// Vérifie si les IDs sont en cours de chargement
  static bool get isLoadingIds => _isLoadingIds;

  /// Initialise AdMob et charge les IDs depuis l'API
  /// Note: L'App ID (Publisher ID) est lu automatiquement depuis les fichiers natifs
  /// (AndroidManifest.xml pour Android et Info.plist pour iOS)
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ [ADMOB] Déjà initialisé, skip');
      return;
    }

    try {
      debugPrint('🚀 [ADMOB] Début de l\'initialisation...');
      
      // Charger les Ad Unit IDs depuis l'API
      await loadAdIds();
      
      // Initialiser AdMob
      // L'App ID est automatiquement lu depuis AndroidManifest.xml (Android) ou Info.plist (iOS)
      debugPrint('🚀 [ADMOB] Initialisation de MobileAds.instance...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      
      if (Platform.isAndroid) {
        debugPrint('📱 [ADMOB] Plateforme: Android');
        debugPrint('✅ [ADMOB] AdMob initialisé (App ID lu depuis AndroidManifest.xml)');
      } else if (Platform.isIOS) {
        debugPrint('📱 [ADMOB] Plateforme: iOS');
        debugPrint('✅ [ADMOB] AdMob initialisé (App ID lu depuis Info.plist)');
      }
      
      debugPrint('✅✅✅ [ADMOB] Initialisation complète!');
    } catch (e) {
      debugPrint('❌ [ADMOB] Erreur initialisation AdMob: $e');
      debugPrint('❌ [ADMOB] Stack trace: ${StackTrace.current}');
    }
  }

  /// Charge les IDs AdMob depuis l'API
  static Future<void> loadAdIds() async {
    if (_isLoadingIds) {
      debugPrint('⚠️ [ADMOB] Les IDs sont déjà en cours de chargement, skip');
      return;
    }
    
    _isLoadingIds = true;
    
    try {
      final url = '${ApiConfig.baseUrl}/admob/ids';
      debugPrint('📡 [ADMOB] Chargement des IDs AdMob: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // App IDs (identifiants du compte publicitaire)
        _appIdAndroid = data['app_id_android'] as String?;
        _appIdIos = data['app_id_ios'] as String?;
        
        // Ad Unit IDs Android (identifiants des unités publicitaires)
        _nativeAdvancedAdUnitIdAndroid = data['native_advanced_android'] as String?;
        _interstitialAdUnitIdAndroid = data['interstitial_android'] as String?;
        _interstitialVideoAdUnitIdAndroid = data['interstitial_video_android'] as String?;
        
        // Ad Unit IDs iOS (identifiants des unités publicitaires)
        _nativeAdvancedAdUnitIdIos = data['native_advanced_ios'] as String?;
        _interstitialAdUnitIdIos = data['interstitial_ios'] as String?;
        _interstitialVideoAdUnitIdIos = data['interstitial_video_ios'] as String?;

        debugPrint('✅ IDs AdMob chargés depuis l\'API');
        debugPrint('📱 App ID Android: ${_appIdAndroid ?? "NULL"}');
        debugPrint('📱 App ID iOS: ${_appIdIos ?? "NULL"}');
        debugPrint('📱 Native Advanced Android: ${_nativeAdvancedAdUnitIdAndroid ?? "NULL"}');
        debugPrint('📱 Native Advanced iOS: ${_nativeAdvancedAdUnitIdIos ?? "NULL"}');
        debugPrint('📱 Interstitiel Android: ${_interstitialAdUnitIdAndroid ?? "NULL"}');
        debugPrint('📱 Interstitiel iOS: ${_interstitialAdUnitIdIos ?? "NULL"}');
      } else {
        debugPrint('⚠️ Erreur HTTP ${response.statusCode} - Les IDs ne seront pas chargés depuis le serveur');
        debugPrint('⚠️ Réponse: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [ADMOB] Erreur chargement IDs AdMob depuis le serveur: $e');
      debugPrint('❌ [ADMOB] Stack trace: ${StackTrace.current}');
      debugPrint('⚠️ [ADMOB] Aucun ID chargé - Vérifiez la connexion au serveur et la configuration');
    } finally {
      _isLoadingIds = false;
    }
  }

  /// Retourne l'ID Native Advanced selon la plateforme
  static String? get nativeAdvancedAdUnitId {
    final id = Platform.isAndroid 
        ? _nativeAdvancedAdUnitIdAndroid 
        : Platform.isIOS 
            ? _nativeAdvancedAdUnitIdIos 
            : null;
    
    if (id == null) {
      debugPrint('⚠️ [ADMOB] nativeAdvancedAdUnitId est NULL pour ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "plateforme inconnue"}');
      debugPrint('⚠️ [ADMOB] Vérifiez que loadAdIds() a été appelé et que l\'ID est configuré dans les settings');
    }
    
    return id;
  }

  /// Retourne l'ID de l'interstitiel selon la plateforme
  static String? get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _interstitialAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _interstitialAdUnitIdIos;
    }
    return null;
  }

  /// Retourne l'ID de l'interstitiel vidéo selon la plateforme
  static String? get interstitialVideoAdUnitId {
    if (Platform.isAndroid) {
      return _interstitialVideoAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _interstitialVideoAdUnitIdIos;
    }
    return null;
  }

  /// Incrémente le compteur de parties et affiche une pub si nécessaire
  /// ⚠️ IMPORTANT: Cette méthode doit être appelée UNIQUEMENT sur l'écran de fin de partie
  /// Ne jamais appeler pendant une partie active (status: 'active' ou 'waiting')
  static void onGameFinished() {
    _gamesPlayed++;
    debugPrint('🎮 [ADMOB] Parties jouées: $_gamesPlayed');

    if (_gamesPlayed >= _gamesBeforeAd) {
      _gamesPlayed = 0;
      debugPrint('📢 [ADMOB] Affichage de la pub interstitielle (après $_gamesBeforeAd parties)');
      _loadAndShowInterstitial();
    } else {
      debugPrint('📢 [ADMOB] Pas encore de pub (${_gamesPlayed}/$_gamesBeforeAd parties)');
    }
  }

  /// Charge et affiche une publicité interstitielle (image ou vidéo)
  static Future<void> _loadAndShowInterstitial() async {
    try {
      // Préférer la vidéo, sinon l'image, selon la plateforme
      final adUnitId = interstitialVideoAdUnitId ?? interstitialAdUnitId;
      
      if (adUnitId == null) {
        debugPrint('⚠️ Aucun ID interstitiel disponible');
        return;
      }

      final isVideo = adUnitId == interstitialVideoAdUnitId;

      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ Pub interstitielle chargée (${isVideo ? "vidéo" : "image"})');
            if (isVideo) {
              _interstitialVideoAd = ad;
            } else {
              _interstitialAd = ad;
            }
            
            // Configurer les callbacks pour disposer après affichage
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('✅ Pub interstitielle fermée');
                ad.dispose();
                if (isVideo) {
                  _interstitialVideoAd = null;
                } else {
                  _interstitialAd = null;
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ Erreur affichage pub interstitielle: $error');
                ad.dispose();
                if (isVideo) {
                  _interstitialVideoAd = null;
                } else {
                  _interstitialAd = null;
                }
              },
            );
            
            ad.show();
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ Erreur chargement pub interstitielle: $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur affichage pub interstitielle: $e');
    }
  }

  /// Charge une publicité interstitielle en prévision
  static Future<void> preloadInterstitial() async {
    try {
      final adUnitId = interstitialVideoAdUnitId ?? interstitialAdUnitId;
      if (adUnitId == null) return;

      final isVideo = adUnitId == interstitialVideoAdUnitId;

      // Ne pas recharger si déjà chargée
      if (isVideo && _interstitialVideoAd != null) return;
      if (!isVideo && _interstitialAd != null) return;

      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ Pub interstitielle préchargée (${isVideo ? "vidéo" : "image"})');
            if (isVideo) {
              _interstitialVideoAd = ad;
            } else {
              _interstitialAd = ad;
            }
            
            // Configurer les callbacks pour disposer après affichage
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('✅ Pub interstitielle fermée');
                ad.dispose();
                if (isVideo) {
                  _interstitialVideoAd = null;
                } else {
                  _interstitialAd = null;
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ Erreur affichage pub interstitielle: $error');
                ad.dispose();
                if (isVideo) {
                  _interstitialVideoAd = null;
                } else {
                  _interstitialAd = null;
                }
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ Erreur préchargement pub interstitielle: $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur préchargement pub interstitielle: $e');
    }
  }

  /// Dispose des publicités interstitielles
  static void disposeInterstitials() {
    _interstitialAd?.dispose();
    _interstitialVideoAd?.dispose();
    _interstitialAd = null;
    _interstitialVideoAd = null;
  }
}

