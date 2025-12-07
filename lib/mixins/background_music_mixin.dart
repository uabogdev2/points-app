import 'package:flutter/material.dart';
import '../services/audio_controller.dart';

/// Mixin pour gérer automatiquement la musique de fond
/// Utilisez-le dans les StatefulWidget qui doivent avoir la musique de fond
mixin BackgroundMusicMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioController.unmuteBackground();
    });
  }

  @override
  void dispose() {
    // Ne rien faire - la musique continue de jouer en sourdine si nécessaire
    super.dispose();
  }
}

