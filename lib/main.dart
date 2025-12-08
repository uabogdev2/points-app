import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Généré automatiquement par FlutterFire CLI
import 'package:Points_Points/l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/matchmaking_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/invitation_provider.dart';
import 'providers/version_provider.dart';
import 'providers/solo_game_provider.dart';
import 'providers/duo_game_provider.dart';
import 'providers/audio_settings_provider.dart';
import 'providers/notification_settings_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/purchase_provider.dart';
import 'services/device_service.dart';
import 'services/audio_controller.dart';
import 'services/admob_service.dart';
import 'theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/first_login_dialog.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase AVANT de lancer l'app (nécessaire pour AuthService)
  // Mais avec un timeout court pour ne pas bloquer trop longtemps
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 5),
    );
    debugPrint('✅ Firebase initialisé avec succès');
  } catch (e) {
    debugPrint('❌ Erreur initialisation Firebase: $e');
    // Continuer quand même - l'app pourra fonctionner sans Firebase
    // mais l'authentification ne fonctionnera pas
  }
  
  // Initialiser DeviceService en arrière-plan (non bloquant)
  DeviceService.initialize().catchError((e) {
    debugPrint('❌ Erreur initialisation DeviceService (non bloquant): $e');
  });
  
  // Initialiser AudioController
  AudioController.init().catchError((e) {
    debugPrint('❌ Erreur initialisation AudioController (non bloquant): $e');
  });
  
  // 🎯 CRITIQUE : Initialiser AdMob avec timeout pour ne pas bloquer le démarrage
  // On attend l'initialisation mais avec un timeout pour ne pas bloquer l'app
  try {
    await AdMobService.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ [MAIN] Timeout initialisation AdMob (10s) - L\'app continue quand même');
        return;
      },
    );
    debugPrint('✅ [MAIN] AdMob initialisé avec succès');
  } catch (e) {
    debugPrint('❌ [MAIN] Erreur initialisation AdMob (non bloquant): $e');
    // L'app continue quand même - les pubs ne s'afficheront simplement pas
  }
  
  // 🚀 OPTIMISATION COMPÉTITION : Préconnexion Socket.IO au démarrage
  // Cela réduit drastiquement la latence lors de la recherche de match
  Future.delayed(const Duration(seconds: 2), () {
    SocketService().preconnect().catchError((e) {
      debugPrint('⚠️ [MAIN] Erreur préconnexion Socket.IO (non bloquant): $e');
    });
  });
  
  // Lancer l'app
  runApp(const PointsMasterApp());
}

class PointsMasterApp extends StatefulWidget {
  const PointsMasterApp({super.key});

  @override
  State<PointsMasterApp> createState() => _PointsMasterAppState();
}

class _PointsMasterAppState extends State<PointsMasterApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Mettre en pause la musique quand l'app passe en arrière-plan
        AudioController.bgPlayer.pause();
        debugPrint('⏸️ [AUDIO] Musique mise en pause (app en arrière-plan)');
        break;
      case AppLifecycleState.resumed:
        // Reprendre la musique quand l'app revient au premier plan
        if (AudioController.isMusicEnabled) {
          AudioController.bgPlayer.play();
          debugPrint('▶️ [AUDIO] Musique reprise (app au premier plan)');
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = LocaleProvider();
            // Attendre un peu pour que la locale soit chargée
            Future.delayed(const Duration(milliseconds: 100), () {
              if (provider.isLoading) {
                debugPrint('⏳ [MAIN] LocaleProvider encore en chargement...');
              }
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = AuthProvider();
            // Initialiser de manière asynchrone sans bloquer
            provider.initialize().catchError((e) {
              debugPrint('❌ Erreur initialisation AuthProvider: $e');
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = VersionProvider();
            // Initialiser de manière asynchrone sans bloquer
            provider.checkVersion().catchError((e) {
              debugPrint('❌ Erreur initialisation VersionProvider: $e');
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => MatchmakingProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => InvitationProvider()),
        ChangeNotifierProvider(create: (_) => SoloGameProvider()),
        ChangeNotifierProvider(create: (_) => DuoGameProvider()),
        ChangeNotifierProvider(create: (_) => AudioSettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            key: ValueKey(localeProvider.locale.toString()), // Force la reconstruction quand la locale change
            title: 'Points Master',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const _AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const _HomeScreenWithExitConfirm(),
            },
          );
        },
      ),
    );
  }
}

class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  bool _forceShowLogin = false;
  bool _showSplash = true;
  DateTime? _splashStartTime;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();
    
    // Timeout de sécurité : après 7 secondes, forcer l'affichage de la page de login
    // (6 secondes pour le splash + 1 seconde de marge)
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isLoading) {
          setState(() {
            _forceShowLogin = true;
            _showSplash = false;
          });
          // Forcer l'arrêt du chargement
          authProvider.forceStopLoading();
        }
      }
    });
  }

  void _onSplashComplete() {
    if (mounted && _splashStartTime != null) {
      // S'assurer que le splash screen dure au moins 6 secondes
      final elapsed = DateTime.now().difference(_splashStartTime!);
      final remaining = const Duration(seconds: 6) - elapsed;
      
      if (remaining.isNegative || remaining.inMilliseconds <= 0) {
        // 20 secondes écoulées, on peut continuer
        setState(() {
          _showSplash = false;
        });
      } else {
        // Attendre le temps restant pour atteindre 20 secondes
        Future.delayed(remaining, () {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher le SplashScreen animé - TOUJOURS pendant 6 secondes minimum
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Si on force l'affichage du login
        if (_forceShowLogin) {
          return const LoginScreen();
        }

        if (authProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.paperWhite,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) => Text(
                      AppLocalizations.of(context)!.connectionInProgress,
                      style: AppTheme.bodyText.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return _FirstLoginWrapper(child: const HomeScreen());
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

/// Wrapper pour vérifier et afficher le popup de première connexion
class _FirstLoginWrapper extends StatefulWidget {
  final Widget child;

  const _FirstLoginWrapper({required this.child});

  @override
  State<_FirstLoginWrapper> createState() => _FirstLoginWrapperState();
}

class _FirstLoginWrapperState extends State<_FirstLoginWrapper> {
  bool _hasCheckedFirstLogin = false;
  bool _isShowingDialog = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Attendre un peu pour que l'utilisateur soit chargé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLogin();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Vérifier l'action en attente après que tout soit chargé
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated && _hasCheckedFirstLogin && !_isShowingDialog) {
      // L'action sera traitée automatiquement par HomeScreen
      // Pas besoin de faire quoi que ce soit ici
    }
  }

  Future<void> _checkFirstLogin() async {
    // Éviter les appels multiples
    if (_isChecking || _hasCheckedFirstLogin || _isShowingDialog) {
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      
      if (user == null) {
        setState(() {
          _hasCheckedFirstLogin = true;
          _isChecking = false;
        });
        return;
      }

      // Vérifier si c'est un nouvel utilisateur selon la base de données
      // Le popup ne doit s'afficher que pour les nouveaux utilisateurs détectés par le backend
      final isNewUserFromDb = await StorageService.isNewUserFromDb();
      final hasCompleted = await StorageService.hasCompletedFirstLogin();
      
      debugPrint('🔍 Vérification première connexion - isNewUserFromDb: $isNewUserFromDb, hasCompleted: $hasCompleted, user: ${user.name}');
      
      // Afficher le popup uniquement si :
      // 1. C'est un nouvel utilisateur détecté par la base de données
      // 2. Il n'a pas encore complété la première connexion
      if (isNewUserFromDb && !hasCompleted && !_isShowingDialog && mounted) {
        // Afficher le popup de première connexion
        setState(() {
          _isShowingDialog = true;
        });

        final newName = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => FirstLoginDialog(
            currentName: user.name,
            currentAvatarUrl: user.avatarUrl,
          ),
        );

        if (newName != null && newName.isNotEmpty && mounted) {
          try {
            // Mettre à jour le nom
            final updatedUser = await ApiService.updateProfile(name: newName);
            authProvider.updateUser(updatedUser);
            
            // Marquer comme complété AVANT de continuer
            await StorageService.setHasCompletedFirstLogin(true);
            
            debugPrint('✅ Première connexion complétée avec le nom: $newName');
          } catch (e) {
            debugPrint('❌ Erreur lors de la mise à jour du nom: $e');
            // Afficher une erreur mais continuer quand même
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur lors de la mise à jour du nom: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _hasCheckedFirstLogin = true;
          _isShowingDialog = false;
          _isChecking = false;
        });
        
        // Après avoir vérifié la première connexion, l'action en attente sera traitée par HomeScreen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedFirstLogin) {
      return widget.child; // Afficher l'enfant pendant la vérification
    }
    return widget.child;
  }
}

/// Wrapper pour HomeScreen avec confirmation de sortie
// Wrapper simplifié - la gestion de la sortie est maintenant dans HomeScreen
// Pas besoin de PopScope ici car HomeScreen gère déjà la sortie avec son propre modal
class _HomeScreenWithExitConfirm extends StatelessWidget {
  const _HomeScreenWithExitConfirm();

  @override
  Widget build(BuildContext context) {
    // Retourner directement HomeScreen sans PopScope
    // HomeScreen gère déjà la sortie avec son propre PopScope et modal
    return const HomeScreen();
  }
}
