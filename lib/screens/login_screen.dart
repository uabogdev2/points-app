import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import 'webview_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotebookBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animé style cahier
                  _buildLogo()
                      .animate()
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 400.ms),
                  
                  const SizedBox(height: 32),
                  
                  // Titre manuscrit
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    style: GoogleFonts.caveat(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                  
                  const SizedBox(height: 8),
                  
                  // Sous-titre
                  Text(
                    AppLocalizations.of(context)!.appSubtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: Colors.grey[600],
                      letterSpacing: 1,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  
                  const SizedBox(height: 16),
                  
                  // Ligne décorative style crayon
                  Container(
                    width: 80,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate().scaleX(delay: 500.ms, duration: 400.ms),
                  
                  const SizedBox(height: 64),
                  
                  // Texte d'instruction style note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4).withOpacity(0.7), // Jaune post-it
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.connectToSave,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.caveat(
                        fontSize: 18,
                        color: Colors.grey[800],
                        height: 1.3,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 32),

                  // Bouton Google - Style cahier (Android uniquement)
                  if (Platform.isAndroid)
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return _buildAuthButton(
                          context: context,
                          label: AppLocalizations.of(context)!.continueWithGoogle,
                          icon: Icons.g_mobiledata,
                          color: AppTheme.inkBlue,
                          isLoading: authProvider.isLoading,
                          onPressed: () => _signInWithGoogle(context, authProvider),
                        );
                      },
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
                  
                  // Bouton Apple - Style cahier (iOS uniquement)
                  if (Platform.isIOS)
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return _buildAuthButton(
                          context: context,
                          label: AppLocalizations.of(context)!.continueWithApple,
                          icon: Icons.apple,
                          color: Colors.black87,
                          isLoading: authProvider.isLoading,
                          onPressed: () => _signInWithApple(context, authProvider),
                        );
                      },
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 48),
                  
                  // Footer avec liens
                  _buildFooter(context).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/image/logo-app.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  Icon(icon, size: 28, color: color),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, AuthProvider authProvider) async {
    debugPrint('🔵 LoginScreen: Début de la connexion Google');
    try {
      final success = await authProvider.signInWithGoogle();
      debugPrint('🔵 LoginScreen: Résultat connexion: $success');
      
      if (success && context.mounted) {
        debugPrint('✅ LoginScreen: Navigation vers /home');
        // L'action en attente sera traitée automatiquement par HomeScreen après connexion
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (context.mounted && authProvider.error != null) {
        _showErrorSnackbar(context, authProvider.error!);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ LoginScreen: Exception: $e');
      debugPrint('❌ LoginScreen: Stack trace: $stackTrace');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context, AuthProvider authProvider) async {
    final success = await authProvider.signInWithApple();
    if (success && context.mounted) {
      // L'action en attente sera traitée automatiquement par HomeScreen après connexion
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (context.mounted && authProvider.error != null) {
      _showErrorSnackbar(context, authProvider.error!);
    }
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Construire le texte avec les placeholders
    final acceptTermsText = l10n.acceptTerms(l10n.terms, l10n.privacy);
    // Extraire les parties du texte
    final parts = acceptTermsText.split(l10n.terms);
    final beforeTerms = parts.isNotEmpty ? parts[0] : '';
    final afterTerms = parts.length > 1 ? parts[1].split(l10n.privacy) : [];
    final betweenTermsAndPrivacy = afterTerms.isNotEmpty ? afterTerms[0] : '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          children: [
            TextSpan(text: beforeTerms),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebViewScreen(
                        url: 'https://ivoirelabs.com/terms',
                        title: l10n.terms,
                      ),
                    ),
                  );
                },
                child: Text(
                  l10n.terms,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            TextSpan(text: betweenTermsAndPrivacy),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebViewScreen(
                        url: 'https://ivoirelabs.com/privacy',
                        title: l10n.privacy,
                      ),
                    ),
                  );
                },
                child: Text(
                  l10n.privacy,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.nunito(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

