import 'package:flutter/foundation.dart';
import '../services/audio_controller.dart';

/// Provider pour gérer les paramètres audio
class AudioSettingsProvider with ChangeNotifier {
  bool get isMusicEnabled => AudioController.isMusicEnabled;
  bool get isSoundEnabled => AudioController.isSoundEnabled;
  double get musicVolume => AudioController.musicVolume;

  /// Active/désactive la musique
  Future<void> setMusicEnabled(bool enabled) async {
    await AudioController.setMusicEnabled(enabled);
    notifyListeners();
  }

  /// Active/désactive les sons
  Future<void> setSoundEnabled(bool enabled) async {
    await AudioController.setSoundEnabled(enabled);
    notifyListeners();
  }

  /// Définit le volume de la musique
  Future<void> setMusicVolume(double volume) async {
    await AudioController.setMusicVolume(volume);
    notifyListeners();
  }
}

