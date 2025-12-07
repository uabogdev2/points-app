import 'package:flutter/material.dart';
import '../services/audio_controller.dart';

/// IconButton avec son de clic automatique
class SoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  
  const SoundIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.tooltip,
    this.iconSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed == null
          ? null
          : () {
              AudioController.playClick();
              onPressed!();
            },
      color: color,
      tooltip: tooltip,
      iconSize: iconSize,
      padding: padding,
    );
  }
}

