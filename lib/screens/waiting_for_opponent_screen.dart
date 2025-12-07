import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/matchmaking_provider.dart';
import '../providers/game_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/sound_button.dart';
import '../widgets/sound_icon_button.dart';
import '../mixins/background_music_mixin.dart';
import 'game_screen.dart';

class WaitingForOpponentScreen extends StatefulWidget {
  final int gridSize;

  const WaitingForOpponentScreen({
    super.key,
    required this.gridSize,
  });

  @override
  State<WaitingForOpponentScreen> createState() => _WaitingForOpponentScreenState();
}

class _WaitingForOpponentScreenState extends State<WaitingForOpponentScreen>
    with SingleTickerProviderStateMixin, BackgroundMusicMixin {
  MatchmakingProvider? _provider;
  late AnimationController _pulseController;
  Timer? _statusCheckTimer;
  bool _hasStartedSearch = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 [WAITING] Écran initialisé - GridSize: ${widget.gridSize}');
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider == null) {
      _provider = context.read<MatchmakingProvider>();
      _provider!.addListener(_onProviderChanged);
      
      // Démarrer la recherche une fois le provider disponible
      if (!_hasStartedSearch) {
        _hasStartedSearch = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startSearch();
            _startStatusCheck();
          }
        });
      }
    }
  }

  /// Vérifie périodiquement l'état de la partie - POLLING ULTRA-RAPIDE
  /// 
  /// DÉTECTION INITIALE (500ms pendant 2.5s) :
  /// - Disponibilité d'un adversaire qui rejoint la partie
  /// - Changement de statut de 'waiting' à 'active'
  /// - Synchronisation initiale avec le serveur
  /// - Détection immédiate si l'adversaire a déjà rejoint
  /// 
  /// POLLING STABLE (1s ensuite) :
  /// - Vérification continue de l'état de la partie
  /// - Détection de changements d'état
  /// - Gestion des erreurs réseau temporaires
  void _startStatusCheck() {
    _statusCheckTimer?.cancel();
    
    int pollCount = 0;
    const Duration fastInterval = Duration(milliseconds: 500); // Ultra-rapide les 5 premières fois (2.5s)
    const Duration normalInterval = Duration(seconds: 1); // Puis 1s pour stabilité et économie de ressources
    
    // Polling intelligent : ultra-rapide au début pour détection immédiate, puis stable pour économie
    _statusCheckTimer = Timer.periodic(fastInterval, (timer) async {
      pollCount++;
      
      // Passer à 1s après 5 tentatives (2.5 secondes) pour réduire la charge serveur
      // Exponential backoff doux : évite la surcharge tout en restant réactif
      if (pollCount > 5) {
        timer.cancel();
        _statusCheckTimer = Timer.periodic(normalInterval, (newTimer) async {
          await _performStatusCheck(newTimer);
        });
        return;
      }
      
      await _performStatusCheck(timer);
    });
  }
  
  /// Effectue une vérification de l'état de la partie sur le serveur
  /// Détecte : adversaire rejoint, partie active, erreurs réseau
  Future<void> _performStatusCheck(Timer timer) async {
    if (!mounted || _provider == null) {
      timer.cancel();
      return;
    }
    
    final waitingGame = _provider!.waitingGame;
    if (waitingGame == null) {
      timer.cancel();
      return;
    }
    
    // Si la partie est active, arrêter le timer immédiatement
    if (waitingGame.status == 'active') {
      timer.cancel();
      if (mounted) {
        debugPrint('✅ [WAITING] Partie active détectée (status local)');
        _navigateToGame(waitingGame.id);
      }
      return;
    }
    
    // Vérifier l'état sur le serveur - polling intelligent
    try {
      final game = await ApiService.getGame(waitingGame.id);
      
      if (game.status == 'active' && game.players.length >= 2) {
        debugPrint('✅ [WAITING] Partie active détectée via polling intelligent');
        timer.cancel();
        _provider!.updateWaitingGame(game);
        if (mounted) {
          _navigateToGame(game.id);
        }
      } else if (game.status != 'waiting' || game.players.length < 1) {
        debugPrint('⚠️ [WAITING] Partie invalide détectée');
        timer.cancel();
        if (mounted) {
          _showNoMatchFound();
        }
      }
    } catch (e) {
      // Ne pas spammer les logs - seulement les erreurs critiques
      if (e.toString().contains('404') || e.toString().contains('introuvable')) {
        debugPrint('⚠️ [WAITING] Partie introuvable (404)');
        timer.cancel();
        if (mounted) {
          _showNoMatchFound();
        }
      }
      // Autres erreurs : continuer le polling (peut être temporaire)
    }
  }

  void _showNoMatchFound() {
    if (!mounted || _provider == null) return;
    
    _provider!.cancelSearch();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recherche annulée - Aucune partie trouvée',
                style: GoogleFonts.nunito(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _startSearch() async {
    if (_provider == null) return;
    
    debugPrint('🔍 [WAITING] Début de la recherche...');
    
    try {
      final game = await _provider!.findMatch(widget.gridSize);
      
      if (game != null && mounted) {
        debugPrint('✅ [WAITING] Partie trouvée immédiatement! Navigation...');
        _navigateToGame(game.id);
      } else {
        debugPrint('⏳ [WAITING] En attente d\'un adversaire...');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [WAITING] Erreur lors de la recherche: $e');
      debugPrint('❌ [WAITING] Stack: $stackTrace');
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('introuvable') || 
            errorStr.contains('404') || 
            errorStr.contains('timeout') ||
            errorStr.contains('aucune partie')) {
          _showNoMatchFound();
        } else {
          _showError(e.toString());
        }
      }
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _pulseController.dispose();
    if (_provider != null) {
      _provider!.removeListener(_onProviderChanged);
      // Ne pas appeler cancelSearch() ici car il appelle notifyListeners()
      // Utiliser un microtask pour annuler côté serveur si nécessaire
      final waitingGame = _provider!.waitingGame;
      if (_provider!.isSearching && waitingGame != null) {
        debugPrint('🚫 [WAITING] Annulation recherche - Game ID: ${waitingGame.id}');
        Future.microtask(() {
          ApiService.cancelMatch(waitingGame.id).catchError((e) {
            debugPrint('⚠️ [WAITING] Erreur annulation serveur (non bloquant): $e');
          });
        });
      }
    }
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted || _provider == null) return;
    
    final waitingGame = _provider!.waitingGame;
    
    // Si un adversaire a rejoint et la partie est active
    if (waitingGame != null && waitingGame.status == 'active') {
      debugPrint('✅ [WAITING] Adversaire rejoint via listener! Navigation...');
      _statusCheckTimer?.cancel();
      _navigateToGame(waitingGame.id);
    }
    
    // Gérer les erreurs
    if (_provider!.error != null) {
      debugPrint('❌ [WAITING] Erreur: ${_provider!.error}');
      if (mounted) {
        _showError(_provider!.error!);
      }
    }
  }

  void _navigateToGame(int gameId) {
    if (!mounted) return;
    
    debugPrint('✅ [WAITING] Navigation vers GameScreen (ID: $gameId)');
    
    // Nettoyer l'état du GameProvider avant de naviguer
    final gameProvider = context.read<GameProvider>();
    gameProvider.resetStateForNewGame();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(gameId: gameId),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _cancelSearch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppTheme.paperWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppTheme.gridLine.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.cancel_outlined, size: 32, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                'Annuler la recherche ?',
                style: GoogleFonts.caveat(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'La recherche sera annulée et la partie sera supprimée.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: AppTheme.gridLine,
                          width: 1.5,
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(
                        'Non',
                        style: GoogleFonts.nunito(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(
                        'Oui, annuler',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      debugPrint('❌ [WAITING] Recherche annulée par l\'utilisateur');
      if (_provider != null && _provider!.waitingGame != null) {
        await ApiService.cancelMatch(_provider!.waitingGame!.id).catchError((e) {
          debugPrint('⚠️ [WAITING] Erreur annulation serveur (non bloquant): $e');
        });
      }
      _provider?.cancelSearch();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: NotebookBackground(
        child: Column(
          children: [
            // Bouton retour repositionné
            Padding(
              padding: EdgeInsets.only(top: topPadding + 32, left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  SoundIconButton(
                    icon: Icons.close,
                    color: Colors.grey,
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    onPressed: _cancelSearch,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<MatchmakingProvider>(
                builder: (context, provider, child) {
                  return SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSearchAnimation()
                                .animate()
                                .fadeIn(duration: 500.ms)
                                .scale(begin: const Offset(0.8, 0.8)),
                            
                            const SizedBox(height: 40),
                            
                            Text(
                              'Recherche en cours...',
                              style: GoogleFonts.caveat(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 200.ms),
                            
                            const SizedBox(height: 12),
                            
                            Text(
                              'Préparation d\'un duel ${widget.gridSize}×${widget.gridSize}',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ).animate().fadeIn(delay: 300.ms),
                            
                            const SizedBox(height: 8),
                            
                            if (provider.waitingGame != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Partie #${provider.waitingGame!.id}',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ).animate().fadeIn(delay: 400.ms),
                            
                            const SizedBox(height: 48),
                            
                            _buildProgressIndicator(),
                            
                            const SizedBox(height: 48),
                            
                            NotebookButton(
                              text: 'Annuler la recherche',
                              icon: Icons.close,
                              isOutlined: true,
                              backgroundColor: Colors.grey,
                              onPressed: _cancelSearch,
                            ).animate().fadeIn(delay: 500.ms),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAnimation() {
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Center(
            child: Container(
              width: 140 + (_pulseController.value * 20),
              height: 140 + (_pulseController.value * 20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05 + _pulseController.value * 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_search,
                      color: AppTheme.primaryColor,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.gridLine.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + (_pulseController.value * 0.7),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Recherche d\'un adversaire de votre niveau',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
