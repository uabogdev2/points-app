import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
import '../models/game_mode.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import '../mixins/background_music_mixin.dart';
import 'solo_game_screen.dart';
import 'duo_game_screen.dart';
import 'create_private_game_screen.dart';
import 'join_private_game_screen.dart';
import 'invitation_screen.dart';

class GameModeSelectionScreen extends StatefulWidget {
  final GameMode mode;
  
  const GameModeSelectionScreen({super.key, required this.mode});

  @override
  State<GameModeSelectionScreen> createState() => _GameModeSelectionScreenState();
}

class _GameModeSelectionScreenState extends State<GameModeSelectionScreen> with BackgroundMusicMixin {
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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  String _getModeTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.mode) {
      case GameMode.solo:
        return '${l10n.solo} Mode';
      case GameMode.duo:
        return '${l10n.duo} Mode';
      case GameMode.matchmaking:
        return l10n.quickMatch;
      case GameMode.private:
        return l10n.privateGame;
      case GameMode.invitation:
        return 'Invitations';
    }
  }

  IconData _getModeIcon() {
    switch (widget.mode) {
      case GameMode.solo:
        return Icons.psychology;
      case GameMode.duo:
        return Icons.people_alt;
      case GameMode.matchmaking:
        return Icons.flash_on;
      case GameMode.private:
        return Icons.qr_code_2;
      case GameMode.invitation:
        return Icons.mail;
    }
  }

  Color _getModeColor() {
    switch (widget.mode) {
      case GameMode.solo:
        return AppTheme.inkBlue;
      case GameMode.duo:
        return const Color(0xFF7B1FA2);
      case GameMode.matchmaking:
        return AppTheme.accentGoldDark;
      case GameMode.private:
        return const Color(0xFF00796B);
      case GameMode.invitation:
        return Colors.orange;
    }
  }

  Widget _buildContent(BuildContext context) {
    switch (widget.mode) {
      case GameMode.solo:
        return _buildSoloSelection(context);
      case GameMode.duo:
        return _buildDuoSelection(context);
      case GameMode.matchmaking:
        return _buildMatchmakingSelection(context);
      case GameMode.private:
        return _buildPrivateSelection(context);
      case GameMode.invitation:
        return _buildInvitationSelection(context);
    }
  }

  Widget _buildSoloSelection(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section difficulté
          ChapterHeader(
            title: AppLocalizations.of(context)!.difficulty,
            subtitle: AppLocalizations.of(context)!.chooseDifficulty,
            icon: Icons.psychology,
          ).animate().fadeIn(duration: 300.ms),
          
          const SizedBox(height: 20),
          
          _DifficultyCard(
            title: AppLocalizations.of(context)!.beginner,
            subtitle: AppLocalizations.of(context)!.beginnerSubtitle,
            icon: Icons.sentiment_satisfied_alt,
            color: Colors.green,
            onTap: () => _showGridSizeDialog(context, AIDifficulty.easy),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
          
          const SizedBox(height: 12),
          
          _DifficultyCard(
            title: AppLocalizations.of(context)!.normal,
            subtitle: AppLocalizations.of(context)!.normalSubtitle,
            icon: Icons.sentiment_neutral,
            color: Colors.orange,
            onTap: () => _showGridSizeDialog(context, AIDifficulty.medium),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
          
          const SizedBox(height: 12),
          
          _DifficultyCard(
            title: AppLocalizations.of(context)!.expert,
            subtitle: AppLocalizations.of(context)!.expertSubtitle,
            icon: Icons.local_fire_department,
            color: Colors.red,
            onTap: () => _showGridSizeDialog(context, AIDifficulty.hard),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildDuoSelection(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Note style post-it
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.duoInfo,
                    style: GoogleFonts.caveat(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
          
          ChapterHeader(
            title: AppLocalizations.of(context)!.gridSize,
            subtitle: AppLocalizations.of(context)!.gridSizeSubtitle,
            icon: Icons.grid_on,
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 20),
          
          // Grilles de sélection
          ...GridSize.values.asMap().entries.map((entry) {
            final index = entry.key;
            final size = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GridSizeCard(
                size: size,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DuoGameScreen(gridSize: size.value),
                  ),
                ),
              ).animate().fadeIn(delay: (200 + index * 100).ms).slideX(begin: 0.1),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMatchmakingSelection(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.underDevelopment,
            style: GoogleFonts.caveat(
              fontSize: 28,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateSelection(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Note explicative
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.privateGameInfo,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
          
          ChapterHeader(
            title: AppLocalizations.of(context)!.options,
            subtitle: AppLocalizations.of(context)!.createOrJoin,
            icon: Icons.games,
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 20),
          
          // Créer une partie
          _OptionCard(
            title: AppLocalizations.of(context)!.createGame,
            subtitle: AppLocalizations.of(context)!.createGameSubtitle,
            icon: Icons.add_circle_outline,
            color: AppTheme.primaryColor,
            onTap: () => _showGridSizeDialogForPrivate(context, true),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
          
          const SizedBox(height: 12),
          
          // Rejoindre une partie
          _OptionCard(
            title: AppLocalizations.of(context)!.joinGame,
            subtitle: AppLocalizations.of(context)!.joinGameSubtitle,
            icon: Icons.login,
            color: AppTheme.accentGoldDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const JoinPrivateGameScreen(),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildInvitationSelection(BuildContext context) {
    return const InvitationScreen();
  }

  void _showGridSizeDialog(BuildContext context, AIDifficulty difficulty) {
    showDialog(
      context: context,
      builder: (context) => _NotebookDialog(
        title: AppLocalizations.of(context)!.gridSize,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GridSize.values.map((size) {
            return _DialogOption(
              icon: Icons.grid_on,
              label: size.label,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SoloGameScreen(
                      gridSize: size.value,
                      difficulty: difficulty,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showGridSizeDialogForPrivate(BuildContext context, bool isCreate) {
    showDialog(
      context: context,
      builder: (context) => _NotebookDialog(
        title: AppLocalizations.of(context)!.gridSize,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GridSize.values.map((size) {
            return _DialogOption(
              icon: Icons.grid_on,
              label: size.label,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePrivateGameScreen(gridSize: size.value),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Carte de difficulté style cahier
class _DifficultyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gridLine.withOpacity(0.5)),
            boxShadow: AppTheme.paperShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.caveat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de taille de grille style cahier
class _GridSizeCard extends StatelessWidget {
  final GridSize size;
  final VoidCallback onTap;

  const _GridSizeCard({
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gridLine.withOpacity(0.5)),
            boxShadow: AppTheme.paperShadow,
          ),
          child: Row(
            children: [
              // Mini grille visuelle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: _MiniGridPainter(size.value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      size.label,
                      style: GoogleFonts.caveat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      _getGridDescription(context, size),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow, color: AppTheme.primaryColor, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  String _getGridDescription(BuildContext context, GridSize size) {
    final l10n = AppLocalizations.of(context)!;
    switch (size) {
      case GridSize.small:
        return l10n.quickGame;
      case GridSize.medium:
        return l10n.classicGame;
      case GridSize.large:
        return l10n.strategicGame;
      case GridSize.xlarge:
        return l10n.expertGame;
    }
  }
}

/// Carte d'option style cahier
class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: AppTheme.paperShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.caveat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog style cahier
class _NotebookDialog extends StatelessWidget {
  final String title;
  final Widget content;

  const _NotebookDialog({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.paperWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.caveat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Container(
              width: 60,
              height: 3,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

/// Option dans un dialog
class _DialogOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Peintre pour mini grille
class _MiniGridPainter extends CustomPainter {
  final int gridSize;
  
  _MiniGridPainter(this.gridSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.4)
      ..strokeWidth = 1;
    
    final cellSize = size.width / gridSize;
    
    // Points
    final pointPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i <= gridSize; i++) {
      for (int j = 0; j <= gridSize; j++) {
        canvas.drawCircle(
          Offset(i * cellSize, j * cellSize),
          2,
          pointPaint,
        );
      }
    }
    
    // Quelques lignes de démonstration
    canvas.drawLine(
      Offset(0, 0),
      Offset(cellSize, 0),
      paint..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(cellSize, 0),
      Offset(cellSize, cellSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
