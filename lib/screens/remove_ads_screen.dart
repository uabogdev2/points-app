import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/sound_icon_button.dart';
import '../widgets/sound_button.dart';
import '../mixins/background_music_mixin.dart';

class RemoveAdsScreen extends StatefulWidget {
  const RemoveAdsScreen({super.key});

  @override
  State<RemoveAdsScreen> createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends State<RemoveAdsScreen> with BackgroundMusicMixin {
  @override
  void initState() {
    super.initState();
    // Initialiser le provider si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final purchaseProvider = context.read<PurchaseProvider>();
      if (!purchaseProvider.isLoading && purchaseProvider.product == null) {
        purchaseProvider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final adsRemoved = user?.adsRemoved ?? false;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.paperWhite,
      body: NotebookBackground(
        child: Column(
          children: [
            // Bouton retour en haut
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 32, 16, 0),
              child: Row(
                children: [
                  SoundIconButton(
                    icon: Icons.arrow_back,
                    color: AppTheme.primaryColor,
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Retour',
                  ),
                ],
              ),
            ),
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ChapterHeader(
                      title: 'Supprimer les publicités',
                      subtitle: 'Profitez d\'une expérience sans interruption',
                      icon: Icons.block,
                    ).animate().fadeIn(duration: 300.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Statut actuel
                    if (adsRemoved) ...[
                      _buildPremiumBadge(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Avantages
                    _buildBenefitsSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Bouton d'achat ou statut
                    if (adsRemoved)
                      _buildAlreadyPurchased()
                    else
                      _buildPurchaseButton(purchaseProvider),
                    
                    const SizedBox(height: 24),
                    
                    // Bouton restaurer
                    if (!adsRemoved)
                      _buildRestoreButton(purchaseProvider),
                    
                    const SizedBox(height: 16),
                    
                    // Message d'erreur
                    if (purchaseProvider.error != null)
                      _buildError(purchaseProvider.error!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentGold,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            color: AppTheme.accentGold,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Actif',
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Les publicités sont désactivées',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildBenefitsSection() {
    return PostItCard(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppTheme.primaryColor, size: 28),
              const SizedBox(width: 12),
              Text(
                'Avantages',
                style: GoogleFonts.caveat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            Icons.block,
            'Aucune publicité',
            'Jouez sans interruption',
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            Icons.speed,
            'Expérience fluide',
            'Concentrez-vous sur le jeu',
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            Icons.all_inclusive,
            'Achat unique',
            'Valable à vie',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(PurchaseProvider purchaseProvider) {
    final product = purchaseProvider.product;
    final isLoading = purchaseProvider.isLoading || purchaseProvider.isPurchasing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (product != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.gridLine.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  product.title,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.price,
                  style: GoogleFonts.caveat(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        NotebookButton(
          onPressed: isLoading
              ? null
              : () async {
                  purchaseProvider.clearError();
                  await purchaseProvider.purchaseRemoveAds();
                  // Rafraîchir le statut utilisateur après l'achat
                  if (mounted) {
                    final authProvider = context.read<AuthProvider>();
                    await authProvider.refreshUser();
                    final updatedUser = authProvider.user;
                    if ((updatedUser?.adsRemoved ?? false) && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Achat réussi ! Les publicités sont maintenant désactivées.',
                            style: GoogleFonts.nunito(),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
          text: isLoading ? 'Chargement...' : 'Acheter maintenant',
          icon: Icons.shopping_cart,
          backgroundColor: AppTheme.accentGold,
          textColor: Colors.white,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildAlreadyPurchased() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(width: 12),
          Text(
            'Déjà acheté',
            style: GoogleFonts.caveat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildRestoreButton(PurchaseProvider purchaseProvider) {
    return SoundTextButton(
      onPressed: purchaseProvider.isRestoring
          ? null
          : () async {
              purchaseProvider.clearError();
              await purchaseProvider.restorePurchases();
              if (mounted) {
                final authProvider = context.read<AuthProvider>();
                await authProvider.refreshUser();
                final updatedUser = authProvider.user;
                if ((updatedUser?.adsRemoved ?? false) && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Achats restaurés avec succès !',
                        style: GoogleFonts.nunito(),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Aucun achat à restaurer.',
                        style: GoogleFonts.nunito(),
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (purchaseProvider.isRestoring)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.restore, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            purchaseProvider.isRestoring ? 'Restauration...' : 'Restaurer les achats',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

