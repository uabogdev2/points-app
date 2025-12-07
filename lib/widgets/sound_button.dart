import 'package:flutter/material.dart';
import '../services/audio_controller.dart';

/// ElevatedButton avec son de clic automatique
class SoundElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool? autofocus;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final bool? statesController;

  const SoundElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.autofocus,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.statesController,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              AudioController.playClick();
              onPressed!();
            },
      style: style,
      autofocus: autofocus ?? false,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      child: child,
    );
  }
}

/// TextButton avec son de clic automatique
class SoundTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool? autofocus;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final bool? statesController;
  final Icon? icon;
  final Widget? label;

  const SoundTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.autofocus,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.statesController,
    this.icon,
    this.label,
  });

  /// Constructeur pour TextButton.icon
  const SoundTextButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.style,
    this.autofocus,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.statesController,
    this.child = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null && label != null) {
      return TextButton.icon(
        onPressed: onPressed == null
            ? null
            : () {
                AudioController.playClick();
                onPressed!();
              },
        style: style,
        autofocus: autofocus ?? false,
        clipBehavior: clipBehavior,
        focusNode: focusNode,
        icon: icon!,
        label: label!,
      );
    }
    
    return TextButton(
      onPressed: onPressed == null
          ? null
          : () {
              AudioController.playClick();
              onPressed!();
            },
      style: style,
      autofocus: autofocus ?? false,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      child: child,
    );
  }
}

/// OutlinedButton avec son de clic automatique
class SoundOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool? autofocus;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final bool? statesController;

  const SoundOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.autofocus,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.statesController,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed == null
          ? null
          : () {
              AudioController.playClick();
              onPressed!();
            },
      style: style,
      autofocus: autofocus ?? false,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      child: child,
    );
  }
}

