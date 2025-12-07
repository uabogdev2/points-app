import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';

/// SplashScreen premium avec design moderne
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _timer;
  double _progress = 0.0;
  String _version = '1.0.0';
  
  static const Duration _splashDuration = Duration(seconds: 6);
  static const Duration _progressDuration = Duration(seconds: 5);
  
  @override
  void initState() {
    super.initState();
    _loadVersion();
    
    debugPrint('⏱️ [SPLASH] Démarrage du splash screen - Durée: ${_splashDuration.inSeconds} secondes');
    debugPrint('⏱️ [SPLASH] Barre de progression - Durée: ${_progressDuration.inSeconds} secondes');
    
    // Contrôleur pour la progression (5 secondes pour 0 à 100%)
    _progressController = AnimationController(
      duration: _progressDuration,
      vsync: this,
    );
    
    // Contrôleur pour l'animation du logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Contrôleur pour l'effet de pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Animation de progression 0 à 100
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    // Animation de scale du logo (légère pulsation)
    _logoScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));
    
    // Animation de rotation subtile
    _logoRotationAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));
    
    // Animation de pulsation pour les éléments décoratifs
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Écouter les changements de progression
    _progressAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _progress = _progressAnimation.value;
        });
      }
    });
    
    // Démarrer toutes les animations
    _progressController.forward();
    
    // Compléter après exactement 20 secondes
    _timer = Timer(_splashDuration, () {
      if (mounted) {
        debugPrint('✅ [SPLASH] Splash screen terminé après ${_splashDuration.inSeconds} secondes');
        widget.onComplete();
      }
    });
  }
  
  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
        });
      }
    } catch (e) {
      // Garder la version par défaut en cas d'erreur
    }
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppTheme.paperWhite,
      body: Stack(
        children: [
          // Fond quadrillé style cahier (conservé)
          CustomPaint(
            painter: _NotebookBackgroundPainter(),
            size: size,
          ),
          
          // Éléments décoratifs animés en arrière-plan
          ..._buildDecorativeElements(size),
          
          // Contenu principal centré
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Logo avec animations (remonté)
                    _buildAnimatedLogo(),
                    
                    const SizedBox(height: 24),
                    
                    // Titre simple
                    _buildSimpleTitle(),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline simple
                    _buildSimpleTagline(),
                  ],
                ),
              ),
            ),
          ),
          
          // Barre de progression premium en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPremiumProgressBar(),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildDecorativeElements(Size size) {
    return [
      // Cercles décoratifs animés
      Positioned(
        top: size.height * 0.1,
        right: -50,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: size.height * 0.2,
        left: -30,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 - (_pulseAnimation.value - 0.8) * 0.5,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.inkBlue.withOpacity(0.15),
                      AppTheme.inkBlue.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
  
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoScaleAnimation, _logoRotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotationAnimation.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/image/logo-app.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    )
        .animate()
        .scale(
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 1.0),
          duration: 800.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 600.ms);
  }
  
  Widget _buildSimpleTitle() {
    return Text(
      'Points Master',
      style: GoogleFonts.caveat(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
        letterSpacing: 1,
      ),
      textAlign: TextAlign.center,
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 600.ms);
  }
  
  Widget _buildSimpleTagline() {
    return Text(
      'Un jeu Points Points',
      style: GoogleFonts.nunito(
        fontSize: 16,
        color: AppTheme.primaryColor.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: 800.ms, duration: 500.ms);
  }
  
  Widget _buildPremiumProgressBar() {
    final percentage = _progress.toInt();
    final screenWidth = MediaQuery.of(context).size.width;
    final progressWidth = screenWidth * 0.65; // 65% de la largeur de l'écran (réduit)
    
    return Positioned(
      bottom: 50,
      left: (screenWidth - progressWidth) / 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de progression avec pourcentage intégré
          Container(
            width: progressWidth,
            height: 32, // Réduit de 45 à 32
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16), // Ajusté pour la nouvelle hauteur
              color: AppTheme.gridLine.withOpacity(0.15),
            ),
            child: Stack(
              children: [
                // Progression de gauche à droite avec dégradé bleu clair → rose/violet
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FractionallySizedBox(
                    widthFactor: _progress / 100,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF64B5F6), // Bleu clair
                            const Color(0xFFBA68C8), // Violet/rose
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Pourcentage centré en blanc
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      '$percentage%',
                      key: ValueKey(percentage),
                      style: GoogleFonts.caveat(
                        fontSize: 18, // Réduit de 22 à 18
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Version
          Text(
            'Version $_version',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1000.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, delay: 1000.ms, duration: 600.ms);
  }
}

/// Peintre pour le fond quadrillé
class _NotebookBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gridSpacing = 24.0;
    
    // Lignes horizontales (bleues légères)
    final horizontalPaint = Paint()
      ..color = AppTheme.gridLine.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    for (double y = gridSpacing; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), horizontalPaint);
    }
    
    // Lignes verticales (très légères)
    final verticalPaint = Paint()
      ..color = AppTheme.gridLine.withOpacity(0.15)
      ..strokeWidth = 0.5;
    
    for (double x = gridSpacing; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), verticalPaint);
    }
    
    // Marge rouge à gauche
    final marginPaint = Paint()
      ..color = AppTheme.marginLine.withOpacity(0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      const Offset(48, 0),
      Offset(48, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

