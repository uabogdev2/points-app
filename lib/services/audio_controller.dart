import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Contrôleur audio simple et optimisé avec 2 players statiques
class AudioController {
  static final AudioPlayer bgPlayer = AudioPlayer();
  static final AudioPlayer fxPlayer = AudioPlayer();
  
  static bool _isMusicEnabled = true;
  static bool _isSoundEnabled = true;
  static double _musicVolume = 0.5;
  static bool _isInitialized = false;
  static bool _isPlaying = false;
  static Timer? _volumeTransitionTimer;
  static double _currentVolume = 0.5;

  static bool get isMusicEnabled => _isMusicEnabled;
  static bool get isSoundEnabled => _isSoundEnabled;
  static double get musicVolume => _musicVolume;

  /// Initialise les players et charge les préférences
  static Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMusicEnabled = prefs.getBool('music_enabled') ?? true;
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _musicVolume = prefs.getDouble('music_volume') ?? 0.5;
      _currentVolume = _musicVolume;
      
      // Configurer le player de musique de fond
      await bgPlayer.setAsset('assets/sounds/background.mp3');
      await bgPlayer.setLoopMode(LoopMode.one);
      await bgPlayer.setVolume(_currentVolume);
      
      // Configurer le volume du player d'effets sonores
      await fxPlayer.setVolume(1.0);
      
      _isInitialized = true;
      debugPrint('✅ [AUDIO] AudioController initialisé - Musique: $_isMusicEnabled, Sons: $_isSoundEnabled, Volume: $_musicVolume');
      
      // Démarrer la musique si activée
      if (_isMusicEnabled) {
        await playBackground();
      }
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur initialisation AudioController: $e');
    }
  }

  /// Joue la musique de fond
  static Future<void> playBackground() async {
    if (!_isMusicEnabled) return;
    
    try {
      final playerState = bgPlayer.playerState;
      if (playerState.processingState == ProcessingState.ready || 
          playerState.processingState == ProcessingState.completed) {
        await bgPlayer.play();
        _isPlaying = true;
        debugPrint('🎵 [AUDIO] Musique de fond démarrée');
      } else if (playerState.playing) {
        // La musique est déjà en cours de lecture
        _isPlaying = true;
      }
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur lecture musique: $e');
    }
  }

  /// Arrête la musique de fond
  static void stopBackground() {
    bgPlayer.stop();
    _isPlaying = false;
    debugPrint('⏹️ [AUDIO] Musique de fond arrêtée');
  }

  /// Met la musique en sourdine (volume à 0) avec transition progressive
  static Future<void> muteBackground() async {
    if (!_isMusicEnabled || !_isPlaying) return;
    
    try {
      await _transitionVolume(_currentVolume, 0.0);
      debugPrint('🔇 [AUDIO] Musique de fond mise en sourdine');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur mise en sourdine: $e');
    }
  }

  /// Remet le volume de la musique au niveau de base avec transition progressive
  static Future<void> unmuteBackground() async {
    if (!_isMusicEnabled) return;
    
    // Si la musique n'est pas encore démarrée, la démarrer
    if (!_isPlaying) {
      await playBackground();
      return;
    }
    
    try {
      await _transitionVolume(_currentVolume, _musicVolume);
      debugPrint('🔊 [AUDIO] Musique de fond remise au volume normal');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur remise volume: $e');
    }
  }

  /// Transition progressive du volume
  static Future<void> _transitionVolume(double from, double to) async {
    _volumeTransitionTimer?.cancel();
    
    if ((from - to).abs() < 0.01) {
      _currentVolume = to;
      await bgPlayer.setVolume(to);
      return;
    }

    const duration = Duration(milliseconds: 500);
    const steps = 20;
    final stepDuration = duration ~/ steps;
    final volumeStep = (to - from) / steps;
    
    int currentStep = 0;
    
    _volumeTransitionTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      _currentVolume = (from + (volumeStep * currentStep)).clamp(0.0, 1.0);
      bgPlayer.setVolume(_currentVolume);
      
      if (currentStep >= steps) {
        timer.cancel();
        _currentVolume = to;
        bgPlayer.setVolume(to);
      }
    });
  }

  /// Joue le son de clic sur un bouton
  static Future<void> playClick() async {
    if (!_isSoundEnabled) return;
    
    try {
      await fxPlayer.setAsset('assets/sounds/clic-boutton.mp3');
      await fxPlayer.play();
      debugPrint('🔊 [AUDIO] Son de clic (bouton) joué');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur son clic bouton: $e');
    }
  }

  /// Joue le son de clic sur un point du plateau
  static Future<void> playClickSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await fxPlayer.setAsset('assets/sounds/clic-square.mp3');
      await fxPlayer.play();
      debugPrint('🔊 [AUDIO] Son de clic (point) joué');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur son clic: $e');
    }
  }

  /// Joue le son de succès (carré complété)
  static Future<void> playSuccessSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await fxPlayer.setAsset('assets/sounds/succes-square.mp3');
      await fxPlayer.play();
      debugPrint('🎉 [AUDIO] Son de succès joué');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur son succès: $e');
    }
  }

  /// Joue le son de victoire (partie gagnée)
  static Future<void> playWinnerSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await fxPlayer.setAsset('assets/sounds/winner-game.mp3');
      await fxPlayer.play();
      debugPrint('🏆 [AUDIO] Son de victoire joué');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur son victoire: $e');
    }
  }

  /// Joue le son de défaite (partie perdue)
  static Future<void> playLosseSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await fxPlayer.setAsset('assets/sounds/losse-game.mp3');
      await fxPlayer.play();
      debugPrint('😢 [AUDIO] Son de défaite joué');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur son défaite: $e');
    }
  }

  /// Active/désactive la musique
  static Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('music_enabled', enabled);
      
      if (enabled) {
        await playBackground();
      } else {
        // Arrêter complètement la musique au lieu de juste la mettre en sourdine
        stopBackground();
      }
      debugPrint('🔊 [AUDIO] Musique ${enabled ? "activée" : "désactivée"}');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur sauvegarde musique: $e');
    }
  }

  /// Active/désactive les sons
  static Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', enabled);
      debugPrint('🔊 [AUDIO] Sons ${enabled ? "activés" : "désactivés"}');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur sauvegarde sons: $e');
    }
  }

  /// Définit le volume de la musique (0.0 à 1.0)
  static Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('music_volume', _musicVolume);
      
      // Si la musique n'est pas en sourdine, mettre à jour le volume actuel
      if (_currentVolume > 0) {
        await _transitionVolume(_currentVolume, _musicVolume);
      }
      debugPrint('🔊 [AUDIO] Volume musique: $_musicVolume');
    } catch (e) {
      debugPrint('❌ [AUDIO] Erreur volume musique: $e');
    }
  }

  /// Libère les ressources
  static Future<void> dispose() async {
    _volumeTransitionTimer?.cancel();
    await bgPlayer.dispose();
    await fxPlayer.dispose();
    _isInitialized = false;
    debugPrint('🔊 [AUDIO] AudioController libéré');
  }
}

