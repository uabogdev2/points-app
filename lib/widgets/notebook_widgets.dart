import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/audio_controller.dart';

/// Fond quadrillé style cahier d'école
class NotebookBackground extends StatelessWidget {
  final Widget child;
  final bool showMargin;
  final double gridSpacing;
  
  const NotebookBackground({
    super.key,
    required this.child,
    this.showMargin = true,
    this.gridSpacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.paperWhite,
      ),
      child: CustomPaint(
        painter: _NotebookPainter(
          showMargin: showMargin,
          gridSpacing: gridSpacing,
        ),
        child: child,
      ),
    );
  }
}

class _NotebookPainter extends CustomPainter {
  final bool showMargin;
  final double gridSpacing;
  
  _NotebookPainter({
    required this.showMargin,
    required this.gridSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.gridLine.withOpacity(0.4)
      ..strokeWidth = 0.5;
    
    // Lignes horizontales
    for (double y = gridSpacing; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Lignes verticales (légères)
    final verticalPaint = Paint()
      ..color = AppTheme.gridLine.withOpacity(0.2)
      ..strokeWidth = 0.5;
    for (double x = gridSpacing; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), verticalPaint);
    }
    
    // Marge rouge à gauche
    if (showMargin) {
      final marginPaint = Paint()
        ..color = AppTheme.marginLine.withOpacity(0.4)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        const Offset(48, 0),
        Offset(48, size.height),
        marginPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Carte style post-it
class PostItCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double rotation;
  final VoidCallback? onTap;
  
  const PostItCard({
    super.key,
    required this.child,
    this.color = const Color(0xFFFFF59D), // Jaune post-it par défaut
    this.rotation = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 0.0174533, // Degrés en radians
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Bouton animé style cahier
class NotebookButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;
  final double? width;
  
  const NotebookButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
    this.width,
  });

  @override
  State<NotebookButton> createState() => _NotebookButtonState();
}

class _NotebookButtonState extends State<NotebookButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppTheme.primaryColor;
    final fgColor = widget.textColor ?? Colors.white;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          AudioController.playClick();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isOutlined ? Colors.transparent : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: widget.isOutlined 
                ? Border.all(color: bgColor, width: 2)
                : null,
            boxShadow: widget.isOutlined ? null : [
              BoxShadow(
                color: bgColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.isOutlined ? bgColor : fgColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.text,
                  style: AppTheme.buttonText.copyWith(
                    color: widget.isOutlined ? bgColor : fgColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de mode de jeu style cahier
class GameModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isNew;
  
  const GameModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Row(
            children: [
              // Icône dans un cercle coloré
              Container(
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
              const SizedBox(width: 12),
              
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTheme.handwritingSubtitle.copyWith(
                              fontSize: 20,
                              color: AppTheme.primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEW',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodyText.copyWith(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Flèche
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}

/// Badge doré style médaille
class GoldBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  
  const GoldBadge({
    super.key,
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.accentGold,
            AppTheme.accentGoldDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicateur de score style encre
class InkScoreDisplay extends StatelessWidget {
  final int score;
  final Color color;
  final String? label;
  
  const InkScoreDisplay({
    super.key,
    required this.score,
    this.color = AppTheme.inkBlue,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTheme.bodyText.copyWith(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          score.toString(),
          style: AppTheme.handwritingNumber.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Animation de page qui se tourne
class PageTurnAnimation extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  
  const PageTurnAnimation({
    super.key,
    required this.child,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: isVisible ? child : const SizedBox.shrink(),
    );
  }
}

/// En-tête de section style titre de chapitre
class ChapterHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  
  const ChapterHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.primaryColor, size: 28),
              const SizedBox(width: 12),
            ],
            Text(
              title,
              style: AppTheme.handwritingTitle,
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: icon != null ? 40 : 0),
            child: Text(
              subtitle!,
              style: AppTheme.bodyText.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Ligne de soulignement style crayon
        Container(
          height: 3,
          width: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

