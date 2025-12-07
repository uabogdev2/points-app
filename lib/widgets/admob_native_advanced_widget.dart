import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

class AdMobNativeAdvancedWidget extends StatefulWidget {
  const AdMobNativeAdvancedWidget({super.key});

  @override
  State<AdMobNativeAdvancedWidget> createState() => _AdMobNativeAdvancedWidgetState();
}

class _AdMobNativeAdvancedWidgetState extends State<AdMobNativeAdvancedWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  Future<void>? _adLoadFuture;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 10; // 10 tentatives max (5 secondes au total)

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 [NATIVE_AD_WIDGET] initState appelé');
    _adLoadFuture = _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    final adUnitId = AdMobService.nativeAdvancedAdUnitId;
    
    // 🎯 LOGIQUE DE TEMPORISATION : Réessayer si les IDs sont en cours de chargement
    if (adUnitId == null && (AdMobService.isLoadingIds || !AdMobService.isInitialized) && _retryAttempts < _maxRetryAttempts) {
      _retryAttempts++;
      debugPrint('⏳ [NATIVE_AD_WIDGET] IDs en cours de chargement ou service non initialisé. Réessai #$_retryAttempts/$_maxRetryAttempts dans 500ms...');
      
      // Attendre un peu et réessayer
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Si le widget est toujours monté, relancer la tentative de chargement
      if (mounted) {
        _adLoadFuture = _loadNativeAd(); // Mettre à jour le Future
      }
      return;
    }
    
    // Ce log critique vérifiera si on arrive ici avec un ID null après le chargement
    debugPrint('➡️ [NATIVE_AD_WIDGET] Tentative de chargement finale - ID Ad Unit: ${adUnitId ?? "NULL"}');

    if (adUnitId == null) {
      debugPrint('⚠️ [NATIVE_AD_WIDGET] Abandon du chargement car adUnitId est NULL');
      debugPrint('⚠️ [NATIVE_AD_WIDGET] AdMobService.isInitialized: ${AdMobService.isInitialized}');
      debugPrint('⚠️ [NATIVE_AD_WIDGET] AdMobService.isLoadingIds: ${AdMobService.isLoadingIds}');
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          debugPrint('✅ [NATIVE_AD_WIDGET] Pub native chargée avec succès!');
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ [NATIVE_AD_WIDGET] Erreur chargement Native Advanced');
          debugPrint('❌ [NATIVE_AD_WIDGET] Code: ${error.code}');
          debugPrint('❌ [NATIVE_AD_WIDGET] Message: ${error.message}');
          debugPrint('❌ [NATIVE_AD_WIDGET] Domain: ${error.domain}');
          ad.dispose();
        },
      ),
    );

    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

