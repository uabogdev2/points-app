import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game.dart';
import '../theme/app_theme.dart';
import '../services/audio_controller.dart';

class GameBoard extends StatefulWidget {
  final Game game;
  final Function(int, int, int, int)? onMove;
  final bool isMyTurn;

  const GameBoard({
    super.key,
    required this.game,
    this.onMove,
    required this.isMyTurn,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  int? _selectedRow;
  int? _selectedCol;
  
  final Map<String, AnimationController> _segmentAnimations = {};
  final Map<String, String> _previousBoardState = {};
  final Map<String, AnimationController> _squareAnimations = {};
  int _previousCompletedSquaresCount = 0;
  
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _interactiveViewerKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  
  Offset? _tapStartPosition;
  DateTime? _tapStartTime;
  
  // Animation pour le pan automatique
  AnimationController? _panAnimationController;
  Animation<Matrix4>? _panAnimation;
  
  // Stocker les dimensions du plateau pour le pan auto
  double? _boardSize;
  double? _cellSize;

  @override
  void initState() {
    super.initState();
    if (widget.game.boardState != null) {
      widget.game.boardState!.forEach((key, _) {
        _previousBoardState[key] = key;
      });
    }
    _previousCompletedSquaresCount = widget.game.completedSquares?.length ?? 0;
  }

  @override
  void didUpdateWidget(GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Vérifier que le widget est toujours monté avant de faire des modifications
    if (!mounted) return;
    
    if (widget.game.boardState != null) {
      // Obtenir l'ancien boardState pour comparer
      final oldBoardState = oldWidget.game.boardState ?? {};
      
      widget.game.boardState!.forEach((key, playerId) {
        if (!_previousBoardState.containsKey(key)) {
          _startSegmentAnimation(key);
          _previousBoardState[key] = key;
          
          // Détecter si c'est un mouvement de l'adversaire
          // Le pan auto doit se faire CHEZ L'ADVERSAIRE (celui qui ne joue pas)
          // 
          // Logique : 
          // Après qu'un joueur joue, le currentPlayerId change pour devenir l'autre joueur.
          // Donc si le playerId du segment est différent du currentPlayerId actuel,
          // cela signifie que c'est l'adversaire qui a joué (car le tour a changé).
          // 
          // IMPORTANT : Le pan se fait uniquement chez l'adversaire (celui qui ne joue pas)
          // Donc si le segment a été ajouté par l'adversaire, je dois pan
          final currentPlayerId = widget.game.currentPlayerId;
          
          // Si le playerId du segment est différent du currentPlayerId actuel,
          // cela signifie que l'adversaire vient de jouer (le tour a changé)
          final isOpponentMove = currentPlayerId != null && playerId != currentPlayerId;
          
          if (isOpponentMove) {
            debugPrint('📍 [GAME_BOARD] Pan auto déclenché - adversaire a joué (segment: $key, playerId: $playerId, currentPlayerId: $currentPlayerId)');
            // Délai pour s'assurer que le widget est complètement rendu et que la vue est à jour
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _checkAndPanToSegment(key, widget.game.gridSize);
              }
            });
          }
        }
      });
    }
    
    // Détecter les nouveaux carrés complétés de manière sécurisée
    final currentCompletedSquares = widget.game.completedSquares ?? <String, dynamic>{};
    final oldCompletedSquares = oldWidget.game.completedSquares ?? <String, dynamic>{};
    final currentCompletedSquaresCount = currentCompletedSquares.length;
    
    if (currentCompletedSquaresCount > _previousCompletedSquaresCount) {
      // Trouver les nouveaux carrés en comparant avec l'ancien état
      final newSquares = currentCompletedSquares.keys
          .where((key) => !oldCompletedSquares.containsKey(key))
          .toList();
      
      for (final squareKey in newSquares) {
        if (mounted) {
          _startSquareAnimation(squareKey);
        }
      }
      
      // Le son est joué dans _startSquareAnimation
      _previousCompletedSquaresCount = currentCompletedSquaresCount;
    }
  }

  void _startSegmentAnimation(String segmentKey) {
    if (_segmentAnimations.containsKey(segmentKey) || !mounted) return;
    
    // Jouer le son de clic-square
    AudioController.playClickSound();
    
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _segmentAnimations[segmentKey] = controller;
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    controller.forward().then((_) {
      // Nettoyer après l'animation
      if (mounted && _segmentAnimations.containsKey(segmentKey)) {
        _segmentAnimations[segmentKey]?.dispose();
        _segmentAnimations.remove(segmentKey);
      }
    });
  }

  void _startSquareAnimation(String squareKey) {
    if (_squareAnimations.containsKey(squareKey) || !mounted) return;
    
    // Jouer le son de succès-square
    AudioController.playSuccessSound();
    
    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _squareAnimations[squareKey] = controller;
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    controller.forward().then((_) {
      // Garder l'animation pour l'affichage final, mais ne pas la nettoyer immédiatement
      // Elle sera nettoyée dans dispose()
    });
  }

  @override
  void dispose() {
    _panAnimationController?.dispose();
    _transformationController.dispose();
    for (var controller in _segmentAnimations.values) {
      controller.dispose();
    }
    for (var controller in _squareAnimations.values) {
      controller.dispose();
    }
    _segmentAnimations.clear();
    _squareAnimations.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = widget.game.gridSize;
    
    // Conteneur bleu qui occupe TOUT l'espace disponible
    final outerMargin = 10.0; // Marge extérieure TRÈS minimale
    final containerPadding = 20.0; // Padding interne du conteneur bleu
    final containerBorder = 6.0; // Bordure épaisse

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(outerMargin),
      decoration: BoxDecoration(
        // Fond papier cahier avec dégradé doux
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.paperWhite,
            AppTheme.paperWhite.withOpacity(0.98),
            AppTheme.paperCream.withOpacity(0.4),
          ],
        ),
      ),
      child: Container(
        // Conteneur bleu FIXE - OCCUPE TOUT L'ESPACE DISPONIBLE
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(containerPadding),
        decoration: BoxDecoration(
          color: AppTheme.paperWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 35,
              spreadRadius: 6,
            ),
          ],
          border: Border.all(
            color: AppTheme.primaryColor,
            width: containerBorder,
          ),
        ),
        // ✅ SOLUTION ROBUSTE: Utiliser AspectRatio pour garantir un carré parfait
        child: Center(
          child: AspectRatio(
            aspectRatio: 1, // GARANTIT toujours un carré parfait
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Taille EXACTE du carré (largeur = hauteur car aspectRatio: 1)
                final boardSize = constraints.maxWidth;
                
                // CALCUL PRÉCIS: Calculer d'abord la taille maximale possible (sans multiplicateur)
                final baseCellSize = boardSize / gridSize;
                
                // Facteur d'agrandissement pour les grilles 8x8 et 12x12
                double sizeMultiplier = 1.0;
                if (gridSize == 8) {
                  sizeMultiplier = 1.15;
                } else if (gridSize == 12) {
                  sizeMultiplier = 1.20;
                }
                
                // Calculer la taille du plateau avec le multiplicateur, mais limiter à boardSize
                final finalBoardSize = math.min(baseCellSize * sizeMultiplier * gridSize, boardSize);
                // Calculer la taille de cellule réelle à partir de la taille finale du plateau
                // Cela garantit que cellSize * gridSize = boardSize exactement
                final actualCellSize = finalBoardSize / gridSize;

                // Stocker la taille du plateau pour le pan auto
                _boardSize = finalBoardSize;
                _cellSize = actualCellSize;

                return InteractiveViewer(
                key: _interactiveViewerKey,
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(200), // AUGMENTÉ pour voir tous les points
                panEnabled: true,
                scaleEnabled: true,
        child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    if (!widget.isMyTurn || widget.onMove == null) return;
                    _tapStartPosition = details.globalPosition; // <-- global
                    _tapStartTime = DateTime.now();
                  },
                  onTapUp: (details) {
                    if (_tapStartPosition == null || _tapStartTime == null) return;

                    final duration = DateTime.now().difference(_tapStartTime!);
                    // distance en pixels globaux
                    final distance = (details.globalPosition - _tapStartPosition!).distance;

                    if (duration.inMilliseconds < 300 && distance < 15) {
                      // Récupère le RenderBox de l'InteractiveViewer (le viewport)
                      final RenderBox? viewerBox = _interactiveViewerKey.currentContext?.findRenderObject() as RenderBox?;
                      if (viewerBox == null) {
                        _tapStartPosition = null;
                        _tapStartTime = null;
                        return;
                      }

                      // Convertit la position globale du tap en coordonnées LOCALES du viewport
                      final Offset localInViewport = viewerBox.globalToLocal(details.globalPosition);

                      // Puis convertit en coordonnées de la scène (position sur le plateau qui a été transformé)
                      final Offset scenePoint = _transformationController.toScene(localInViewport);

                      _handleTap(
                        scenePoint,
                        actualCellSize,
                        gridSize,
                      );
                    }

                    _tapStartPosition = null;
                    _tapStartTime = null;
                  },
                  onTapCancel: () {
                    _tapStartPosition = null;
                    _tapStartTime = null;
                  },
                  child: SizedBox(
                    width: finalBoardSize,
                    height: finalBoardSize,
                    child: CustomPaint(
                      key: _boardKey,
                      size: Size(finalBoardSize, finalBoardSize),
                      painter: _NotebookGameBoardPainter(
                        gridSize: gridSize,
                        cellSize: actualCellSize,
                        boardState: widget.game.boardState ?? {},
                        completedSquares: widget.game.completedSquares ?? <String, CompletedSquare>{},
                        selectedRow: _selectedRow,
                        selectedCol: _selectedCol,
                        players: widget.game.players,
                        segmentAnimations: _segmentAnimations,
                        squareAnimations: _squareAnimations,
                      ),
                    ),
                  ),
                ),
              );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(
    Offset scenePoint,
    double cellSize,
    int gridSize,
  ) {
    if (!widget.isMyTurn || widget.onMove == null) return;

    // Obtenir le RenderBox du CustomPaint
    final renderBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    // IMPORTANT: Utiliser la cellSize passée en paramètre (celle du painter)
    // pour garantir la correspondance exacte avec les lignes et points dessinés
    final actualBoardSize = renderBox.size.width;
    // Vérifier que la taille correspond bien à cellSize * gridSize
    final expectedBoardSize = cellSize * gridSize;
    
    // Si il y a une différence, utiliser la taille réelle pour recalculer
    final usedCellSize = (actualBoardSize / expectedBoardSize).abs() < 0.01 
        ? cellSize 
        : actualBoardSize / gridSize;

    // ✅ Les coordonnées sont déjà converties en coordonnées de la scène par toScene()
    // dans onTapUp. On peut les utiliser directement.
    final boardX = scenePoint.dx;
    final boardY = scenePoint.dy;
    
    // Marge généreuse pour permettre de cliquer sur les bords
    final margin = usedCellSize * 0.6;
    if (boardX < -margin || boardX > actualBoardSize + margin || 
        boardY < -margin || boardY > actualBoardSize + margin) {
      return;
    }

    // Zone de touch adaptative
    final touchRadius = math.max(40.0, usedCellSize * 0.45);
    
    double minDistance = double.infinity;
    int? closestRow;
    int? closestCol;

    // Parcourir tous les points de la grille
    for (int row = 0; row <= gridSize; row++) {
      for (int col = 0; col <= gridSize; col++) {
        // Position exacte du point - utiliser usedCellSize pour correspondre aux lignes
        final pointX = col * usedCellSize;
        final pointY = row * usedCellSize;
        
        final distance = (Offset(boardX, boardY) - Offset(pointX, pointY)).distance;

        if (distance < touchRadius && distance < minDistance) {
          minDistance = distance;
          closestRow = row;
          closestCol = col;
        }
      }
    }

    if (closestRow == null || closestCol == null) return;

    final row = closestRow;
    final col = closestCol;

      if (_selectedRow != null && _selectedCol != null) {
        if (_selectedRow != row || _selectedCol != col) {
          final fromRow = _selectedRow!;
          final fromCol = _selectedCol!;
          final toRow = row;
          final toCol = col;

          if ((fromRow == toRow && (fromCol - toCol).abs() == 1) ||
              (fromCol == toCol && (fromRow - toRow).abs() == 1)) {
            _onSegmentTap(fromRow, fromCol, toRow, toCol);
          } else {
            setState(() {
              _selectedRow = row;
              _selectedCol = col;
            });
          }
        } else {
          setState(() {
            _selectedRow = null;
            _selectedCol = null;
          });
        }
      } else {
        setState(() {
          _selectedRow = row;
          _selectedCol = col;
        });
      }
  }

  void _onSegmentTap(int fromRow, int fromCol, int toRow, int toCol) {
    if (!widget.isMyTurn || widget.onMove == null) return;

    final segmentKey = '$fromRow-$fromCol-$toRow-$toCol';
    final reverseKey = '$toRow-$toCol-$fromRow-$fromCol';

    if (widget.game.boardState?.containsKey(segmentKey) == true ||
        widget.game.boardState?.containsKey(reverseKey) == true) {
      return;
    }

    AudioController.playClickSound();
    widget.onMove!(fromRow, fromCol, toRow, toCol);

    setState(() {
      _selectedRow = null;
      _selectedCol = null;
    });
  }

  /// Vérifie si un segment est visible et pan automatiquement si nécessaire
  void _checkAndPanToSegment(String segmentKey, int gridSize) {
    if (!mounted || _boardSize == null || _cellSize == null) return;
    
    try {
      // Parser la clé du segment (format: "fromRow-fromCol-toRow-toCol")
      final parts = segmentKey.split('-');
      if (parts.length != 4) return;
      
      final fromRow = int.parse(parts[0]);
      final fromCol = int.parse(parts[1]);
      final toRow = int.parse(parts[2]);
      final toCol = int.parse(parts[3]);
      
      // Utiliser le point de destination (toRow, toCol) comme point de référence
      final targetPoint = Offset(toCol * _cellSize!, toRow * _cellSize!);
      
      // Vérifier si le point est visible dans la vue actuelle
      if (!_isPointVisible(targetPoint)) {
        // Animer le pan vers ce point
        _animatePanToPoint(targetPoint);
      }
    } catch (e) {
      debugPrint('❌ [GAME_BOARD] Erreur pan auto: $e');
    }
  }

  /// Vérifie si un point est visible dans la vue actuelle
  bool _isPointVisible(Offset point) {
    if (_boardSize == null) return true;
    
    final RenderBox? viewerBox = _interactiveViewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewerBox == null) return true;
    
    final viewportSize = viewerBox.size;
    final currentTransform = _transformationController.value;
    
    // ✅ CORRECTION: Utiliser la transformation DIRECTE (la valeur actuelle de la matrice)
    // pour convertir le point de la scène (le plateau) en coordonnées du viewport (l'écran)
    final pointInViewport = MatrixUtils.transformPoint(currentTransform, point);
    
    // Vérifier si le point est dans les limites visibles avec une marge
    const margin = 50.0;
    
    // Le point est visible s'il est dans la zone :
    // [0 - margin, viewportSize.width + margin] en X
    // [0 - margin, viewportSize.height + margin] en Y
    return pointInViewport.dx >= -margin &&
           pointInViewport.dx <= viewportSize.width + margin &&
           pointInViewport.dy >= -margin &&
           pointInViewport.dy <= viewportSize.height + margin;
  }

  /// Anime le pan vers un point spécifique
  void _animatePanToPoint(Offset targetPoint) {
    if (!mounted || _boardSize == null) return;
    
    final RenderBox? viewerBox = _interactiveViewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewerBox == null) return;
    
    final viewportSize = viewerBox.size;
    final currentTransform = _transformationController.value;
    
    // Calculer la position actuelle du point dans le viewport
    // ✅ Utiliser la transformation DIRECTE pour obtenir la position du point dans le viewport
    final currentPointInViewport = MatrixUtils.transformPoint(currentTransform, targetPoint);
    
    // Calculer le décalage nécessaire pour centrer le point
    final centerOffset = Offset(
      viewportSize.width / 2 - currentPointInViewport.dx,
      viewportSize.height / 2 - currentPointInViewport.dy,
    );
    
    // Créer la nouvelle transformation
    final newTransform = Matrix4.copy(currentTransform);
    newTransform.translate(centerOffset.dx, centerOffset.dy);
    
    // Créer l'animation si elle n'existe pas
    _panAnimationController?.dispose();
    _panAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _panAnimation = Matrix4Tween(
      begin: currentTransform,
      end: newTransform,
    ).animate(CurvedAnimation(
      parent: _panAnimationController!,
      curve: Curves.easeOutCubic,
    ));
    
    _panAnimation!.addListener(() {
      if (mounted && _panAnimation != null) {
        _transformationController.value = _panAnimation!.value;
      }
    });
    
    _panAnimationController!.forward().then((_) {
      if (mounted) {
        _panAnimationController?.dispose();
        _panAnimationController = null;
        _panAnimation = null;
      }
    });
  }
}

class _NotebookGameBoardPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;
  final Map<String, int> boardState;
  final Map<String, CompletedSquare> completedSquares;
  final int? selectedRow;
  final int? selectedCol;
  final List<dynamic> players;
  final Map<String, AnimationController> segmentAnimations;
  final Map<String, AnimationController> squareAnimations;

  _NotebookGameBoardPainter({
    required this.gridSize,
    required this.cellSize,
    required this.boardState,
    required this.completedSquares,
    this.selectedRow,
    this.selectedCol,
    required this.players,
    required this.segmentAnimations,
    required this.squareAnimations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fond papier cahier propre et net
    final backgroundPaint = Paint()
      ..color = AppTheme.paperWhite
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      backgroundPaint,
    );

    // Grille style cahier - PROPRE ET BIEN CALIBRÉE
    // Lignes principales (tous les 5 carreaux pour les grandes grilles, toutes pour les petites)
    final mainGridPaint = Paint()
      ..color = AppTheme.gridLine.withOpacity(0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Lignes secondaires (plus subtiles mais visibles)
    final secondaryGridPaint = Paint()
      ..color = AppTheme.gridLine.withOpacity(0.45)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Lignes horizontales - CALIBRÉES PRÉCISÉMENT
    // IMPORTANT: Utiliser exactement cellSize pour garantir l'alignement avec les points
    // Dessiner TOUTES les lignes jusqu'au bord exact (y compris la dernière)
    for (int row = 0; row <= gridSize; row++) {
      final y = row * cellSize;
      final isMainLine = gridSize <= 5 || row % 5 == 0;
      final paint = isMainLine ? mainGridPaint : secondaryGridPaint;
      // Dessiner jusqu'au bord exact - pas de vérification conditionnelle
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Lignes verticales - CALIBRÉES PRÉCISÉMENT
    // IMPORTANT: Utiliser exactement cellSize pour garantir l'alignement avec les points
    // Dessiner TOUTES les lignes jusqu'au bord exact (y compris la dernière)
    for (int col = 0; col <= gridSize; col++) {
      final x = col * cellSize;
      final isMainLine = gridSize <= 5 || col % 5 == 0;
      final paint = isMainLine ? mainGridPaint : secondaryGridPaint;
      // Dessiner jusqu'au bord exact - pas de vérification conditionnelle
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Carrés complétés
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final top = boardState['$row-$col-$row-${col + 1}'] ?? 
                   boardState['$row-${col + 1}-$row-$col'];
        final right = boardState['$row-${col + 1}-${row + 1}-${col + 1}'] ?? 
                     boardState['${row + 1}-${col + 1}-$row-${col + 1}'];
        final bottom = boardState['${row + 1}-$col-${row + 1}-${col + 1}'] ?? 
                      boardState['${row + 1}-${col + 1}-${row + 1}-$col'];
        final left = boardState['$row-$col-${row + 1}-$col'] ?? 
                    boardState['${row + 1}-$col-$row-$col'];
        
        if (top == null || right == null || bottom == null || left == null) {
          continue;
        }
        
        final squareKey = '$row-$col';
        final squareX = col * cellSize;
        final squareY = row * cellSize;
        final squareRect = Rect.fromLTWH(squareX, squareY, cellSize, cellSize);
        
        final allSamePlayer = top == right && right == bottom && bottom == left;
        final animation = squareAnimations[squareKey];
        final animationValue = animation?.value ?? 1.0;
        
        if (allSamePlayer) {
          // Carré complété uniforme (4 couleurs identiques)
          final playerId = top;
          
          int playerIndex = 0;
          for (int i = 0; i < players.length; i++) {
            if ((players[i] as GamePlayer).userId == playerId) {
              playerIndex = i;
              break;
            }
          }
          
          final color = playerIndex == 0 ? AppTheme.player1Color : AppTheme.player2Color;
          
          if (animationValue < 1.0) {
            // Animation de complétion - style surligneur avec effet de zoom
            final scale = 0.1 + (animationValue * 0.9);
            final opacity = math.min(1.0, animationValue * 1.5);
            final scaledRect = Rect.fromCenter(
              center: squareRect.center,
              width: squareRect.width * scale,
              height: squareRect.height * scale,
            );
            
            // Halo pulsant doré
            final haloPaint = Paint()
              ..color = AppTheme.accentGold.withOpacity(0.4 * (1 - animationValue))
              ..style = PaintingStyle.fill;
            canvas.drawRect(squareRect, haloPaint);
            
            // Surligneur animé avec effet de brillance
            final highlightPaint = Paint()
              ..color = AppTheme.completedSquareColor.withOpacity(0.5 * opacity)
              ..style = PaintingStyle.fill;
            canvas.drawRect(scaledRect, highlightPaint);
            
            // Bordure encre animée
            final borderPaint = Paint()
              ..color = color.withOpacity(opacity)
              ..strokeWidth = 3.0 + (2.0 * animationValue)
              ..style = PaintingStyle.stroke;
            canvas.drawRect(scaledRect, borderPaint);
            
            // Étoiles dorées animées qui apparaissent
            if (animationValue > 0.4) {
              final starOpacity = (animationValue - 0.4) / 0.6;
              final starPaint = Paint()
                ..color = AppTheme.accentGold.withOpacity(starOpacity)
                ..style = PaintingStyle.fill;
              final starSize = cellSize * 0.2 * animationValue;
              _drawStar(canvas, scaledRect.center, starSize, starPaint);
            }
            
            // Numéro animé (scale + fade in)
            final completedSquare = completedSquares[squareKey];
            final squareNumber = completedSquare?.number;
            if (squareNumber != null && animationValue > 0.5) {
              final numberOpacity = (animationValue - 0.5) / 0.5;
              final numberScale = 0.3 + (0.7 * numberOpacity);
              final textStyle = TextStyle(
                color: color.withOpacity(numberOpacity),
                fontSize: cellSize * 0.5 * numberScale,
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.caveat().fontFamily,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.2 * numberOpacity),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              );
              
              final textPainter = TextPainter(
                text: TextSpan(text: squareNumber.toString(), style: textStyle),
                textDirection: TextDirection.ltr,
              );
              textPainter.layout();
              textPainter.paint(
                canvas,
                Offset(
                  squareX + (cellSize - textPainter.width) / 2,
                  squareY + (cellSize - textPainter.height) / 2,
                ),
              );
            }
          } else {
            // Carré complété final - style surligneur cahier
            // Fond surligneur
            final highlightPaint = Paint()
              ..color = AppTheme.completedSquareColor.withOpacity(0.35)
              ..style = PaintingStyle.fill;
            canvas.drawRect(squareRect, highlightPaint);
            
            // Bordure encre épaisse
            final borderPaint = Paint()
              ..color = color
              ..strokeWidth = 3.5
              ..style = PaintingStyle.stroke;
            canvas.drawRect(squareRect, borderPaint);
            
            // Ombre intérieure pour effet de profondeur
            final innerShadowPaint = Paint()
              ..color = color.withOpacity(0.15)
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke;
            final innerRect = Rect.fromLTWH(
              squareX + 2,
              squareY + 2,
              cellSize - 4,
              cellSize - 4,
            );
            canvas.drawRect(innerRect, innerShadowPaint);
            
            // Numéro final
            final completedSquare = completedSquares[squareKey];
            final squareNumber = completedSquare?.number;
            if (squareNumber != null) {
              final textStyle = TextStyle(
                color: color,
                fontSize: cellSize * 0.5,
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.caveat().fontFamily,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              );
              
              final textPainter = TextPainter(
                text: TextSpan(text: squareNumber.toString(), style: textStyle),
                textDirection: TextDirection.ltr,
              );
              textPainter.layout();
              textPainter.paint(
                canvas,
                Offset(
                  squareX + (cellSize - textPainter.width) / 2,
                  squareY + (cellSize - textPainter.height) / 2,
                ),
              );
            }
          }
        } else {
          // Carré complété mais non uniforme (X animé)
          if (animationValue < 1.0) {
            // Animation avec X qui apparaît
            final scale = 0.2 + (animationValue * 0.8);
            final opacity = math.min(1.0, animationValue * 1.5);
            final scaledRect = Rect.fromCenter(
              center: squareRect.center,
              width: squareRect.width * scale,
              height: squareRect.height * scale,
            );
            
            // Halo pulsant rouge/orange
            final haloPaint = Paint()
              ..color = AppTheme.errorColor.withOpacity(0.3 * (1 - animationValue))
              ..style = PaintingStyle.fill;
            canvas.drawRect(squareRect, haloPaint);
            
            // Fond grisé animé
            final backgroundPaint = Paint()
              ..color = Colors.grey.withOpacity(0.3 * opacity)
              ..style = PaintingStyle.fill;
            canvas.drawRect(scaledRect, backgroundPaint);
            
            // Bordure rouge animée
            final borderPaint = Paint()
              ..color = AppTheme.errorColor.withOpacity(opacity)
              ..strokeWidth = 3.0 + (2.0 * animationValue)
              ..style = PaintingStyle.stroke;
            canvas.drawRect(scaledRect, borderPaint);
            
            // X animé qui apparaît
            if (animationValue > 0.3) {
              final xOpacity = (animationValue - 0.3) / 0.7;
              final xPaint = Paint()
                ..color = AppTheme.errorColor.withOpacity(xOpacity)
                ..strokeWidth = 4.0 + (2.0 * animationValue)
                ..style = PaintingStyle.stroke
                ..strokeCap = StrokeCap.round;
              
              final xSize = cellSize * 0.4 * scale;
              final centerX = scaledRect.center.dx;
              final centerY = scaledRect.center.dy;
              
              // Dessiner le X
              canvas.drawLine(
                Offset(centerX - xSize, centerY - xSize),
                Offset(centerX + xSize, centerY + xSize),
                xPaint,
              );
              canvas.drawLine(
                Offset(centerX + xSize, centerY - xSize),
                Offset(centerX - xSize, centerY + xSize),
                xPaint,
              );
            }
          } else {
            // Carré complété non uniforme final
            // Fond grisé
            final backgroundPaint = Paint()
              ..color = Colors.grey.withOpacity(0.3)
              ..style = PaintingStyle.fill;
            canvas.drawRect(squareRect, backgroundPaint);
            
            // Bordure rouge
            final borderPaint = Paint()
              ..color = AppTheme.errorColor
              ..strokeWidth = 3.5
              ..style = PaintingStyle.stroke;
            canvas.drawRect(squareRect, borderPaint);
            
            // X final
            final xPaint = Paint()
              ..color = AppTheme.errorColor
              ..strokeWidth = 5.0
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;
            
            final xSize = cellSize * 0.4;
            final centerX = squareRect.center.dx;
            final centerY = squareRect.center.dy;
            
            canvas.drawLine(
              Offset(centerX - xSize, centerY - xSize),
              Offset(centerX + xSize, centerY + xSize),
              xPaint,
            );
            canvas.drawLine(
              Offset(centerX + xSize, centerY - xSize),
              Offset(centerX - xSize, centerY + xSize),
              xPaint,
            );
          }
        }
      }
    }

    // Segments (lignes tracées)
    boardState.forEach((key, userId) {
      final parts = key.split('-');
      if (parts.length == 4) {
        final fromRow = int.parse(parts[0]);
        final fromCol = int.parse(parts[1]);
        final toRow = int.parse(parts[2]);
        final toCol = int.parse(parts[3]);

        GamePlayer? player;
        try {
          player = players.firstWhere(
            (p) => p.userId == userId,
          ) as GamePlayer?;
        } catch (e) {
          player = null;
        }

        final color = player != null && players.indexOf(player) == 0
            ? AppTheme.player1Color
            : AppTheme.player2Color;

        final fromX = fromCol * cellSize;
        final fromY = fromRow * cellSize;
        final toX = toCol * cellSize;
        final toY = toRow * cellSize;

        final animation = segmentAnimations[key];
        final animationValue = animation?.value ?? 1.0;

        if (animationValue < 1.0) {
          // Animation de tracé - style crayon/encre avec effet fluide
          // Utiliser une courbe d'animation pour un effet plus naturel
          final curvedValue = Curves.easeOut.transform(animationValue);
          final animatedToX = fromX + (toX - fromX) * curvedValue;
          final animatedToY = fromY + (toY - fromY) * curvedValue;
          
          // Ombre portée animée avec effet de fade
          final shadowPaint = Paint()
            ..color = color.withOpacity(0.3 * curvedValue)
            ..strokeWidth = 5.5 * curvedValue
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * curvedValue);
          canvas.drawLine(
            Offset(fromX + 1, fromY + 1),
            Offset(animatedToX + 1, animatedToY + 1),
            shadowPaint,
          );

          // Trait principal animé - style encre avec épaisseur progressive
          final segmentPaint = Paint()
            ..color = color.withOpacity(0.7 + (0.3 * curvedValue))
            ..strokeWidth = 3.0 + (2.0 * curvedValue)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            Offset(fromX, fromY),
            Offset(animatedToX, animatedToY),
            segmentPaint,
          );
          
          // Effet de brillance qui suit le tracé
          if (curvedValue > 0.3) {
            final glowPaint = Paint()
              ..color = AppTheme.accentGold.withOpacity(0.4 * (curvedValue - 0.3) / 0.7)
              ..strokeWidth = 2.0
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5);
            canvas.drawLine(
              Offset(fromX, fromY),
              Offset(animatedToX, animatedToY),
              glowPaint,
            );
          }
        } else {
          // Segment final - style trait de crayon/encre
          // Ombre portée
      final shadowPaint = Paint()
            ..color = color.withOpacity(0.25)
            ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawLine(
        Offset(fromX + 1, fromY + 1),
            Offset(toX + 1, toY + 1),
        shadowPaint,
      );

          // Trait principal - style encre épais
      final segmentPaint = Paint()
        ..color = color
            ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawLine(
        Offset(fromX, fromY),
            Offset(toX, toY),
        segmentPaint,
      );
        }
      }
    });

    // Points - style point d'encre/crayon PROPRE
    final pointRadius = math.max(4.5, cellSize * 0.06);
    
    // IMPORTANT: Utiliser exactement la même cellSize que pour les lignes
    for (int row = 0; row <= gridSize; row++) {
      for (int col = 0; col <= gridSize; col++) {
        // Position exacte correspondant aux lignes
        final x = col * cellSize;
        final y = row * cellSize;
        
        // Ombre du point
        final shadowPaint = Paint()
          ..color = AppTheme.accentGold.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x + 1, y + 1), pointRadius * 0.9, shadowPaint);
        
        // Point principal - couleur dorée AppTheme
        final pointPaint = Paint()
          ..color = AppTheme.accentGold
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), pointRadius, pointPaint);
        
        // Bordure fine - couleur dorée foncée
        final borderPaint = Paint()
          ..color = AppTheme.accentGoldDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(x, y), pointRadius, borderPaint);
        
        // Reflet brillant (petit point blanc)
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(x - pointRadius * 0.3, y - pointRadius * 0.3),
          pointRadius * 0.3,
          highlightPaint,
        );
      }
    }

    // Point sélectionné - style avec couleur dorée AppTheme
    if (selectedRow != null && selectedCol != null) {
      final x = selectedCol! * cellSize;
      final y = selectedRow! * cellSize;
      
      // Halo externe - couleur dorée AppTheme
      final outerHaloPaint = Paint()
        ..color = AppTheme.accentGold.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), pointRadius * 2.5, outerHaloPaint);
      
      // Cercle de sélection - couleur dorée AppTheme
      final outerPaint = Paint()
        ..color = AppTheme.accentGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), pointRadius * 1.3, outerPaint);
        
      // Point sélectionné - couleur dorée AppTheme
      final selectedPaint = Paint()
        ..color = AppTheme.accentGold
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), pointRadius * 1.0, selectedPaint);
      
      // Reflet brillant (réduit)
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x - pointRadius * 0.2, y - pointRadius * 0.2),
        pointRadius * 0.2,
        highlightPaint,
      );
    }
  }

  // Dessiner une étoile
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final angle = math.pi / 5;
    for (int i = 0; i < 10; i++) {
      final radius = i.isEven ? size : size * 0.4;
      final x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final y = center.dy + radius * math.sin(i * angle - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NotebookGameBoardPainter oldDelegate) {
    return oldDelegate.boardState != boardState ||
        oldDelegate.completedSquares != completedSquares ||
        oldDelegate.selectedRow != selectedRow ||
        oldDelegate.selectedCol != selectedCol ||
        oldDelegate.segmentAnimations != segmentAnimations ||
        oldDelegate.squareAnimations != squareAnimations;
  }
}
