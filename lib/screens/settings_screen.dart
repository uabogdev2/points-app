import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Points_Points/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/audio_settings_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_widgets.dart';
import '../widgets/sound_icon_button.dart';
import '../widgets/sound_button.dart';
import '../models/user.dart';
import '../mixins/background_music_mixin.dart';
import 'edit_profile_screen.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with BackgroundMusicMixin {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final audioProvider = context.watch<AudioSettingsProvider>();
    final notificationProvider = context.watch<NotificationSettingsProvider>();
    
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
                      title: AppLocalizations.of(context)!.settings,
                      subtitle: AppLocalizations.of(context)!.personalizeExperience,
                      icon: Icons.settings,
                    ).animate().fadeIn(duration: 300.ms),
              
              const SizedBox(height: 24),
              
              // Profil
              _buildSection(
                title: AppLocalizations.of(context)!.profile,
                icon: Icons.person,
                color: AppTheme.primaryColor,
                children: [
                  if (user != null) ...[
                    _buildProfileInfo(user),
                    const SizedBox(height: 16),
                  ],
                  FutureBuilder<bool>(
                    future: StorageService.canUpdateProfile(),
                    builder: (context, snapshot) {
                      final canUpdate = snapshot.data ?? false;
                      final lastUpdate = snapshot.connectionState == ConnectionState.done
                          ? null
                          : null; // On pourrait récupérer la date si nécessaire
                      
                      return _buildSettingTile(
                        icon: Icons.edit,
                        title: AppLocalizations.of(context)!.editProfile,
                        subtitle: canUpdate
                            ? AppLocalizations.of(context)!.editProfileSubtitle
                            : AppLocalizations.of(context)!.editProfileLimited,
                        onTap: canUpdate
                            ? () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                                if (result == true && mounted) {
                                  setState(() {}); // Rafraîchir l'écran
                                }
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!.profileUpdateLimit,
                                      style: GoogleFonts.nunito(),
                                    ),
                                    backgroundColor: AppTheme.errorColor,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                      );
                    },
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 24),
              
              // Notifications
              _buildSection(
                title: AppLocalizations.of(context)!.notifications,
                icon: Icons.notifications,
                color: AppTheme.inkBlue,
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_active,
                    title: AppLocalizations.of(context)!.pushNotifications,
                    subtitle: AppLocalizations.of(context)!.pushNotificationsSubtitle,
                    value: notificationProvider.pushNotificationsEnabled,
                    onChanged: (value) {
                      context.read<NotificationSettingsProvider>().setPushNotificationsEnabled(value);
                    },
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
              
              const SizedBox(height: 24),
              
              // Langue
              _buildSection(
                title: AppLocalizations.of(context)!.language,
                icon: Icons.language,
                color: const Color(0xFF00796B),
                children: [
                  _buildLanguageSelector(context),
                ],
              ).animate().fadeIn(delay: 350.ms),
              
              const SizedBox(height: 24),
              
              // Audio
              _buildSection(
                title: AppLocalizations.of(context)!.audio,
                icon: Icons.music_note,
                color: AppTheme.accentGoldDark,
                children: [
                  // Musique de fond
                  _buildSwitchTile(
                    icon: Icons.music_note,
                    title: AppLocalizations.of(context)!.backgroundMusic,
                    subtitle: AppLocalizations.of(context)!.backgroundMusicSubtitle,
                    value: audioProvider.isMusicEnabled,
                    onChanged: (value) {
                      context.read<AudioSettingsProvider>().setMusicEnabled(value);
                    },
                  ),
                  if (audioProvider.isMusicEnabled) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.volume,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${(audioProvider.musicVolume * 100).toInt()}%',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: audioProvider.musicVolume,
                            onChanged: (value) {
                              context.read<AudioSettingsProvider>().setMusicVolume(value);
                            },
                            activeColor: AppTheme.primaryColor,
                            inactiveColor: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Sons de jeu
                  _buildSwitchTile(
                    icon: Icons.volume_up,
                    title: AppLocalizations.of(context)!.gameSounds,
                    subtitle: AppLocalizations.of(context)!.gameSoundsSubtitle,
                    value: audioProvider.isSoundEnabled,
                    onChanged: (value) {
                      context.read<AudioSettingsProvider>().setSoundEnabled(value);
                    },
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 32),
              
              // Bouton de déconnexion
              NotebookButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.signOutConfirm),
                      content: Text(AppLocalizations.of(context)!.signOutMessage),
                      actions: [
                        SoundTextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        SoundElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(AppLocalizations.of(context)!.signOutConfirm),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && context.mounted) {
                    try {
                      await context.read<AuthProvider>().signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.signOutError(e.toString())),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                text: AppLocalizations.of(context)!.signOut,
                icon: Icons.logout,
                backgroundColor: Colors.red,
                textColor: Colors.white,
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 16),
              
              // Bouton supprimer mes données
              NotebookButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: AppTheme.paperWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: AppTheme.gridLine.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icône
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                size: 32,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Titre
                            Text(
                              AppLocalizations.of(context)!.deleteMyData,
                              style: GoogleFonts.caveat(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            // Message
                            Text(
                              AppLocalizations.of(context)!.deleteMyDataMessage,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Boutons
                            Row(
                              children: [
                                Expanded(
                                  child: SoundTextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      AppLocalizations.of(context)!.cancel,
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SoundElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.yes,
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
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
                  
                  if (confirm == true && context.mounted) {
                    final uri = Uri.parse('https://account.ivoirelabs.com/');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.cannotOpenUrl,
                              style: GoogleFonts.nunito(),
                            ),
                            backgroundColor: AppTheme.errorColor,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  }
                },
                text: AppLocalizations.of(context)!.deleteMyData,
                icon: Icons.delete_outline,
                backgroundColor: Colors.orange,
                textColor: Colors.white,
              ).animate().fadeIn(delay: 700.ms),
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
  
  Widget _buildProfileInfo(User user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.name[0].toUpperCase(),
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (user.email != null)
                Text(
                  user.email!,
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
  
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }
  
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    
    String currentLanguageText;
    if (localeProvider.isUsingSystemLocale) {
      currentLanguageText = l10n.systemDefault;
    } else if (localeProvider.currentLanguageCode == 'fr') {
      currentLanguageText = l10n.french;
    } else {
      currentLanguageText = l10n.english;
    }
    
    return ListTile(
      leading: Icon(Icons.language, color: AppTheme.primaryColor),
      title: Text(
        l10n.language,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      subtitle: Text(
        l10n.languageSubtitle,
        style: GoogleFonts.nunito(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLanguageText,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor, size: 16),
        ],
      ),
      onTap: () => _showLanguageDialog(context, localeProvider, l10n),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppTheme.paperWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.gridLine.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre style cahier
              Row(
                children: [
                  Icon(Icons.language, color: AppTheme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    l10n.language,
                    style: GoogleFonts.caveat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.languageSubtitle,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Options de langue style cahier
              _buildLanguageOption(
                context: dialogContext,
                localeProvider: localeProvider,
                locale: null,
                title: l10n.systemDefault,
                icon: Icons.settings,
                isSelected: localeProvider.isUsingSystemLocale,
                onTap: () async {
                  await localeProvider.setLocale(null);
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context: dialogContext,
                localeProvider: localeProvider,
                locale: const Locale('fr'),
                title: l10n.french,
                icon: Icons.flag,
                isSelected: localeProvider.currentLanguageCode == 'fr' && !localeProvider.isUsingSystemLocale,
                onTap: () async {
                  await localeProvider.setLocale(const Locale('fr'));
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context: dialogContext,
                localeProvider: localeProvider,
                locale: const Locale('en'),
                title: l10n.english,
                icon: Icons.flag,
                isSelected: localeProvider.currentLanguageCode == 'en' && !localeProvider.isUsingSystemLocale,
                onTap: () async {
                  await localeProvider.setLocale(const Locale('en'));
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required LocaleProvider localeProvider,
    required Locale? locale,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor
                : AppTheme.gridLine.withOpacity(0.5),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

