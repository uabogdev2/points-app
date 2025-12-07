import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admob_service.dart';
import '../theme/app_theme.dart';

/// Native Advanced Ad stylisée comme une position du classement
class LeaderboardNativeAdWidget extends StatefulWidget {
  const LeaderboardNativeAdWidget({super.key});

  @override
  State<LeaderboardNativeAdWidget> createState() => _LeaderboardNativeAdWidgetState();
}

class _LeaderboardNativeAdWidgetState extends State<LeaderboardNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 10; // 10 tentatives max (5 secondes au total)

  @override
  void initState() {
    super.initState();
    debugPrint('');
    debugPrint('🚀🚀🚀 [NATIVE_AD_LEADERBOARD] ========================================');
    debugPrint('🚀 [NATIVE_AD_LEADERBOARD] initState appelé - Widget monté');
    debugPrint('🚀 [NATIVE_AD_LEADERBOARD] AdMobService.isInitialized: ${AdMobService.isInitialized}');
    debugPrint('🚀 [NATIVE_AD_LEADERBOARD] AdMobService.isLoadingIds: ${AdMobService.isLoadingIds}');
    debugPrint('🚀🚀🚀 [NATIVE_AD_LEADERBOARD] ========================================');
    debugPrint('');
    
    // La logique de réessai est maintenant dans _loadNativeAd()
    // On appelle directement depuis initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNativeAd();
    });
  }

  Future<void> _loadNativeAd() async {
    debugPrint('');
    debugPrint('📢📢📢 [NATIVE_AD_LEADERBOARD] ========================================');
    debugPrint('📢 [NATIVE_AD_LEADERBOARD] Tentative de chargement de la pub native');
    debugPrint('📢📢📢 [NATIVE_AD_LEADERBOARD] ========================================');
    debugPrint('');
    
    final adUnitId = AdMobService.nativeAdvancedAdUnitId;
    
    debugPrint('📢 [NATIVE_AD_LEADERBOARD] Ad Unit ID récupéré: ${adUnitId ?? "NULL"}');
    debugPrint('📢 [NATIVE_AD_LEADERBOARD] AdMobService.isLoadingIds: ${AdMobService.isLoadingIds}');
    
    // 🎯 LOGIQUE DE TEMPORISATION : Réessayer si les IDs sont en cours de chargement
    if (adUnitId == null && (AdMobService.isLoadingIds || !AdMobService.isInitialized) && _retryAttempts < _maxRetryAttempts) {
      _retryAttempts++;
      debugPrint('⏳ [NATIVE_AD_LEADERBOARD] IDs en cours de chargement ou service non initialisé. Réessai #$_retryAttempts/$_maxRetryAttempts dans 500ms...');
      
      // Attendre un peu et réessayer
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Si le widget est toujours monté, relancer la tentative de chargement
      if (mounted) {
        _loadNativeAd(); // Réessayer
      }
      return;
    }
    
    // Ce log critique vérifiera si on arrive ici avec un ID null après le chargement
    debugPrint('➡️ [NATIVE_AD_LEADERBOARD] Tentative de chargement finale - ID Ad Unit: ${adUnitId ?? "NULL"}');
    
    if (adUnitId == null) {
      debugPrint('⚠️ [NATIVE_AD_LEADERBOARD] Abandon du chargement car adUnitId est NULL');
      debugPrint('⚠️ [NATIVE_AD_LEADERBOARD] Vérifiez que:');
      debugPrint('   1. AdMobService.initialize() a été appelé');
      debugPrint('   2. Les IDs ont été chargés depuis l\'API (/admob/ids)');
      debugPrint('   3. L\'ID native_advanced est configuré dans les settings');
      debugPrint('⚠️ [NATIVE_AD_LEADERBOARD] AdMobService.isInitialized: ${AdMobService.isInitialized}');
      debugPrint('⚠️ [NATIVE_AD_LEADERBOARD] AdMobService.isLoadingIds: ${AdMobService.isLoadingIds}');
      return;
    }

    debugPrint('✅ [NATIVE_AD_LEADERBOARD] Ad Unit ID valide, création de NativeAd...');

    // Utiliser un template style personnalisé pour format rectangulaire compact
    // Template small pour un format rectangulaire qui s'adapte mieux au bloc réduit
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small, // Small pour format rectangulaire compact
        mainBackgroundColor: Colors.transparent, // Transparent pour s'intégrer au fond blanc
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppTheme.primaryColor,
          size: 12.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.primaryColor,
          size: 15.0, // Taille réduite pour le format compact
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.primaryColor.withOpacity(0.7),
          size: 13.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.primaryColor.withOpacity(0.5),
          size: 11.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          debugPrint('✅✅✅ [NATIVE_AD_LEADERBOARD] Pub native CHARGÉE avec succès!');
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌❌❌ [NATIVE_AD_LEADERBOARD] Erreur chargement Native Advanced leaderboard');
          debugPrint('❌ [NATIVE_AD_LEADERBOARD] Code: ${error.code}');
          debugPrint('❌ [NATIVE_AD_LEADERBOARD] Message: ${error.message}');
          debugPrint('❌ [NATIVE_AD_LEADERBOARD] Domain: ${error.domain}');
          debugPrint('❌ [NATIVE_AD_LEADERBOARD] ResponseInfo: ${error.responseInfo}');
          ad.dispose();
          // Réinitialiser l'état en cas d'erreur pour éviter les bugs d'affichage
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _nativeAd = null;
            });
          }
        },
        onAdOpened: (_) {
          debugPrint('📢 [NATIVE_AD_LEADERBOARD] Pub native ouverte');
        },
        onAdClosed: (_) {
          debugPrint('📢 [NATIVE_AD_LEADERBOARD] Pub native fermée');
        },
        onAdClicked: (_) {
          debugPrint('📢 [NATIVE_AD_LEADERBOARD] Pub native cliquée');
        },
        onAdImpression: (_) {
          debugPrint('📢 [NATIVE_AD_LEADERBOARD] Impression de la pub native enregistrée');
        },
      ),
    );

    debugPrint('📢 [NATIVE_AD_LEADERBOARD] Appel de _nativeAd.load()...');
    _nativeAd?.load();
    debugPrint('📢 [NATIVE_AD_LEADERBOARD] _nativeAd.load() appelé');
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Masquer le bloc si la pub n'est pas chargée
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    // Style compact et moderne pour le bloc publicitaire
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.gridLine.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge, // Empêcher le badge de dépasser
        children: [
          // Zone pour la Native Advanced - format rectangulaire compact
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 50, 10), // Padding à droite pour le badge
            child: SizedBox(
              width: double.infinity,
              height: 100, // Hauteur réduite pour format rectangulaire compact
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AdWidget(ad: _nativeAd!),
              ),
            ),
          ),
          
          // Badge "Ad" à l'intérieur du bloc, en haut à droite
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'AD',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

