import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/matchmaking_provider.dart';
import '../providers/version_provider.dart';
import '../models/version_check.dart';
import '../models/user.dart';
import '../models/game_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/notebook_bottom_nav.dart';
import '../widgets/sound_button.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';
import 'game_mode_selection_screen.dart';
import 'statistics_screen.dart';
import 'leaderboard_screen.dart';
import 'waiting_for_opponent_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';
import '../mixins/background_music_mixin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with BackgroundMusicMixin {
  int _selectedIndex = 0;
  bool _isShowingDialog = false;

  Future<bool> _showExitDialog(BuildContext context) async {
    // Empêcher l'affichage multiple du dialogue
    if (_isShowingDialog) {
      return false;
    }

    _isShowingDialog = true;

    // Afficher une boîte de dialogue de confirmation
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppTheme.paperWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.gridLine.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.exit_to_app, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.quitApp,
                style: GoogleFonts.caveat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.quitAppConfirm,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SoundTextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: GoogleFonts.nunito(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SoundElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.quit,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

    _isShowingDialog = false;

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit && mounted) {
          // Quitter l'application
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else if (Platform.isIOS) {
            exit(0);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.paperWhite,
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  _HomeTab(),
                  StatisticsScreen(),
                  LeaderboardScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NotebookBottomNav(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _updateDialogShown = false;
  VersionProvider? _versionProvider;
  NotificationService? _notificationService;

  @override
  void initState() {
    super.initState();
    // Configurer le callback de navigation pour les notifications
    // Attendre un peu pour que l'état de connexion soit vérifié
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _setupNotificationNavigation();
        }
      });
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Écouter les changements du VersionProvider
    final versionProvider = context.read<VersionProvider>();
    if (_versionProvider != versionProvider) {
      _versionProvider?.removeListener(_onVersionProviderChanged);
      _versionProvider = versionProvider;
      versionProvider.addListener(_onVersionProviderChanged);
      
      // Vérifier immédiatement si la vérification est déjà terminée
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkAndShowUpdateDialog(context, versionProvider);
        }
      });
    }
    
    // Reconfigurer le callback si l'état de connexion change
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated && _notificationService != null) {
      // Vérifier s'il y a une action en attente quand l'utilisateur se connecte
      _checkPendingActionAfterLogin();
    }
  }
  
  Future<void> _checkPendingActionAfterLogin() async {
    final pendingAction = await StorageService.getPendingNotificationAction();
    if (pendingAction != null && pendingAction.isNotEmpty && mounted) {
      debugPrint('🔔 Action en attente trouvée après connexion: $pendingAction');
      // Attendre un peu pour que HomeScreen soit complètement chargé
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _handleNotificationAction(pendingAction);
          // Nettoyer l'action après traitement
          StorageService.clearPendingNotificationAction();
        }
      });
    }
  }

  void _setupNotificationNavigation() async {
    final authProvider = context.watch<AuthProvider>();
    // Accéder au NotificationService via une méthode publique ou créer une instance
    _notificationService = NotificationService();
    
    // Vérifier s'il y a une action en attente dans le stockage
    final pendingAction = await StorageService.getPendingNotificationAction();
    if (pendingAction != null && pendingAction.isNotEmpty && authProvider.isAuthenticated) {
      debugPrint('🔔 Action en attente trouvée au démarrage: $pendingAction');
      // Attendre que HomeScreen soit complètement chargé
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && authProvider.isAuthenticated) {
          _handleNotificationAction(pendingAction);
          StorageService.clearPendingNotificationAction();
        }
      });
    }
    
    _notificationService!.setNavigateToScreenCallback((String actionType) {
      // Vérifier l'état de connexion avant de naviguer
      if (!mounted) return;
      
      final isAuthenticated = authProvider.isAuthenticated;
      debugPrint('🔔 Tentative de navigation depuis notification: $actionType (connecté: $isAuthenticated)');
      
      if (!isAuthenticated) {
        // Si non connecté, stocker l'action et attendre la connexion
        debugPrint('⚠️ Utilisateur non connecté, action stockée: $actionType');
        // L'action est déjà stockée dans StorageService, elle sera traitée après connexion
        return;
      }
      
      // Attendre que l'app soit complètement chargée avant de naviguer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && authProvider.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _handleNotificationAction(actionType);
              }
            });
          }
        });
      });
    }, checkAuth: false); // On vérifie déjà l'auth dans le callback
  }

  void _handleNotificationAction(String actionType) {
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    
    // Vérifier à nouveau l'état de connexion
    if (!authProvider.isAuthenticated) {
      debugPrint('⚠️ Utilisateur non connecté, navigation annulée pour: $actionType');
      // Stocker l'action pour après la connexion
      StorageService.savePendingNotificationAction(actionType);
      return;
    }
    
    debugPrint('🔔 Navigation depuis notification: $actionType');
    
    // Attendre que l'écran soit complètement chargé avant de naviguer
    // Utiliser plusieurs postFrameCallback pour s'assurer que tout est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        
        // Vérifier à nouveau l'état de connexion
        if (!authProvider.isAuthenticated) {
          debugPrint('⚠️ Utilisateur déconnecté pendant l\'attente, navigation annulée');
          return;
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          
          try {
            switch (actionType) {
              case 'quick_game':
              case 'matchmaking':
                // Ouvrir l'écran de matchmaking
                debugPrint('🔔 Navigation vers matchmaking');
                _startQuickMatch(context);
                break;
              case 'solo':
                // Ouvrir l'écran de sélection Solo
                debugPrint('🔔 Navigation vers solo');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameModeSelectionScreen(mode: GameMode.solo),
                  ),
                );
                break;
              case 'duo':
                // Ouvrir l'écran de sélection Duo
                debugPrint('🔔 Navigation vers duo');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameModeSelectionScreen(mode: GameMode.duo),
                  ),
                );
                break;
              default:
                debugPrint('⚠️ Action inconnue: $actionType');
            }
          } catch (e, stackTrace) {
            debugPrint('❌ Erreur lors de la navigation: $e');
            debugPrint('❌ Stack trace: $stackTrace');
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _versionProvider?.removeListener(_onVersionProviderChanged);
    // Nettoyer le callback
    _notificationService?.onNavigateToScreen = null;
    super.dispose();
  }

  void _onVersionProviderChanged() {
    if (!mounted || _updateDialogShown) return;
    
    final versionProvider = _versionProvider;
    if (versionProvider == null) return;
    
    // Attendre que la vérification soit terminée
    if (versionProvider.isChecking) return;
    
    // Vérifier si une mise à jour est requise ou disponible
    if (versionProvider.versionCheck != null) {
      if (versionProvider.updateRequired) {
        _updateDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showUpdateDialog(context, versionProvider.versionCheck!, force: true);
          }
        });
      } else if (versionProvider.updateAvailable) {
        _updateDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showUpdateDialog(context, versionProvider.versionCheck!, force: false);
          }
        });
      }
    }
  }

  void _checkAndShowUpdateDialog(BuildContext context, VersionProvider versionProvider) {
    // Éviter d'afficher le dialog plusieurs fois
    if (_updateDialogShown) return;
    
    // Attendre que la vérification soit terminée
    if (versionProvider.isChecking) return;
    
    // Vérifier si une mise à jour est requise ou disponible
    if (versionProvider.versionCheck != null) {
      if (versionProvider.updateRequired) {
        _updateDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showUpdateDialog(context, versionProvider.versionCheck!, force: true);
          }
        });
      } else if (versionProvider.updateAvailable) {
        _updateDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showUpdateDialog(context, versionProvider.versionCheck!, force: false);
          }
        });
      }
    }
  }

  void _showUpdateDialog(BuildContext context, VersionCheck versionCheck, {required bool force}) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async {
          // Empêcher la fermeture avec le bouton retour si force = true
          if (force) {
            // Afficher un message si l'utilisateur essaie de fermer
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.updateRequiredMessage),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
            return false; // Empêcher la fermeture
          }
          return true; // Permettre la fermeture
        },
        child: AlertDialog(
          title: Text(force ? AppLocalizations.of(context)!.updateRequired : AppLocalizations.of(context)!.updateAvailable),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (versionCheck.message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(versionCheck.message!),
                ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.currentVersion(versionCheck.minVersion)),
              Text(AppLocalizations.of(context)!.latestVersion(versionCheck.latestVersion)),
            ],
          ),
          actions: [
            if (!force)
              SoundTextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.updateLater),
              ),
            SoundElevatedButton(
              onPressed: () async {
                try {
                  if (versionCheck.updateUrl != null && versionCheck.updateUrl!.isNotEmpty) {
                    final uri = Uri.parse(versionCheck.updateUrl!);
                    debugPrint('🔗 Tentative d\'ouverture de l\'URL: ${versionCheck.updateUrl}');
                    
                    // Essayer d'ouvrir l'URL directement
                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    
                    if (launched) {
                      debugPrint('✅ URL ouverte avec succès');
                    } else {
                      debugPrint('⚠️ Échec de l\'ouverture de l\'URL');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossible d\'ouvrir le lien. Veuillez mettre à jour manuellement depuis le store.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } else {
                    debugPrint('⚠️ Aucune URL de mise à jour fournie');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL de mise à jour non disponible. Veuillez mettre à jour depuis le store.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('❌ Erreur lors de l\'ouverture de l\'URL: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                
                // Ne pas fermer le dialog si c'est une mise à jour forcée
                if (!force) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return _buildContent(context, user);
  }
  
  Widget _buildContent(BuildContext context, User? user) {
    final topPadding = MediaQuery.of(context).padding.top;
    return NotebookBackground(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, topPadding + 60, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête avec profil utilisateur - Style cahier
            _buildProfileCard(user)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.2, end: 0),
            
            const SizedBox(height: 32),
            
            // Titre "Modes de jeu" style chapitre
            ChapterHeader(
              title: AppLocalizations.of(context)!.gameModes,
              subtitle: AppLocalizations.of(context)!.chooseAdventure,
              icon: Icons.sports_esports,
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 20),

            // Mode Solo
            GameModeCard(
              title: AppLocalizations.of(context)!.solo,
              subtitle: AppLocalizations.of(context)!.soloSubtitle,
              icon: Icons.psychology,
              color: AppTheme.inkBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameModeSelectionScreen(mode: GameMode.solo),
                  ),
                );
              },
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 12),

            // Mode Duo
            GameModeCard(
              title: AppLocalizations.of(context)!.duo,
              subtitle: AppLocalizations.of(context)!.duoSubtitle,
              icon: Icons.people_alt,
              color: const Color(0xFF7B1FA2), // Violet
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameModeSelectionScreen(mode: GameMode.duo),
                  ),
                );
              },
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 12),

            // Matchmaking rapide
            GameModeCard(
              title: AppLocalizations.of(context)!.quickMatch,
              subtitle: AppLocalizations.of(context)!.quickMatchSubtitle,
              icon: Icons.flash_on,
              color: AppTheme.accentGoldDark,
              isNew: true,
              onTap: () => _startQuickMatch(context),
            ).animate().fadeIn(delay: 500.ms),
            
            const SizedBox(height: 12),

            // Partie Privée
            GameModeCard(
              title: AppLocalizations.of(context)!.privateGame,
              subtitle: AppLocalizations.of(context)!.privateGameSubtitle,
              icon: Icons.qr_code_2,
              color: const Color(0xFF00796B), // Teal
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameModeSelectionScreen(mode: GameMode.private),
                  ),
                );
              },
            ).animate().fadeIn(delay: 600.ms),
            
            const SizedBox(height: 32),
            
            // Titre "Autres" style chapitre
            ChapterHeader(
              title: AppLocalizations.of(context)!.others,
              subtitle: AppLocalizations.of(context)!.helpAndSettings,
              icon: Icons.more_horiz,
            ).animate().fadeIn(delay: 700.ms),
            
            const SizedBox(height: 20),
            
            // Aide et Paramètres en ligne (icônes uniquement)
            Row(
              children: [
                Expanded(
                  child: _buildIconOnlyButton(
                    icon: Icons.help_outline,
                    color: AppTheme.inkBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpScreen(),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 800.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIconOnlyButton(
                    icon: Icons.settings,
                    color: const Color(0xFF7B1FA2), // Violet
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 900.ms),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  /// Construit la carte de profil style cahier
  Widget _buildProfileCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.gridLine.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppTheme.paperShadow,
      ),
      child: Row(
        children: [
          // Avatar avec bordure dorée
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.accentGold, AppTheme.accentGoldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: AppTheme.paperWhite,
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(
                      user?.name[0].toUpperCase() ?? 'U',
                      style: AppTheme.handwritingTitle.copyWith(fontSize: 28),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          
          // Infos utilisateur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.welcome,
                  style: AppTheme.bodyText.copyWith(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  user?.name ?? AppLocalizations.of(context)!.player,
                  style: AppTheme.handwritingSubtitle.copyWith(
                    fontSize: 26,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (user?.statistic != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatBadge(
                        Icons.emoji_events,
                        '${user!.statistic!.gamesWon}',
                        AppLocalizations.of(context)!.victories,
                        AppTheme.accentGold,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        Icons.local_fire_department,
                        '${user.statistic!.currentStreak}',
                        AppLocalizations.of(context)!.streak,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatBadge(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTheme.bodyText.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un bouton avec uniquement une icône (pour aide et paramètres)
  Widget _buildIconOnlyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AudioController.playClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.gridLine.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: AppTheme.paperShadow,
          ),
          child: Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startQuickMatch(BuildContext context) {
    debugPrint('🎮 [HOME] Bouton "Partie Rapide" pressé');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.gridSize),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.gridSize3x3),
              onTap: () {
                debugPrint('🎮 [HOME] Taille 3x3 sélectionnée');
                Navigator.pop(context);
                _findMatch(context, 3);
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.gridSize5x5),
              onTap: () {
                debugPrint('🎮 [HOME] Taille 5x5 sélectionnée');
                Navigator.pop(context);
                _findMatch(context, 5);
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.gridSize8x8),
              onTap: () {
                debugPrint('🎮 [HOME] Taille 8x8 sélectionnée');
                Navigator.pop(context);
                _findMatch(context, 8);
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.gridSize12x12),
              onTap: () {
                debugPrint('🎮 [HOME] Taille 12x12 sélectionnée');
                Navigator.pop(context);
                _findMatch(context, 12);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _findMatch(BuildContext context, int gridSize) {
    debugPrint('🔍 [HOME] Début recherche matchmaking - GridSize: $gridSize');
    
    // Nettoyer l'état des providers avant de lancer une nouvelle recherche
    final gameProvider = context.read<GameProvider>();
    final matchmakingProvider = context.read<MatchmakingProvider>();
    
    // ** ACTION CRITIQUE : Réinitialiser complètement l'état du GameProvider **
    // Cela garantit qu'aucune donnée de l'ancienne partie ne persiste
    debugPrint('🧹 [HOME] Réinitialisation complète de l\'état du GameProvider');
    gameProvider.resetStateForNewGame();
    
    // Annuler toute recherche en cours
    if (matchmakingProvider.isSearching) {
      debugPrint('🧹 [HOME] Annulation de la recherche en cours');
      matchmakingProvider.cancelSearch();
    }
    
    // Naviguer immédiatement vers l'écran de recherche
    // Utiliser addPostFrameCallback pour s'assurer que le dialog est bien fermé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('⏳ [HOME] Navigation vers WaitingForOpponentScreen...');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingForOpponentScreen(gridSize: gridSize),
          ),
        );
      }
    });
  }

}


