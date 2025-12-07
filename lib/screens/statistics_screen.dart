import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
import '../providers/statistics_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import '../mixins/background_music_mixin.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with BackgroundMusicMixin {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Charger les stats au montage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoaded) {
        _hasLoaded = true;
        context.read<StatisticsProvider>().loadStatistics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statisticsProvider = context.watch<StatisticsProvider>();
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.paperWhite,
      body: NotebookBackground(
        showMargin: false,
        child: Column(
          children: [
            SizedBox(height: topPadding + 50),
            // Contenu
            Expanded(
              child: statisticsProvider.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.loadingStats,
                    style: GoogleFonts.caveat(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : statisticsProvider.statistics == null
              ? _buildEmptyState()
              : _StatisticsContent(statistics: statisticsProvider.statistics!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noStatistics,
            style: GoogleFonts.caveat(
              fontSize: 28,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.playToUnlock,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  final dynamic statistics;

  const _StatisticsContent({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Résumé principal en grand
          _buildMainStats(context).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 24),
          
          // Section Matchmaking (pour le classement)
          _buildMatchmakingSection(context).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 24),
          
          // Section séries
          _buildStreakSection(context).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 24),
          
          // Grille de stats détaillées
          _buildSectionHeader(AppLocalizations.of(context)!.details, Icons.info_outline),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: AppLocalizations.of(context)!.bestScore,
                  value: statistics.bestScore.toString(),
                  icon: Icons.star,
                  color: Colors.amber,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: AppLocalizations.of(context)!.squaresCompleted,
                  value: statistics.totalSquaresCompleted.toString(),
                  icon: Icons.grid_on,
                  color: AppTheme.inkBlue,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats(BuildContext context) {
    final winRate = statistics.winRate ?? 0.0;
    final gamesPlayed = statistics.gamesPlayed;
    final gamesWon = statistics.gamesWon;
    final gamesLost = statistics.gamesLost;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, color: Colors.white.withOpacity(0.9), size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.overview,
                style: GoogleFonts.caveat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats principales en grille
          Row(
            children: [
              Expanded(
                child: _MainStatItem(
                  value: gamesPlayed.toString(),
                  label: AppLocalizations.of(context)!.games,
                  icon: Icons.sports_esports,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _MainStatItem(
                  value: gamesWon.toString(),
                  label: AppLocalizations.of(context)!.victories,
                  icon: Icons.emoji_events,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _MainStatItem(
                  value: '${winRate.toStringAsFixed(0)}%',
                  label: AppLocalizations.of(context)!.rate,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.winRate,
                    style: GoogleFonts.nunito(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${winRate.toStringAsFixed(1)}%',
                    style: GoogleFonts.caveat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: winRate / 100,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.caveat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchmakingSection(BuildContext context) {
    final gamesPlayedMatchmaking = statistics.gamesPlayedMatchmaking ?? 0;
    final gamesWonMatchmaking = statistics.gamesWonMatchmaking ?? 0;
    final gamesLostMatchmaking = statistics.gamesLostMatchmaking ?? 0;
    final winRateMatchmaking = statistics.winRateMatchmaking ?? 0.0;
    
    if (gamesPlayedMatchmaking == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.flash_on, color: Colors.grey[400], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.playMatchmaking,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withOpacity(0.15),
            AppTheme.accentGoldDark.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: AppTheme.accentGoldDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.matchmaking,
                      style: GoogleFonts.caveat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGoldDark,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.forRanking,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CompactStatCard(
                  title: AppLocalizations.of(context)!.games,
                  value: gamesPlayedMatchmaking.toString(),
                  icon: Icons.sports_esports,
                  color: AppTheme.accentGoldDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStatCard(
                  title: AppLocalizations.of(context)!.victories,
                  value: gamesWonMatchmaking.toString(),
                  icon: Icons.emoji_events,
                  color: AppTheme.accentGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStatCard(
                  title: AppLocalizations.of(context)!.defeats,
                  value: gamesLostMatchmaking.toString(),
                  icon: Icons.sentiment_dissatisfied,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentGold.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: AppTheme.accentGoldDark, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.winRate,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${winRateMatchmaking.toStringAsFixed(1)}%',
                  style: GoogleFonts.caveat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGoldDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gridLine.withOpacity(0.5)),
        boxShadow: AppTheme.paperShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.streak,
                style: GoogleFonts.caveat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StreakItem(
                  label: AppLocalizations.of(context)!.currentStreak,
                  value: statistics.currentStreak,
                  isActive: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StreakItem(
                  label: AppLocalizations.of(context)!.longestStreak,
                  value: statistics.longestStreak,
                  isActive: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _MainStatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.caveat(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gridLine.withOpacity(0.5)),
        boxShadow: AppTheme.paperShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.caveat(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.caveat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StreakItem extends StatelessWidget {
  final String label;
  final int value;
  final bool isActive;

  const _StreakItem({
    required this.label,
    required this.value,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.deepOrange.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? Colors.deepOrange.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                Icon(
                  Icons.local_fire_department,
                  color: Colors.deepOrange,
                  size: 20,
                ),
              const SizedBox(width: 4),
              Text(
                value.toString(),
                style: GoogleFonts.caveat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.deepOrange : Colors.grey[700],
                ),
              ),
            ],
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
