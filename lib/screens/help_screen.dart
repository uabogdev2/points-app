import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/sound_icon_button.dart';
import '../mixins/background_music_mixin.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with BackgroundMusicMixin {
  @override
  Widget build(BuildContext context) {
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
                      title: AppLocalizations.of(context)!.howToPlay,
                      subtitle: AppLocalizations.of(context)!.gameGuide,
                      icon: Icons.help_outline,
                    ).animate().fadeIn(duration: 300.ms),
              
              const SizedBox(height: 24),
              
              // Règles du jeu
              _buildSection(
                title: AppLocalizations.of(context)!.gameRules,
                icon: Icons.rule,
                color: AppTheme.primaryColor,
                children: [
                  _buildRuleItem(
                    AppLocalizations.of(context)!.rule1,
                    AppLocalizations.of(context)!.rule1Desc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.rule2,
                    AppLocalizations.of(context)!.rule2Desc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.rule3,
                    AppLocalizations.of(context)!.rule3Desc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.rule4,
                    AppLocalizations.of(context)!.rule4Desc,
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 24),
              
              // Modes de jeu
              _buildSection(
                title: AppLocalizations.of(context)!.gameModesSection,
                icon: Icons.sports_esports,
                color: AppTheme.inkBlue,
                children: [
                  _buildRuleItem(
                    AppLocalizations.of(context)!.soloMode,
                    AppLocalizations.of(context)!.soloModeDesc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.duoMode,
                    AppLocalizations.of(context)!.duoModeDesc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.quickMatchMode,
                    AppLocalizations.of(context)!.quickMatchModeDesc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.privateGameMode,
                    AppLocalizations.of(context)!.privateGameModeDesc,
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
              
              const SizedBox(height: 24),
              
              // Conseils
              _buildSection(
                title: AppLocalizations.of(context)!.tipsAndTricks,
                icon: Icons.lightbulb_outline,
                color: AppTheme.accentGoldDark,
                children: [
                  _buildRuleItem(
                    AppLocalizations.of(context)!.tip1,
                    AppLocalizations.of(context)!.tip1Desc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.tip2,
                    AppLocalizations.of(context)!.tip2Desc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.tip3,
                    AppLocalizations.of(context)!.tip3Desc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.tip4,
                    AppLocalizations.of(context)!.tip4Desc,
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 24),
              
              // FAQ
              _buildSection(
                title: AppLocalizations.of(context)!.faq,
                icon: Icons.question_answer,
                color: const Color(0xFF7B1FA2),
                children: [
                  _buildRuleItem(
                    AppLocalizations.of(context)!.faq1,
                    AppLocalizations.of(context)!.faq1Desc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.faq2,
                    AppLocalizations.of(context)!.faq2Desc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.faq3,
                    AppLocalizations.of(context)!.faq3Desc,
                  ),
                  _buildRuleItem(
                    AppLocalizations.of(context)!.faq4,
                    AppLocalizations.of(context)!.faq4Desc,
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return PostItCard(
      color: color.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.caveat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildRuleItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

