import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème "Cahier d'école Premium" - Points Master
class AppTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // COULEURS PRINCIPALES - Style Cahier d'École
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Bleu nuit (couleur dominante)
  static const Color primaryColor = Color(0xFF1A237E);      // Bleu nuit profond
  static const Color primaryLight = Color(0xFF534bae);      // Bleu nuit clair
  static const Color primaryDark = Color(0xFF000051);       // Bleu nuit foncé
  
  // Couleurs secondaires
  static const Color accentGold = Color(0xFFFFD700);        // Or pour badges
  static const Color accentGoldDark = Color(0xFFDAA520);    // Or foncé
  static const Color inkBlue = Color(0xFF1565C0);           // Encre bleue
  static const Color inkRed = Color(0xFFB71C1C);            // Encre rouge (correction)
  
  // Fond papier cahier
  static const Color paperWhite = Color(0xFFFFFDF7);        // Blanc cassé papier
  static const Color paperCream = Color(0xFFF5F5DC);        // Crème
  static const Color gridLine = Color(0xFFB8D4E8);          // Ligne quadrillage bleu clair
  static const Color marginLine = Color(0xFFE57373);        // Ligne de marge rouge
  
  // Couleurs de jeu
  static const Color player1Color = Color(0xFF1565C0);      // Bleu encre
  static const Color player2Color = Color(0xFFD32F2F);      // Rouge encre
  static const Color completedSquareColor = Color(0xFFFFD54F); // Jaune surligneur
  
  // Couleurs d'état
  static const Color successColor = Color(0xFF2E7D32);      // Vert validation
  static const Color errorColor = Color(0xFFC62828);        // Rouge erreur
  static const Color warningColor = Color(0xFFF9A825);      // Orange attention
  
  // Mode sombre - Ardoise
  static const Color slateDark = Color(0xFF2D3436);         // Ardoise
  static const Color chalkWhite = Color(0xFFFDFDFD);        // Craie blanche
  static const Color chalkYellow = Color(0xFFFFF59D);       // Craie jaune
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ALIAS POUR COMPATIBILITÉ
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color secondaryColor = accentGold;
  static const Color backgroundColor = paperWhite;
  static const Color gridColor = gridLine;

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHIE - Style Manuscrit + Moderne
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Police manuscrite pour les titres
  static TextStyle get handwritingTitle => GoogleFonts.caveat(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 1.2,
  );
  
  /// Police manuscrite pour sous-titres
  static TextStyle get handwritingSubtitle => GoogleFonts.caveat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: primaryColor.withOpacity(0.8),
  );
  
  /// Police manuscrite pour les scores/nombres
  static TextStyle get handwritingNumber => GoogleFonts.caveat(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: inkBlue,
  );
  
  /// Police moderne pour le corps de texte
  static TextStyle get bodyText => GoogleFonts.nunito(
    fontSize: 16,
    color: Colors.black87,
  );
  
  /// Police moderne pour les boutons
  static TextStyle get buttonText => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DÉCORATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Ombre style cahier (légère)
  static List<BoxShadow> get paperShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  /// Ombre prononcée pour les cartes
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Bordure style crayon
  static Border get pencilBorder => Border.all(
    color: primaryColor.withOpacity(0.3),
    width: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // THÈME CLAIR (Cahier)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentGold,
        surface: paperWhite,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: primaryColor,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: paperWhite,
      
      // AppBar style cahier
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: paperWhite,
        foregroundColor: primaryColor,
        titleTextStyle: GoogleFonts.caveat(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      
      // Cartes style page de cahier
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: gridLine.withOpacity(0.5), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // Boutons avec style encre
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      
      // Boutons outline style crayon
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      
      // Champs de texte style ligne de cahier
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gridLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gridLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.nunito(color: Colors.grey[600]),
        hintStyle: GoogleFonts.nunito(color: Colors.grey[400]),
      ),
      
      // Navigation bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.nunito(),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Typographie générale
      textTheme: TextTheme(
        displayLarge: GoogleFonts.caveat(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        displayMedium: GoogleFonts.caveat(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        displaySmall: GoogleFonts.caveat(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        headlineLarge: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineMedium: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        headlineSmall: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          color: Colors.black87,
        ),
        bodySmall: GoogleFonts.nunito(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      
      // Floating action button style badge doré
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: primaryColor,
        elevation: 4,
      ),
      
      // Chips style étiquette
      chipTheme: ChipThemeData(
        backgroundColor: paperCream,
        labelStyle: GoogleFonts.nunito(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
      ),
      
      // Divider style ligne de cahier
      dividerTheme: DividerThemeData(
        color: gridLine,
        thickness: 1,
        space: 24,
      ),
      
      // Snackbar style post-it
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFFFF9C4), // Jaune post-it
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.black87,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog style page arrachée
      dialogTheme: DialogThemeData(
        backgroundColor: paperWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.caveat(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THÈME SOMBRE (Ardoise)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: chalkWhite,
        secondary: chalkYellow,
        surface: slateDark,
        error: const Color(0xFFEF5350),
        onPrimary: slateDark,
        onSecondary: slateDark,
        onSurface: chalkWhite,
      ),
      scaffoldBackgroundColor: slateDark,
      
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: slateDark,
        foregroundColor: chalkWhite,
        titleTextStyle: GoogleFonts.caveat(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: chalkWhite,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF3D4447),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.caveat(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: chalkWhite,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          color: chalkWhite,
        ),
      ),
    );
  }
}
