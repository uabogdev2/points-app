import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/game.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/sound_button.dart';
import '../widgets/sound_icon_button.dart';
import '../mixins/background_music_mixin.dart';
import 'game_screen.dart';

class CreatePrivateGameScreen extends StatefulWidget {
  final int gridSize;

  const CreatePrivateGameScreen({
    super.key,
    required this.gridSize,
  });

  @override
  State<CreatePrivateGameScreen> createState() => _CreatePrivateGameScreenState();
}

class _CreatePrivateGameScreenState extends State<CreatePrivateGameScreen> with BackgroundMusicMixin {
  bool _isLoading = false;
  String? _error;
  Game? _game;
  String? _roomCode;
  final SocketService _socketService = SocketService();
  bool _isListening = false;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _createPrivateGame();
  }
  
  void _startStatusCheck() {
    if (_game == null) return;
    
    // Vérifier l'état de la partie toutes les 1 seconde (polling rapide)
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || _game == null) {
        timer.cancel();
        return;
      }
      
      if (_game!.status == 'active') {
        timer.cancel();
        return;
      }
      
      // Vérifier l'état de la partie sur le serveur
      try {
        final game = await ApiService.getGame(_game!.id);
        
        if (game.status == 'active' && game.players.length >= 2) {
          debugPrint('✅ [PRIVATE] Partie devenue active via polling rapide (1s), navigation...');
          timer.cancel();
          if (mounted) {
            _navigateToGame(game.id);
          }
        } else if (game.status != 'waiting' || game.players.length < 1) {
          debugPrint('⚠️ [PRIVATE] Partie invalide détectée');
          timer.cancel();
        }
      } catch (e) {
        // Ne pas spammer les logs - seulement les erreurs critiques
        if (e.toString().contains('404') || e.toString().contains('introuvable')) {
          debugPrint('⚠️ [PRIVATE] Partie introuvable (404)');
          timer.cancel();
        }
        // Autres erreurs : continuer le polling (peut être temporaire)
      }
    });
  }

  void _setupSocketListeners() {
    if (_isListening) return;
    _isListening = true;

    _socketService.onOpponentJoined = (Game game) {
      debugPrint('✅ [PRIVATE] Adversaire rejoint! Game ID: ${game.id}, Status: ${game.status}');
      if (mounted && game.status == 'active') {
        _navigateToGame(game.id);
      }
    };

    _socketService.onGameUpdated = (Game game) {
      debugPrint('✅ [PRIVATE] Game updated! Game ID: ${game.id}, Status: ${game.status}');
      if (mounted && game.status == 'active' && _game?.id == game.id) {
        _navigateToGame(game.id);
      }
    };
  }

  void _navigateToGame(int gameId) {
    if (!mounted) return;
    debugPrint('✅ [PRIVATE] Navigation vers GameScreen (ID: $gameId)');
    
    // Nettoyer l'état du GameProvider avant de naviguer vers la nouvelle partie
    final gameProvider = context.read<GameProvider>();
    gameProvider.resetStateForNewGame();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(gameId: gameId),
      ),
    );
  }

  Future<void> _createPrivateGame() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Connexion Socket.IO non-bloquante
      if (!_socketService.isConnected) {
        _socketService.connect().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('⚠️ [PRIVATE] Timeout connexion Socket.IO, continue quand même');
          },
        );
      }

      final result = await ApiService.createPrivateGame(widget.gridSize);
      final game = result['game'] as Game;
      final roomCode = result['room_code'] as String;
      
      setState(() {
        _game = game;
        _roomCode = roomCode;
        _isLoading = false;
      });

      // Attendre l'authentification (max 2 secondes)
      int attempts = 0;
      while (!_socketService.isAuthenticated && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      // Rejoindre la room immédiatement (même si pas encore authentifié, sera fait après)
      if (game.id != null) {
        _socketService.joinGame(game.id);
        debugPrint('✅ [PRIVATE] Rejoint la room Socket.IO pour la partie ${game.id}');
      }
      
      // Démarrer la vérification périodique de l'état (polling rapide)
      _startStatusCheck();
    } catch (e) {
      debugPrint('❌ [PRIVATE] Erreur lors de la création: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    // Annuler la partie privée si elle est toujours en attente
    if (_game != null && _game!.status == 'waiting') {
      debugPrint('🚫 [PRIVATE] Annulation de la partie privée - Game ID: ${_game!.id}');
      ApiService.cancelPrivateGame(_game!.id).catchError((e) {
        debugPrint('⚠️ [PRIVATE] Erreur annulation serveur (non bloquant): $e');
      });
    }
    super.dispose();
  }

  void _copyToClipboard() {
    if (_roomCode != null) {
      Clipboard.setData(ClipboardData(text: _roomCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'Code copié !',
                style: GoogleFonts.nunito(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    // Si la partie est en attente, demander confirmation
    if (_game != null && _game!.status == 'waiting') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: AppTheme.paperWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppTheme.gridLine.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.cancel_outlined, size: 32, color: Colors.orange),
                ),
                const SizedBox(height: 16),
                Text(
                  'Annuler la partie ?',
                  style: GoogleFonts.caveat(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'La partie privée sera supprimée et le code ne sera plus valide.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: AppTheme.gridLine,
                            width: 1.5,
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(
                          'Non',
                          style: GoogleFonts.nunito(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(
                          'Oui, annuler',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                          ),
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

      if (confirmed == true) {
        // Annuler côté serveur
        await ApiService.cancelPrivateGame(_game!.id).catchError((e) {
          debugPrint('⚠️ [PRIVATE] Erreur annulation serveur (non bloquant): $e');
        });
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: NotebookBackground(
        showMargin: false,
        child: Builder(
          builder: (context) {
            final topPadding = MediaQuery.of(context).padding.top;
            return Column(
              children: [
                // Bouton retour repositionné
                Padding(
                  padding: EdgeInsets.only(top: topPadding + 32, left: 16, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      SoundIconButton(
                        icon: Icons.arrow_back,
                        color: Colors.grey,
                        iconSize: 24,
                        padding: const EdgeInsets.all(8),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _error != null
                          ? _buildError()
                          : _roomCode != null
                              ? _buildGameCreated()
                              : const SizedBox(),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          Text(
            'Création de la partie...',
            style: GoogleFonts.caveat(
              fontSize: 24,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oups !',
              style: GoogleFonts.caveat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            NotebookButton(
              text: 'Réessayer',
              icon: Icons.refresh,
              onPressed: _createPrivateGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCreated() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Note style post-it
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Partie créée ! Partagez le code ou le QR code avec votre ami.',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
          
          // QR Code dans un cadre style cahier
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gridLine.withOpacity(0.5)),
              boxShadow: AppTheme.paperShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: QrImageView(
                    data: _roomCode!,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppTheme.primaryColor,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Code texte
                Text(
                  'Code de la partie',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _copyToClipboard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _roomCode!,
                            style: GoogleFonts.caveat(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                              color: AppTheme.primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.copy,
                          color: AppTheme.primaryColor.withOpacity(0.7),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
          
          const SizedBox(height: 32),
          
          // Indicateur d'attente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'En attente d\'un joueur...',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 16),
          
          // Info partie
                Text(
                  'Grille ${widget.gridSize}×${widget.gridSize}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }
}
