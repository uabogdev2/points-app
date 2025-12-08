import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/game_board.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/sound_button.dart';
import '../widgets/sound_icon_button.dart';
import '../models/game.dart';
import '../services/audio_controller.dart';
import '../services/admob_service.dart';

class GameScreen extends StatefulWidget {
  final int gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // AJOUTER UN CHAMP POUR SUIVRE L'ID ACTUEL AFFICHÉ
  int? _lastGameId; 
  bool _hasShownFinishedScreen = false;
  bool _isNavigatingAway = false;
  // Protection supplémentaire : suivre l'ID de la partie pour laquelle on a déjà affiché l'écran de fin
  int? _finishedGameId;
  
  @override
  void initState() {
    super.initState();
    // Initialiser _lastGameId avec l'ID de la partie à charger
    // Cela évite que la première vérification déclenche une réinitialisation incorrecte
    _lastGameId = widget.gameId;
    // Réinitialiser TOUS les drapeaux pour cette nouvelle instance de GameScreen
    // Cela garantit qu'on ne réaffiche pas l'écran de fin d'une partie précédente
    _hasShownFinishedScreen = false;
    _isNavigatingAway = false;
    _finishedGameId = null;
    AudioController.muteBackground();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().loadGame(widget.gameId);
    });
  }

  @override
  void didUpdateWidget(GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le gameId change (ne devrait normalement pas arriver, mais protection)
    if (oldWidget.gameId != widget.gameId) {
      debugPrint('🔄 [SCREEN] GameId changé: ${oldWidget.gameId} -> ${widget.gameId}. Réinitialisation complète.');
      _lastGameId = widget.gameId;
      _hasShownFinishedScreen = false;
      _isNavigatingAway = false;
      _finishedGameId = null;
      // Recharger la nouvelle partie
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<GameProvider>().loadGame(widget.gameId);
        }
      });
    }
  }

  @override
  void dispose() {
    AudioController.unmuteBackground();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final gameProvider = context.read<GameProvider>();
    final game = gameProvider.currentGame;
    
    if (game?.status == 'finished') {
      // Nettoyer complètement et retourner à l'accueil
      gameProvider.leaveGame();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
      return false; // Empêcher le pop normal
    }

    if (game?.status == 'active') {
      final shouldForfeit = await _showForfeitDialog(context);
      if (shouldForfeit == true) {
        await gameProvider.forfeitGame();
        // Après abandon, retourner à l'accueil
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return false;
      }
      return false;
    }
    
    // Pour les autres cas (waiting, etc.), nettoyer et retourner
    gameProvider.leaveGame();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
    return false;
  }

  Future<bool?> _showForfeitDialog(BuildContext context) {
    return showDialog<bool>(
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
                child: const Icon(Icons.flag, size: 32, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.forfeit,
                style: GoogleFonts.caveat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.forfeitMessage,
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
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
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
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(
                        AppLocalizations.of(context)!.forfeitAction,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
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
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: NotebookBackground(
          showMargin: false,
          child: SafeArea(
            child: Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              // Vérifier que le contexte est toujours monté
              if (!context.mounted) {
                return const SizedBox.shrink();
              }

              if (gameProvider.isLoading && gameProvider.currentGame == null) {
                return _buildLoadingState();
              }

              if (gameProvider.error != null && gameProvider.currentGame == null) {
                return _buildErrorState(gameProvider);
              }

              final game = gameProvider.currentGame;
              
              // PROTECTION : Si on est en train de naviguer depuis l'écran de fin,
              // ne pas afficher l'état "no game" immédiatement
              // Cela empêche la fermeture automatique de l'écran de fin
              if (game == null) {
                // Si on a déjà affiché l'écran de fin et qu'on navigue, attendre la navigation
                if (_isNavigatingAway && _finishedGameId != null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return _buildNoGameState();
              }

              // --- LOGIQUE CRITIQUE DE RÉINITIALISATION DU DRAPEAU ---
              // Si un jeu est présent ET que son ID est différent du dernier ID, 
              // cela signifie que nous sommes passés à une NOUVELLE PARTIE.
              if (game.id != _lastGameId) {
                // Réinitialiser TOUS les drapeaux pour la nouvelle partie
                _hasShownFinishedScreen = false;
                _isNavigatingAway = false;
                _finishedGameId = null; // Réinitialiser aussi l'ID de la partie terminée
                debugPrint('🔄 [SCREEN] Nouveau Game ID détecté: ${game.id} (précédent: $_lastGameId). Tous les drapeaux réinitialisés.');
              }
              // Toujours mettre à jour l'ID après vérification.
              _lastGameId = game.id;
              // ----------------------------------------------------

              // Ceci est la condition qui doit déclencher l'affichage unique :
              // Vérifier que :
              // 1. La partie est terminée
              // 2. On n'a pas encore affiché l'écran de fin pour CETTE partie spécifique
              // 3. On n'est pas en train de naviguer
              // 4. Cette partie n'a pas déjà été marquée comme terminée
              // 5. CRITIQUE : Le game.id correspond bien au widget.gameId (protection contre les anciennes parties)
              if (game.status == 'finished' && 
                  !_hasShownFinishedScreen && 
                  !_isNavigatingAway &&
                  _finishedGameId != game.id &&
                  game.id == widget.gameId) { // PROTECTION CRITIQUE : vérifier que c'est bien la partie actuelle
                // MARQUER COMME AFFICHÉ IMMÉDIATEMENT pour cette partie spécifique
                _hasShownFinishedScreen = true;
                _finishedGameId = game.id; // Mémoriser l'ID de la partie terminée
                debugPrint('✅ [SCREEN] Affichage écran de fin pour partie ${game.id}');
                
                return _GameFinishedScreen(
                  game: game,
                  currentUserId: gameProvider.currentUserId,
                  onLeave: () async {
                    if (_isNavigatingAway) return;
                    _isNavigatingAway = true;
                    
                    // 1. RÉINITIALISER TOUS LES DRAPEAUX AVANT DE NETTOYER
                    // Cela empêche l'affichage de l'écran de fin si on revient rapidement
                    _hasShownFinishedScreen = false;
                    _finishedGameId = null;
                    _lastGameId = null; // Réinitialiser aussi pour forcer la détection d'une nouvelle partie
                    debugPrint('🧹 [SCREEN] Tous les drapeaux réinitialisés avant nettoyage');
                    
                    // 2. Nettoyage du Provider
                    gameProvider.leaveGame();
                    
                    // 3. Navigation
                    if (context.mounted) {
                      // Utiliser un post-frame callback pour s'assurer que le nettoyage
                      // du Provider est pris en compte avant la navigation
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/home');
                        }
                      });
                    }
                  },
                );
              }
              
              // Si la partie est terminée mais qu'on a déjà affiché l'écran, OU si ce n'est pas la partie actuelle
              // Afficher un écran de chargement ou un message
              if (game.status == 'finished' && 
                  (game.id != widget.gameId || // PROTECTION : si ce n'est pas la partie actuelle
                   _hasShownFinishedScreen || 
                   _isNavigatingAway || 
                   _finishedGameId == game.id)) {
                // Si ce n'est pas la partie actuelle, nettoyer et retourner à l'accueil
                if (game.id != widget.gameId) {
                  debugPrint('⚠️ [SCREEN] Partie terminée mais ID différent (actuel: ${widget.gameId}, reçu: ${game.id}). Nettoyage et retour.');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      gameProvider.leaveGame();
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  });
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (game.status == 'waiting' || game.players.length < 2) {
                return _WaitingScreen(game: game);
              }

              return _ActiveGameScreen(
                game: game,
                gameProvider: gameProvider,
                onBackPressed: () async {
                  if (await _onWillPop()) {
                    if (mounted) Navigator.of(context).pop();
                  }
                },
              );
            },
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.loadingGame,
            style: GoogleFonts.caveat(
              fontSize: 24,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorState(GameProvider gameProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.error,
              style: GoogleFonts.caveat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              gameProvider.error ?? AppLocalizations.of(context)!.error,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            NotebookButton(
              text: AppLocalizations.of(context)!.retry,
              icon: Icons.refresh,
              onPressed: () => gameProvider.loadGame(widget.gameId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGameState() {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.gameNotFound,
        style: GoogleFonts.caveat(fontSize: 24, color: Colors.grey[600]),
      ),
    );
  }
}

/// Écran d'attente
class _WaitingScreen extends StatelessWidget {
  final Game game;

  const _WaitingScreen({required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
          
          const SizedBox(height: 32),
          
          Text(
            AppLocalizations.of(context)!.waiting,
            style: GoogleFonts.caveat(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            AppLocalizations.of(context)!.waitingOpponent,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran de jeu actif - DESIGN COMPACT ET PROPRE
class _ActiveGameScreen extends StatelessWidget {
  final Game game;
  final GameProvider gameProvider;
  final VoidCallback onBackPressed;

  const _ActiveGameScreen({
    required this.game,
    required this.gameProvider,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header compact
        _buildCompactHeader(context),
        
        // Scores compacts (très réduits)
        _buildCompactScores(context),
        
        // Plateau de jeu - PREND TOUT L'ESPACE
        Expanded(
          child: GameBoard(
            game: game,
            onMove: gameProvider.isMyTurn
                ? (fromRow, fromCol, toRow, toCol) {
                    gameProvider.makeMove(fromRow, fromCol, toRow, toCol);
                  }
                : null,
            isMyTurn: gameProvider.isMyTurn,
          ),
        ),
        
        // Indicateur de tour compact
        _buildCompactTurnIndicator(context),
        
        // Loading
        if (gameProvider.isLoading)
          Container(
            height: 2,
            child: LinearProgressIndicator(
              color: AppTheme.primaryColor,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: AppTheme.gridLine.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          SoundIconButton(
            icon: Icons.arrow_back,
            color: Colors.grey,
            iconSize: 24,
            padding: const EdgeInsets.all(8),
            onPressed: onBackPressed,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.onlineGame,
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.gameNumber(game.id),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactScores(BuildContext context) {
    final player1 = game.players.isNotEmpty ? game.players[0] : null;
    final player2 = game.players.length > 1 ? game.players[1] : null;
    final currentUserId = gameProvider.currentUserId;
    final remainingSeconds = gameProvider.isTimerRunning ? gameProvider.remainingSeconds : null;

    // Le timer s'affiche pour le joueur qui a la main (isActive), visible par tous
    final player1IsActive = player1 != null && game.currentPlayerId == player1.userId;
    final player2IsActive = player2 != null && game.currentPlayerId == player2.userId;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Joueur 1
          if (player1 != null)
            Expanded(
              child: _PlayerCard(
                label: player1.user?.name ?? AppLocalizations.of(context)!.player1,
                score: player1.score,
                color: AppTheme.player1Color,
                isActive: player1IsActive,
                showTimer: player1IsActive, // Timer visible pour tous si ce joueur a la main
                remainingSeconds: remainingSeconds,
                isMe: player1.userId == currentUserId,
                player: player1,
              ),
            ),
          
          // VS central
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              AppLocalizations.of(context)!.vs,
              style: GoogleFonts.caveat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          
          // Joueur 2
          if (player2 != null)
            Expanded(
              child: _PlayerCard(
                label: player2.user?.name ?? AppLocalizations.of(context)!.player2,
                score: player2.score,
                color: AppTheme.player2Color,
                isActive: player2IsActive,
                showTimer: player2IsActive, // Timer visible pour tous si ce joueur a la main
                remainingSeconds: remainingSeconds,
                isMe: player2.userId == currentUserId,
                player: player2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactTurnIndicator(BuildContext context) {
    final isUrgent = gameProvider.isTimerRunning && gameProvider.remainingSeconds <= 10;
    final turnColor = gameProvider.isMyTurn
        ? (isUrgent ? Colors.red : AppTheme.player1Color)
        : AppTheme.player2Color;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: turnColor.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (gameProvider.isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: turnColor,
              ),
            )
          else
            Icon(
              gameProvider.isMyTurn ? Icons.touch_app : Icons.hourglass_empty,
              color: turnColor,
              size: 20,
            ),
          const SizedBox(width: 8),
          Text(
            gameProvider.isMyTurn ? AppLocalizations.of(context)!.yourTurn : AppLocalizations.of(context)!.opponentTurn,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: turnColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de joueur PROPRE inspirée du mode solo
class _PlayerCard extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final bool isActive;
  final bool showTimer;
  final int? remainingSeconds;
  final bool isMe;
  final GamePlayer player;

  const _PlayerCard({
    required this.label,
    required this.score,
    required this.color,
    required this.isActive,
    required this.showTimer,
    this.remainingSeconds,
    required this.isMe,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = showTimer && remainingSeconds != null && remainingSeconds! <= 10;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : AppTheme.gridLine.withOpacity(0.5),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isMe)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.you,
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: GoogleFonts.caveat(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (showTimer && remainingSeconds != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isUrgent ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 12,
                    color: isUrgent ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${remainingSeconds}s',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUrgent ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Écran de fin de partie
class _GameFinishedScreen extends StatefulWidget {
  final Game game;
  final int? currentUserId;
  final VoidCallback onLeave;

  const _GameFinishedScreen({
    required this.game,
    required this.currentUserId,
    required this.onLeave,
  });

  @override
  State<_GameFinishedScreen> createState() => _GameFinishedScreenState();
}

class _GameFinishedScreenState extends State<_GameFinishedScreen> {
  @override
  void initState() {
    super.initState();
    // Jouer le son de victoire ou de défaite
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myPlayer = widget.game.players.firstWhere(
        (p) => p.userId == widget.currentUserId,
        orElse: () => widget.game.players.first,
      );
      
      final winners = widget.game.players.where((p) => p.isWinner == true).toList();
      final isWinner = myPlayer.isWinner == true;
      final isDraw = winners.isEmpty;
      
      if (!isDraw) {
        if (isWinner) {
          AudioController.playWinnerSound();
        } else {
          AudioController.playLosseSound();
        }
      }
      
      // Afficher une publicité interstitielle après 2-3 parties
      // ⚠️ IMPORTANT: Uniquement sur l'écran de fin de partie (game.status == 'finished')
      if (widget.game.status == 'finished') {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final adsRemoved = authProvider.user?.adsRemoved ?? false;
        AdMobService.onGameFinished(adsRemoved: adsRemoved);
      } else {
        debugPrint('⚠️ [GAME] Tentative d\'afficher une pub alors que la partie n\'est pas terminée (status: ${widget.game.status})');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myPlayer = widget.game.players.firstWhere(
      (p) => p.userId == widget.currentUserId,
      orElse: () => widget.game.players.first,
    );
    
    final winners = widget.game.players.where((p) => p.isWinner == true).toList();
    final isWinner = myPlayer.isWinner == true;
    final isDraw = winners.isEmpty;
    
    String resultMessage;
    IconData resultIcon;
    Color resultColor;
    
    final l10n = AppLocalizations.of(context)!;
    if (isDraw) {
      resultMessage = l10n.draw;
      resultIcon = Icons.handshake;
      resultColor = Colors.orange;
    } else if (isWinner) {
      resultMessage = l10n.victory;
      resultIcon = Icons.emoji_events;
      resultColor = AppTheme.accentGold;
    } else {
      resultMessage = l10n.defeat;
      resultIcon = Icons.sentiment_dissatisfied;
      resultColor = Colors.grey;
    }

    return PopScope(
      canPop: false, // Empêcher la fermeture automatique avec le bouton retour
      onPopInvoked: (didPop) {
        // Si l'utilisateur appuie sur retour, appeler onLeave
        if (!didPop) {
          widget.onLeave();
        }
      },
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: resultColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                resultIcon,
                size: 80,
                color: resultColor,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            Text(
              resultMessage,
              style: GoogleFonts.caveat(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: resultColor == AppTheme.accentGold 
                    ? AppTheme.accentGoldDark 
                    : resultColor,
              ),
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gridLine.withOpacity(0.5)),
                boxShadow: AppTheme.paperShadow,
              ),
              child: Column(
                children: widget.game.players.map((player) {
                  final isMe = player.userId == widget.currentUserId;
                  final playerColor = widget.game.players.indexOf(player) == 0 
                      ? AppTheme.player1Color 
                      : AppTheme.player2Color;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: playerColor.withOpacity(0.2),
                          backgroundImage: player.user?.avatarUrl != null
                              ? NetworkImage(player.user!.avatarUrl!)
                              : null,
                          child: player.user?.avatarUrl == null
                              ? Text(
                                  player.user?.name[0].toUpperCase() ?? 'P',
                                  style: GoogleFonts.caveat(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: playerColor,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    player.user?.name ?? '${AppLocalizations.of(context)!.player} ${player.position}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (isMe)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.you,
                                        style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (player.isWinner == true)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      size: 14,
                                      color: AppTheme.accentGold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.winner,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: AppTheme.accentGoldDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        
                        Text(
                          '${player.score}',
                          style: GoogleFonts.caveat(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: playerColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 32),
            
            NotebookButton(
              text: AppLocalizations.of(context)!.backToHome,
              icon: Icons.home,
              width: double.infinity,
              onPressed: widget.onLeave,
            ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

