import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/duo_game_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/game_board.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/sound_button.dart';
import '../widgets/sound_icon_button.dart';
import '../models/game.dart';
import '../services/audio_controller.dart';
import '../services/admob_service.dart';

class DuoGameScreen extends StatefulWidget {
  final int gridSize;

  const DuoGameScreen({super.key, required this.gridSize});

  @override
  State<DuoGameScreen> createState() => _DuoGameScreenState();
}

class _DuoGameScreenState extends State<DuoGameScreen> {
  @override
  void initState() {
    super.initState();
    // Mettre la musique en sourdine quand on entre dans une partie duo
    AudioController.muteBackground();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DuoGameProvider>().startDuoGame(widget.gridSize);
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
        final provider = context.read<DuoGameProvider>();
        if (provider.currentGame?.status == 'active') {
          final shouldPop = await _showExitDialog(context) ?? false;
          if (shouldPop) {
            // Terminer la partie sans gagnant/perdant et afficher l'écran de fin
            provider.endGameWithoutWinner();
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
          child: Consumer<DuoGameProvider>(
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
            'Préparation du duel...',
            style: GoogleFonts.caveat(
              fontSize: 24,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorState(DuoGameProvider provider) {
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
                provider.startDuoGame(widget.gridSize);
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

  Widget _buildActiveGame(Game game, DuoGameProvider provider) {
    final currentPlayerPosition = provider.currentPlayerId == game.players[0].id ? 1 : 2;
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
                    provider.endGameWithoutWinner();
                  }
                },
              ),
            ],
          ),
        ),
        
        // Info joueurs avec timer
        _buildPlayersInfo(game, provider),
        
        // Indicateur de tour central
        _buildTurnBanner(currentPlayerPosition, provider.remainingSeconds),
        
        // Plateau de jeu
        Expanded(
          child: GameBoard(
            game: game,
            onMove: (fromRow, fromCol, toRow, toCol) {
              provider.makeMove(fromRow, fromCol, toRow, toCol);
            },
            isMyTurn: provider.isMyTurn,
          ),
        ),
        
        // Instruction
        Container(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Passez le téléphone à Joueur $currentPlayerPosition',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
            ],
          );
  }

  Widget _buildPlayersInfo(Game game, DuoGameProvider provider) {
    final player1 = game.players[0];
    final player2 = game.players.length > 1 ? game.players[1] : null;
    final currentPlayerId = provider.currentPlayerId;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Joueur 1
          Expanded(
            child: _PlayerCard(
              label: 'Joueur 1',
              score: player1.score,
              color: AppTheme.player1Color,
              isActive: currentPlayerId == player1.id,
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
          
          // Joueur 2
          if (player2 != null)
            Expanded(
              child: _PlayerCard(
                label: 'Joueur 2',
                score: player2.score,
                color: AppTheme.player2Color,
                isActive: currentPlayerId == player2.id,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTurnBanner(int playerNumber, int remainingSeconds) {
    final color = playerNumber == 1 ? AppTheme.player1Color : AppTheme.player2Color;
    final isUrgent = remainingSeconds <= 10;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Tour du Joueur $playerNumber',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.red : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: isUrgent ? Colors.white : Colors.white.withOpacity(0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  '${remainingSeconds}s',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildGameFinished(BuildContext context, Game game, DuoGameProvider provider) {
    final player1 = game.players.firstWhere((p) => p.position == 1);
    final player2 = game.players.firstWhere((p) => p.position == 2);
    
    // Vérifier s'il y a un gagnant (si aucun joueur n'a isWinner = true, c'est qu'on a quitté)
    final hasWinner = game.players.any((p) => p.isWinner == true);
    final isDraw = hasWinner && player1.score == player2.score;
    final winner = hasWinner ? game.players.firstWhere((p) => p.isWinner == true) : null;
    
    // Pour le mode duo local, on ne joue pas de son car c'est un jeu local
    // Les sons de victoire/défaite sont pour les parties en ligne uniquement

    // Afficher une publicité interstitielle après 2-3 parties
    // ⚠️ IMPORTANT: Uniquement sur l'écran de fin de partie (game.status == 'finished')
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (game.status == 'finished') {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final adsRemoved = authProvider.user?.adsRemoved ?? false;
        AdMobService.onGameFinished(adsRemoved: adsRemoved);
      } else {
        debugPrint('⚠️ [DUO] Tentative d\'afficher une pub alors que la partie n\'est pas terminée (status: ${game.status})');
      }
    });

    // Déterminer le message à afficher
    String titleMessage;
    IconData resultIcon;
    Color resultColor;
    
    if (!hasWinner) {
      // Partie terminée sans gagnant (quand on quitte)
      titleMessage = 'Partie terminée';
      resultIcon = Icons.flag;
      resultColor = Colors.grey;
    } else if (isDraw) {
      titleMessage = 'Égalité !';
      resultIcon = Icons.handshake;
      resultColor = Colors.grey;
    } else {
      // Il y a un gagnant
      final winnerPosition = winner!.position ?? 1;
      final winnerColor = winnerPosition == 1 ? 'bleu' : 'rouge';
      titleMessage = 'Joueur $winnerColor a gagné !';
      resultIcon = Icons.emoji_events;
      resultColor = AppTheme.accentGold;
    }

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
                color: (!hasWinner || isDraw)
                    ? Colors.grey.withOpacity(0.1)
                    : AppTheme.accentGold.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                resultIcon,
                size: 80,
                color: resultColor,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            // Titre
            Text(
              titleMessage,
              style: GoogleFonts.caveat(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: (!hasWinner || isDraw) ? Colors.grey[700] : AppTheme.accentGoldDark,
              ),
              textAlign: TextAlign.center,
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
                    label: 'Joueur bleu',
                    score: player1.score,
                    isWinner: hasWinner && !isDraw && winner?.position == 1,
                    color: AppTheme.player1Color,
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    color: AppTheme.gridLine,
                  ),
                  _ScoreColumn(
                    label: 'Joueur rouge',
                    score: player2.score,
                    isWinner: hasWinner && !isDraw && winner?.position == 2,
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
                  text: 'Revanche',
                  icon: Icons.refresh,
                  onPressed: () {
                    provider.startDuoGame(widget.gridSize);
                  },
                ),
              ],
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
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
                'La partie en cours sera perdue.',
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

class _PlayerCard extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final bool isActive;

  const _PlayerCard({
    required this.label,
    required this.score,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
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
