import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
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

class JoinPrivateGameScreen extends StatefulWidget {
  const JoinPrivateGameScreen({super.key});

  @override
  State<JoinPrivateGameScreen> createState() => _JoinPrivateGameScreenState();
}

class _JoinPrivateGameScreenState extends State<JoinPrivateGameScreen> with BackgroundMusicMixin {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _showScanner = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _joinByCode(String code) async {
    if (code.length != 6) {
      setState(() {
        _error = 'Le code doit contenir 6 caractères';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final socketService = SocketService();
      // Connexion non-bloquante
      if (!socketService.isConnected) {
        socketService.connect().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('⚠️ [JOIN] Timeout connexion Socket.IO, continue quand même');
          },
        );
      }

      final result = await ApiService.joinByCode(code.toUpperCase());
      final game = result['game'] as Game;
      final joined = result['joined'] as bool? ?? false;
      
      if (game.id == null) {
        throw Exception('Partie invalide');
      }
      
      // Rejoindre la room Socket.IO immédiatement
      socketService.joinGame(game.id);
      debugPrint('✅ [JOIN] Rejoint la room Socket.IO pour la partie ${game.id}');
      
      // Si la partie est active et a 2 joueurs, naviguer immédiatement
      if (joined && game.status == 'active' && game.players.length >= 2) {
        debugPrint('✅ [JOIN] Partie active, navigation immédiate');
        if (mounted) {
          final gameProvider = context.read<GameProvider>();
          gameProvider.resetStateForNewGame();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GameScreen(gameId: game.id),
            ),
          );
        }
        return;
      }
      
      // Si la partie n'est pas encore active, polling rapide (1 seconde)
      debugPrint('⏳ [JOIN] Partie pas encore active, polling rapide...');
      for (int i = 0; i < 10; i++) { // Max 10 secondes
        await Future.delayed(const Duration(seconds: 1));
        final updatedGame = await ApiService.getGame(game.id);
        
        if (updatedGame.status == 'active' && updatedGame.players.length >= 2) {
          debugPrint('✅ [JOIN] Partie devenue active via polling rapide');
          if (mounted) {
            final gameProvider = context.read<GameProvider>();
            gameProvider.resetStateForNewGame();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameScreen(gameId: updatedGame.id),
              ),
            );
          }
          return;
        }
      }
      
      throw Exception('La partie n\'est pas encore prête. Veuillez réessayer.');
    } catch (e) {
      debugPrint('❌ [JOIN] Erreur lors de la jointure: $e');
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.length == 6) {
        _scannerController?.stop();
        setState(() {
          _showScanner = false;
        });
        _joinByCode(code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotebookBackground(
        showMargin: false,
        child: Column(
          children: [
            // Bouton retour repositionné
            Builder(
              builder: (context) {
                final topPadding = MediaQuery.of(context).padding.top;
                return Padding(
                  padding: EdgeInsets.only(top: topPadding + 32, left: 16, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: SoundIconButton(
                          icon: _showScanner ? Icons.close : Icons.arrow_back,
                          color: Colors.grey,
                          iconSize: 24,
                          padding: const EdgeInsets.all(8),
                          onPressed: () {
                            if (_showScanner) {
                              setState(() => _showScanner = false);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: _showScanner ? _buildScanner() : _buildCodeInput(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Icône principale
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 24),
          
          Text(
            'Rejoindre une partie',
            style: GoogleFonts.caveat(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Entrez le code ou scannez le QR code',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 40),
          
          // Champ de saisie du code
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.gridLine.withOpacity(0.5)),
              boxShadow: AppTheme.paperShadow,
            ),
            child: TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: AppTheme.primaryColor,
              ),
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: '______',
                hintStyle: GoogleFonts.caveat(
                  fontSize: 36,
                  color: Colors.grey[300],
                  letterSpacing: 8,
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
              onChanged: (value) {
                if (value.length == 6) {
                  _joinByCode(value);
                }
              },
            ),
          ).animate().fadeIn(delay: 300.ms),
          
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.nunito(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Boutons
          if (_isLoading)
            Column(
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.connectionInProgress,
                  style: GoogleFonts.nunito(color: Colors.grey[600]),
                ),
              ],
            )
          else
            Column(
              children: [
                NotebookButton(
                  text: 'Rejoindre',
                  icon: Icons.login,
                  width: double.infinity,
                  onPressed: () => _joinByCode(_codeController.text),
                ),
                const SizedBox(height: 16),
                
                // Séparateur
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.gridLine)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: GoogleFonts.nunito(color: Colors.grey[500]),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.gridLine)),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                NotebookButton(
                  text: 'Scanner QR code',
                  icon: Icons.qr_code_scanner,
                  isOutlined: true,
                  backgroundColor: AppTheme.primaryColor,
                  width: double.infinity,
                  onPressed: () {
                    setState(() {
                      _showScanner = true;
                      _error = null;
                    });
                  },
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryColor, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onQRCodeDetected,
                ),
                // Overlay avec cadre de scan
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.accentGold,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Instructions
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Placez le QR code dans le cadre pour le scanner automatiquement',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoundTextButton.icon(
                onPressed: () {
                  setState(() => _showScanner = false);
                },
                icon: const Icon(Icons.keyboard),
                label: Text(
                  'Entrer le code manuellement',
                  style: GoogleFonts.nunito(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
