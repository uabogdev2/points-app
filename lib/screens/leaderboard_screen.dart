import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
import '../providers/statistics_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/leaderboard_native_ad_widget.dart';
import '../mixins/background_music_mixin.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with BackgroundMusicMixin {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    print('');
    print('🚀🚀🚀 [LEADERBOARD] ========================================');
    print('🚀 [LEADERBOARD] initState appelé - LeaderboardScreen monté');
    print('🚀🚀🚀 [LEADERBOARD] ========================================');
    print('');
    
    // Charger le classement au montage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📢 [LEADERBOARD] PostFrameCallback exécuté');
      if (mounted && !_hasLoaded) {
        _hasLoaded = true;
        print('📢 [LEADERBOARD] Chargement du classement...');
        context.read<StatisticsProvider>().loadLeaderboard();
      } else {
        print('⚠️ [LEADERBOARD] Widget non monté ou déjà chargé');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('');
    print('🔨 [LEADERBOARD] Build appelé');
    final statisticsProvider = context.watch<StatisticsProvider>();
    
    print('🔨 [LEADERBOARD] État:');
    print('  - isLoading: ${statisticsProvider.isLoading}');
    print('  - error: ${statisticsProvider.error}');
    print('  - leaderboard: ${statisticsProvider.leaderboard != null ? "non null (${statisticsProvider.leaderboard!.leaderboard.length} entrées)" : "null"}');

    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppTheme.paperWhite,
      body: NotebookBackground(
        showMargin: false,
        child: Column(
          children: [
            // En-tête avec design amélioré
            Padding(
              padding: EdgeInsets.only(top: topPadding + 50),
              child: _buildHeader().animate().fadeIn(duration: 300.ms),
            ),
            
            const SizedBox(height: 20),
          
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
                          AppLocalizations.of(context)!.loadingLeaderboard,
                          style: GoogleFonts.caveat(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : statisticsProvider.error != null
                    ? _buildErrorState(statisticsProvider.error!)
                    : statisticsProvider.leaderboard == null
                        ? _buildEmptyState()
                        : _LeaderboardContent(
                            leaderboard: statisticsProvider.leaderboard!,
                          ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withOpacity(0.15),
            AppTheme.accentGoldDark.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
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
                      AppLocalizations.of(context)!.topPlayers,
                      style: GoogleFonts.caveat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGoldDark,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.bestOfTheMoment,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppTheme.primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.stars,
                  color: AppTheme.accentGoldDark,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.joinRanking,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noLeaderboard,
              style: GoogleFonts.caveat(
                fontSize: 28,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.playToAppear,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.error,
              style: GoogleFonts.caveat(
                fontSize: 28,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            NotebookButton(
              text: AppLocalizations.of(context)!.retry,
              icon: Icons.refresh,
              onPressed: () {
                context.read<StatisticsProvider>().loadLeaderboard();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardContent extends StatelessWidget {
  final dynamic leaderboard;

  const _LeaderboardContent({
    required this.leaderboard,
  });

  @override
  Widget build(BuildContext context) {
    print('📋 [LEADERBOARD_CONTENT] Build appelé - ${leaderboard.leaderboard.length} entrées');
    
    if (leaderboard.leaderboard.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.leaderboard_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noLeaderboard,
                style: GoogleFonts.caveat(
                  fontSize: 28,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.playToAppear,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Position où insérer la bannière publicitaire (après la 1ère position)
    // Modifié de 2 à 1 pour permettre l'affichage même avec 1 seule entrée
    const int adBannerPosition = 1;
    final leaderboardLength = leaderboard.leaderboard.length;
    // Afficher la pub s'il y a au moins 1 entrée (au lieu de 2)
    final canShowAd = leaderboardLength >= 1;
    final int totalItems = leaderboardLength + (canShowAd ? 1 : 0);
    
    print('');
    print('📋📋📋 [LEADERBOARD_CONTENT] ========================================');
    print('📋 [LEADERBOARD_CONTENT] Build appelé');
    print('📋 [LEADERBOARD_CONTENT] Longueur classement: $leaderboardLength');
    print('📋 [LEADERBOARD_CONTENT] Position pub: $adBannerPosition');
    print('📋 [LEADERBOARD_CONTENT] canShowAd: $canShowAd (${leaderboardLength} >= 1)');
    print('📋 [LEADERBOARD_CONTENT] Total items: $totalItems');
    print('📋📋📋 [LEADERBOARD_CONTENT] ========================================');
    print('');
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Insérer la bannière publicitaire après la 1ère position
        if (index == adBannerPosition && canShowAd) {
          print('');
          print('🎯🎯🎯 [LEADERBOARD_CONTENT] ========================================');
          print('🎯 [LEADERBOARD_CONTENT] CRÉATION BANNIÈRE À L\'INDEX $index');
          print('🎯🎯🎯 [LEADERBOARD_CONTENT] ========================================');
          print('');
          return const LeaderboardNativeAdWidget()
              .animate()
              .fadeIn(delay: (index * 50).ms);
        }
        
        // Ajuster l'index pour les éléments après la bannière
        final adjustedIndex = index > adBannerPosition && canShowAd ? index - 1 : index;
        
        if (adjustedIndex >= leaderboard.leaderboard.length) {
          return const SizedBox.shrink();
        }
        
        final entry = leaderboard.leaderboard[adjustedIndex];
        final isTopThree = entry.rank <= 3;
        final isTopOne = entry.rank == 1;
        
        return _LeaderboardEntry(
          entry: entry,
          isTopThree: isTopThree,
          isTopOne: isTopOne,
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }
}

class _LeaderboardEntry extends StatefulWidget {
  final dynamic entry;
  final bool isTopThree;
  final bool isTopOne;

  const _LeaderboardEntry({
    required this.entry,
    required this.isTopThree,
    required this.isTopOne,
  });

  @override
  State<_LeaderboardEntry> createState() => _LeaderboardEntryState();
}

class _LeaderboardEntryState extends State<_LeaderboardEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isTopOne) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 2500),
        vsync: this,
      )..repeat();

      // Animation sinusoïdale pour une boucle fluide continue
      _scaleAnimation = Tween<double>(begin: 0.99, end: 1.01).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );

      // Animation de l'ombre synchronisée avec le scale
      _shadowAnimation = Tween<double>(begin: 0.12, end: 0.22).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (widget.isTopOne) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: EdgeInsets.only(bottom: widget.isTopOne ? 20 : 12),
      decoration: BoxDecoration(
        gradient: widget.isTopOne
            ? LinearGradient(
                colors: [
                  AppTheme.accentGold.withOpacity(0.18),
                  Colors.white,
                  AppTheme.accentGold.withOpacity(0.12),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.3, 0.7, 1.0],
              )
            : null,
        color: widget.isTopOne ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isTopThree
              ? _getRankColor(widget.entry.rank).withOpacity(
                  widget.isTopOne ? 0.9 : 0.6,
                )
              : AppTheme.gridLine.withOpacity(0.5),
          width: widget.isTopThree ? (widget.isTopOne ? 3.5 : 2.5) : 1.5,
        ),
        boxShadow: widget.isTopOne
            ? [
                BoxShadow(
                  color: AppTheme.accentGold.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : widget.isTopThree
                ? [
                    BoxShadow(
                      color: _getRankColor(widget.entry.rank).withOpacity(0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppTheme.paperShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.isTopOne ? 20 : 16),
        child: Row(
          children: [
            // Badge de rang
            _RankBadge(rank: widget.entry.rank),
            
            const SizedBox(width: 16),
            
            // Infos joueur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.entry.user.name,
                          style: GoogleFonts.nunito(
                            fontSize: widget.isTopOne ? 15 : 13,
                            fontWeight: FontWeight.bold,
                            color: widget.isTopOne
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isTopOne)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentGold,
                                AppTheme.accentGoldDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGold.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                AppLocalizations.of(context)!.pointsMaster,
                                style: GoogleFonts.caveat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.emoji_events,
                        value: '${widget.entry.statistic.gamesWon}',
                        color: widget.isTopOne ? AppTheme.primaryColor : AppTheme.accentGold,
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        icon: Icons.percent,
                        value: '${(widget.entry.statistic.winRate ?? 0).toStringAsFixed(0)}%',
                        color: AppTheme.successColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Score total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.entry.statistic.totalSquaresCompleted}',
                  style: GoogleFonts.caveat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: widget.isTopOne ? AppTheme.primaryColor : AppTheme.inkBlue,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.squares,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppTheme.primaryColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.isTopOne) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Créer une valeur sinusoïdale pour une boucle parfaitement fluide
          final double sinValue = (math.sin(_animationController.value * 2 * math.pi) + 1) / 2;
          final double scale = 0.99 + (sinValue * 0.02); // 0.99 à 1.01
          final double shadowOpacity = 0.12 + (sinValue * 0.10); // 0.12 à 0.22
          
          return Transform.scale(
            scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(shadowOpacity),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: content,
              ),
          );
        },
      );
    }
    
    return content;
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppTheme.accentGold;
      case 2:
        return const Color(0xFFC0C0C0); // Argent
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.gridLine;
    }
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    
    if (isTopThree) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(rank),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (rank == 1 ? AppTheme.primaryColor : _getRankColor(rank)).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: rank == 1
              ? const Icon(Icons.emoji_events, color: Colors.white, size: 26)
              : Text(
                  rank.toString(),
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      );
    }
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.gridLine.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.gridLine),
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: GoogleFonts.caveat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(int rank) {
    switch (rank) {
      case 1:
        return [AppTheme.primaryColor, AppTheme.primaryLight];
      case 2:
        return [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return [AppTheme.gridLine, AppTheme.gridLine.withOpacity(0.6)];
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey;
    }
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
