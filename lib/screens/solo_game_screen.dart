import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/solo_game_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/game_board.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/sound_button.dart';
import '../widgets/sound_icon_button.dart';
import '../models/game.dart';
import '../services/ai_service.dart';
import '../services/audio_controller.dart';
import '../services/admob_service.dart';

class SoloGameScreen extends StatefulWidget {
  final int gridSize;
  final AIDifficulty difficulty;

  const SoloGameScreen({
    super.key,
    required this.gridSize,
    required this.difficulty,
  });

  @override
  State<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends State<SoloGameScreen> {
  @override
  void initState() {
    super.initState();
    // Mettre la musique en sourdine quand on entre dans une partie solo
    AudioController.muteBackground();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SoloGameProvider>().startSoloGame(
        widget.gridSize,
        widget.difficulty,
      );
    });
  }

  @override
  void dispose() {
    // Remettre le volume de la musique quand on quitte la partie
    AudioController.unmuteBackground();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final provider = context.read<SoloGameProvider>();
        if (provider.currentGame?.status == 'active') {
          final shouldPop = await _showExitDialog(context) ?? false;
          if (shouldPop) {
            // Forcer la fin de partie avec défaite
            provider.forfeitGame();
            // Ne pas quitter immédiatement, l'écran de fin s'affichera automatiquement
          }
        } else {
          provider.reset();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: NotebookBackground(
          showMargin: false,
          child: SafeArea(
            child: Consumer<SoloGameProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.currentGame == null) {
                return _buildLoadingState();
              }

              if (provider.error != null && provider.currentGame == null) {
                return _buildErrorState(provider);
              }

              final game = provider.currentGame;
              if (game == null) {
                return _buildNoGameState();
              }

              if (game.status == 'finished') {
                return _buildGameFinished(context, game, provider);
              }

              return _buildActiveGame(game, provider);
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
            'Préparation de la partie...',
            style: GoogleFonts.caveat(
              fontSize: 24,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorState(SoloGameProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oups !',
              style: GoogleFonts.caveat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            NotebookButton(
              text: 'Réessayer',
              icon: Icons.refresh,
              onPressed: () {
                provider.startSoloGame(widget.gridSize, widget.difficulty);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGameState() {
    return Center(
      child: Text(
        'Aucune partie en cours',
        style: GoogleFonts.caveat(fontSize: 24, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildActiveGame(Game game, SoloGameProvider provider) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        // Bouton retour repositionné
        Padding(
          padding: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16, bottom: 8),
          child: Row(
            children: [
              SoundIconButton(
                icon: Icons.arrow_back,
                color: Colors.grey,
                iconSize: 24,
                padding: const EdgeInsets.all(8),
                onPressed: () async {
                  if (await _showExitDialog(context) ?? false) {
                    // Forcer la fin de partie avec défaite
                    provider.forfeitGame();
                  }
                },
              ),
            ],
          ),
        ),
        
        // Info joueurs avec timer
        _buildPlayersInfo(game, provider),
        
        // Plateau de jeu
        Expanded(
          child: GameBoard(
            game: game,
            onMove: provider.isMyTurn 
                ? (fromRow, fromCol, toRow, toCol) {
                    provider.makeMove(fromRow, fromCol, toRow, toCol);
                  }
                : null,
            isMyTurn: provider.isMyTurn,
          ),
        ),
        
        // Indicateur de tour
        _buildTurnIndicator(provider),
      ],
    );
  }

  Widget _buildPlayersInfo(Game game, SoloGameProvider provider) {
    final myPlayer = game.players.first;
    final aiPlayer = game.players.length > 1 ? game.players[1] : null;
    final isMyTurn = provider.isMyTurn;
    final remainingSeconds = isMyTurn 
        ? provider.remainingSeconds 
        : (provider.isAITimerRunning ? provider.aiRemainingSeconds : 45);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Joueur
          Expanded(
            child: _PlayerCard(
              label: 'Vous',
              score: myPlayer.score,
              color: AppTheme.player1Color,
              isActive: isMyTurn,
              showTimer: isMyTurn,
              remainingSeconds: remainingSeconds,
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
              'VS',
              style: GoogleFonts.caveat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          
          // IA
          if (aiPlayer != null)
            Expanded(
              child: _PlayerCard(
                label: 'IA',
                score: aiPlayer.score,
                color: AppTheme.player2Color,
                isActive: !isMyTurn,
                showTimer: !isMyTurn,
                remainingSeconds: remainingSeconds,
                isAI: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(SoloGameProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: provider.isMyTurn 
            ? AppTheme.player1Color.withOpacity(0.1)
            : AppTheme.player2Color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (provider.isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: provider.isMyTurn ? AppTheme.player1Color : AppTheme.player2Color,
              ),
            )
          else
            Icon(
              provider.isMyTurn ? Icons.touch_app : Icons.psychology,
              color: provider.isMyTurn ? AppTheme.player1Color : AppTheme.player2Color,
              size: 20,
            ),
          const SizedBox(width: 8),
          Text(
            provider.isMyTurn ? 'À vous de jouer !' : 'L\'IA réfléchit...',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: provider.isMyTurn ? AppTheme.player1Color : AppTheme.player2Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameFinished(BuildContext context, Game game, SoloGameProvider provider) {
    final winner = game.players.firstWhere(
      (p) => p.isWinner == true,
      orElse: () => game.players.first,
    );
    final isWinner = winner.userId != null && winner.userId! != 2;
    final myPlayer = game.players.first;
    final aiPlayer = game.players.length > 1 ? game.players[1] : null;

    // Jouer le son de victoire ou de défaite
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isWinner) {
        AudioController.playWinnerSound();
      } else {
        AudioController.playLosseSound();
      }
      
      // Afficher une publicité interstitielle après 2-3 parties
      // ⚠️ IMPORTANT: Uniquement sur l'écran de fin de partie (game.status == 'finished')
      if (game.status == 'finished') {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final adsRemoved = authProvider.user?.adsRemoved ?? false;
        AdMobService.onGameFinished(adsRemoved: adsRemoved);
      } else {
        debugPrint('⚠️ [SOLO] Tentative d\'afficher une pub alors que la partie n\'est pas terminée (status: ${game.status})');
      }
    });

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de résultat
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isWinner 
                    ? AppTheme.accentGold.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 80,
                color: isWinner ? AppTheme.accentGold : Colors.grey,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            // Titre
            Text(
              isWinner ? 'Victoire !' : 'Défaite',
              style: GoogleFonts.caveat(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: isWinner ? AppTheme.accentGoldDark : Colors.grey[700],
              ),
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 32),
            
            // Scores
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gridLine.withOpacity(0.5)),
                boxShadow: AppTheme.paperShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ScoreColumn(
                    label: 'Vous',
                    score: myPlayer.score,
                    isWinner: isWinner,
                    color: AppTheme.player1Color,
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    color: AppTheme.gridLine,
                  ),
                  if (aiPlayer != null)
                    _ScoreColumn(
                      label: 'IA',
                      score: aiPlayer.score,
                      isWinner: !isWinner,
                      color: AppTheme.player2Color,
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 40),
            
            // Boutons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NotebookButton(
                  text: 'Retour',
                  icon: Icons.arrow_back,
                  isOutlined: true,
                  backgroundColor: Colors.grey,
                  onPressed: () {
                    provider.reset();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 16),
                NotebookButton(
                  text: 'Rejouer',
                  icon: Icons.refresh,
                  onPressed: () {
                    provider.startSoloGame(widget.gridSize, widget.difficulty);
                  },
                ),
              ],
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  String _getDifficultyName() {
    switch (widget.difficulty) {
      case AIDifficulty.easy:
        return 'Niveau Débutant';
      case AIDifficulty.medium:
        return 'Niveau Normal';
      case AIDifficulty.hard:
        return 'Niveau Expert';
    }
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.paperWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.exit_to_app, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Quitter la partie ?',
                style: GoogleFonts.caveat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre progression sera perdue.',
                style: GoogleFonts.nunito(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SoundTextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.nunito(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SoundElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'Quitter',
                      style: GoogleFonts.nunito(color: Colors.white),
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
}

class _DifficultyBadge extends StatelessWidget {
  final AIDifficulty difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (difficulty) {
      case AIDifficulty.easy:
        color = Colors.green;
        icon = Icons.sentiment_satisfied_alt;
        break;
      case AIDifficulty.medium:
        color = Colors.orange;
        icon = Icons.sentiment_neutral;
        break;
      case AIDifficulty.hard:
        color = Colors.red;
        icon = Icons.local_fire_department;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final bool isActive;
  final bool showTimer;
  final int remainingSeconds;
  final bool isAI;

  const _PlayerCard({
    required this.label,
    required this.score,
    required this.color,
    required this.isActive,
    required this.showTimer,
    required this.remainingSeconds,
    this.isAI = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = showTimer && remainingSeconds <= 10;
    
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
              if (isAI) Icon(Icons.psychology, size: 16, color: color),
              if (isAI) const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.grey[600],
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
          if (showTimer) ...[
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

class _ScoreColumn extends StatelessWidget {
  final String label;
  final int score;
  final bool isWinner;
  final Color color;

  const _ScoreColumn({
    required this.label,
    required this.score,
    required this.isWinner,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isWinner)
          Icon(Icons.emoji_events, color: AppTheme.accentGold, size: 20),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          '$score',
          style: GoogleFonts.caveat(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'points',
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
