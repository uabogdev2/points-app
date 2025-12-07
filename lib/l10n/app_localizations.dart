import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Le titre de l'application
  ///
  /// In fr, this message translates to:
  /// **'Points Master'**
  String get appTitle;

  /// Sous-titre de l'application
  ///
  /// In fr, this message translates to:
  /// **'Le jeu de stratégie ultime'**
  String get appSubtitle;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue,'**
  String get welcome;

  /// No description provided for @player.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get player;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get continueWithApple;

  /// No description provided for @connectToSave.
  ///
  /// In fr, this message translates to:
  /// **'📝 Connectez-vous pour sauvegarder\nvos scores et défier vos amis !'**
  String get connectToSave;

  /// No description provided for @acceptTerms.
  ///
  /// In fr, this message translates to:
  /// **'En continuant, vous acceptez nos {terms} et notre {privacy}'**
  String acceptTerms(String terms, String privacy);

  /// No description provided for @terms.
  ///
  /// In fr, this message translates to:
  /// **'conditions'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In fr, this message translates to:
  /// **'politique de confidentialité'**
  String get privacy;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @stats.
  ///
  /// In fr, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @leaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get leaderboard;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get help;

  /// No description provided for @quitApp.
  ///
  /// In fr, this message translates to:
  /// **'Quitter l\'application ?'**
  String get quitApp;

  /// No description provided for @quitAppConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir quitter Points Master ?'**
  String get quitAppConfirm;

  /// No description provided for @quit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get quit;

  /// No description provided for @gameModes.
  ///
  /// In fr, this message translates to:
  /// **'Modes de jeu'**
  String get gameModes;

  /// No description provided for @chooseAdventure.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre aventure'**
  String get chooseAdventure;

  /// No description provided for @solo.
  ///
  /// In fr, this message translates to:
  /// **'Solo'**
  String get solo;

  /// No description provided for @soloSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Défiez l\'intelligence artificielle'**
  String get soloSubtitle;

  /// No description provided for @duo.
  ///
  /// In fr, this message translates to:
  /// **'Duo'**
  String get duo;

  /// No description provided for @duoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'2 joueurs sur le même écran'**
  String get duoSubtitle;

  /// No description provided for @quickMatch.
  ///
  /// In fr, this message translates to:
  /// **'Partie Rapide'**
  String get quickMatch;

  /// No description provided for @quickMatchSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez un adversaire en ligne'**
  String get quickMatchSubtitle;

  /// No description provided for @privateGame.
  ///
  /// In fr, this message translates to:
  /// **'Partie Privée'**
  String get privateGame;

  /// No description provided for @privateGameSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez une salle avec code QR'**
  String get privateGameSubtitle;

  /// No description provided for @others.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get others;

  /// No description provided for @helpAndSettings.
  ///
  /// In fr, this message translates to:
  /// **'Aide et paramètres'**
  String get helpAndSettings;

  /// No description provided for @victories.
  ///
  /// In fr, this message translates to:
  /// **'Victoires'**
  String get victories;

  /// No description provided for @streak.
  ///
  /// In fr, this message translates to:
  /// **'Série'**
  String get streak;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Changez votre nom et votre avatar'**
  String get editProfileSubtitle;

  /// No description provided for @editProfileLimited.
  ///
  /// In fr, this message translates to:
  /// **'Modification limitée à 1 fois par semaine'**
  String get editProfileLimited;

  /// No description provided for @profileUpdateLimit.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez modifier votre profil une fois par semaine. Veuillez réessayer plus tard.'**
  String get profileUpdateLimit;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir des notifications'**
  String get pushNotificationsSubtitle;

  /// No description provided for @audio.
  ///
  /// In fr, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @backgroundMusic.
  ///
  /// In fr, this message translates to:
  /// **'Musique de fond'**
  String get backgroundMusic;

  /// No description provided for @backgroundMusicSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer la musique de fond'**
  String get backgroundMusicSubtitle;

  /// No description provided for @volume.
  ///
  /// In fr, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @gameSounds.
  ///
  /// In fr, this message translates to:
  /// **'Sons de jeu'**
  String get gameSounds;

  /// No description provided for @gameSoundsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer les sons (clic, succès)'**
  String get gameSoundsSubtitle;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue de l\'application'**
  String get languageSubtitle;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// No description provided for @systemDefault.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut (système)'**
  String get systemDefault;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get signOutConfirm;

  /// No description provided for @signOutMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get signOutMessage;

  /// No description provided for @signOutError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la déconnexion: {error}'**
  String signOutError(String error);

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @loadingGame.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la partie...'**
  String get loadingGame;

  /// No description provided for @loadingStats.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des stats...'**
  String get loadingStats;

  /// No description provided for @loadingLeaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du classement...'**
  String get loadingLeaderboard;

  /// No description provided for @connectionInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours...'**
  String get connectionInProgress;

  /// No description provided for @gameNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Partie introuvable'**
  String get gameNotFound;

  /// No description provided for @forfeit.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner ?'**
  String get forfeit;

  /// No description provided for @forfeitMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre adversaire gagnera automatiquement.'**
  String get forfeitMessage;

  /// No description provided for @forfeitAction.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get forfeitAction;

  /// No description provided for @waiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente...'**
  String get waiting;

  /// No description provided for @waitingOpponent.
  ///
  /// In fr, this message translates to:
  /// **'Un adversaire va bientôt rejoindre'**
  String get waitingOpponent;

  /// No description provided for @onlineGame.
  ///
  /// In fr, this message translates to:
  /// **'Partie en ligne'**
  String get onlineGame;

  /// No description provided for @gameNumber.
  ///
  /// In fr, this message translates to:
  /// **'Partie #{gameId}'**
  String gameNumber(int gameId);

  /// No description provided for @yourTurn.
  ///
  /// In fr, this message translates to:
  /// **'À vous de jouer !'**
  String get yourTurn;

  /// No description provided for @opponentTurn.
  ///
  /// In fr, this message translates to:
  /// **'Tour de l\'adversaire'**
  String get opponentTurn;

  /// No description provided for @player1.
  ///
  /// In fr, this message translates to:
  /// **'Joueur 1'**
  String get player1;

  /// No description provided for @player2.
  ///
  /// In fr, this message translates to:
  /// **'Joueur 2'**
  String get player2;

  /// No description provided for @you.
  ///
  /// In fr, this message translates to:
  /// **'vous'**
  String get you;

  /// No description provided for @vs.
  ///
  /// In fr, this message translates to:
  /// **'VS'**
  String get vs;

  /// No description provided for @squares.
  ///
  /// In fr, this message translates to:
  /// **'carrés'**
  String get squares;

  /// No description provided for @victory.
  ///
  /// In fr, this message translates to:
  /// **'Victoire !'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In fr, this message translates to:
  /// **'Défaite'**
  String get defeat;

  /// No description provided for @draw.
  ///
  /// In fr, this message translates to:
  /// **'Match nul !'**
  String get draw;

  /// No description provided for @winner.
  ///
  /// In fr, this message translates to:
  /// **'Vainqueur'**
  String get winner;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// No description provided for @updateRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour requise'**
  String get updateRequired;

  /// No description provided for @updateAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour disponible'**
  String get updateAvailable;

  /// No description provided for @currentVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version actuelle: {version}'**
  String currentVersion(String version);

  /// No description provided for @latestVersion.
  ///
  /// In fr, this message translates to:
  /// **'Dernière version: {version}'**
  String latestVersion(String version);

  /// No description provided for @updateLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get updateLater;

  /// No description provided for @update.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get update;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'La mise à jour est requise pour continuer.'**
  String get updateRequiredMessage;

  /// No description provided for @updateError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le lien. Veuillez mettre à jour manuellement depuis le store.'**
  String get updateError;

  /// No description provided for @updateUrlError.
  ///
  /// In fr, this message translates to:
  /// **'URL de mise à jour non disponible. Veuillez mettre à jour depuis le store.'**
  String get updateUrlError;

  /// No description provided for @gridSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille de la grille'**
  String get gridSize;

  /// No description provided for @gridSize3x3.
  ///
  /// In fr, this message translates to:
  /// **'3x3'**
  String get gridSize3x3;

  /// No description provided for @gridSize5x5.
  ///
  /// In fr, this message translates to:
  /// **'5x5'**
  String get gridSize5x5;

  /// No description provided for @gridSize8x8.
  ///
  /// In fr, this message translates to:
  /// **'8x8'**
  String get gridSize8x8;

  /// No description provided for @gridSize12x12.
  ///
  /// In fr, this message translates to:
  /// **'12x12'**
  String get gridSize12x12;

  /// No description provided for @difficulty.
  ///
  /// In fr, this message translates to:
  /// **'Difficulté'**
  String get difficulty;

  /// No description provided for @chooseDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre niveau de défi'**
  String get chooseDifficulty;

  /// No description provided for @beginner.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get beginner;

  /// No description provided for @beginnerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Parfait pour apprendre les règles'**
  String get beginnerSubtitle;

  /// No description provided for @normal.
  ///
  /// In fr, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @normalSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un défi équilibré'**
  String get normalSubtitle;

  /// No description provided for @expert.
  ///
  /// In fr, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @expertSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour les vrais stratèges'**
  String get expertSubtitle;

  /// No description provided for @gridSizeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Plus la grille est grande, plus c\'est stratégique'**
  String get gridSizeSubtitle;

  /// No description provided for @quickGame.
  ///
  /// In fr, this message translates to:
  /// **'Partie rapide • ~2 min'**
  String get quickGame;

  /// No description provided for @classicGame.
  ///
  /// In fr, this message translates to:
  /// **'Classique • ~5 min'**
  String get classicGame;

  /// No description provided for @strategicGame.
  ///
  /// In fr, this message translates to:
  /// **'Stratégique • ~10 min'**
  String get strategicGame;

  /// No description provided for @expertGame.
  ///
  /// In fr, this message translates to:
  /// **'Expert • ~20 min'**
  String get expertGame;

  /// No description provided for @createGame.
  ///
  /// In fr, this message translates to:
  /// **'Créer une partie'**
  String get createGame;

  /// No description provided for @createGameSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Générer un code et un QR code'**
  String get createGameSubtitle;

  /// No description provided for @joinGame.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre une partie'**
  String get joinGame;

  /// No description provided for @joinGameSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un QR code ou entrer un code'**
  String get joinGameSubtitle;

  /// No description provided for @duoInfo.
  ///
  /// In fr, this message translates to:
  /// **'Jouez à deux sur le même écran !\nPassez le téléphone à votre adversaire.'**
  String get duoInfo;

  /// No description provided for @privateGameInfo.
  ///
  /// In fr, this message translates to:
  /// **'Créez une partie privée et partagez\nle code QR avec votre ami !'**
  String get privateGameInfo;

  /// No description provided for @options.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @createOrJoin.
  ///
  /// In fr, this message translates to:
  /// **'Créer ou rejoindre une partie'**
  String get createOrJoin;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @yourPerformance.
  ///
  /// In fr, this message translates to:
  /// **'Vos performances'**
  String get yourPerformance;

  /// No description provided for @noStatistics.
  ///
  /// In fr, this message translates to:
  /// **'Aucune statistique'**
  String get noStatistics;

  /// No description provided for @playToUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Jouez pour débloquer vos stats !'**
  String get playToUnlock;

  /// No description provided for @overview.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble'**
  String get overview;

  /// No description provided for @games.
  ///
  /// In fr, this message translates to:
  /// **'Parties'**
  String get games;

  /// No description provided for @winRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de victoire'**
  String get winRate;

  /// No description provided for @rate.
  ///
  /// In fr, this message translates to:
  /// **'Taux'**
  String get rate;

  /// No description provided for @matchmaking.
  ///
  /// In fr, this message translates to:
  /// **'Partie Rapide'**
  String get matchmaking;

  /// No description provided for @forRanking.
  ///
  /// In fr, this message translates to:
  /// **'Pour le classement'**
  String get forRanking;

  /// No description provided for @playMatchmaking.
  ///
  /// In fr, this message translates to:
  /// **'Jouez en mode \"Partie Rapide\" pour apparaître dans le classement'**
  String get playMatchmaking;

  /// No description provided for @defeats.
  ///
  /// In fr, this message translates to:
  /// **'Défaites'**
  String get defeats;

  /// No description provided for @bestScore.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur score'**
  String get bestScore;

  /// No description provided for @squaresCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Carrés complétés'**
  String get squaresCompleted;

  /// No description provided for @currentStreak.
  ///
  /// In fr, this message translates to:
  /// **'Série actuelle'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In fr, this message translates to:
  /// **'Meilleure série'**
  String get longestStreak;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @topPlayers.
  ///
  /// In fr, this message translates to:
  /// **'Top Joueurs'**
  String get topPlayers;

  /// No description provided for @bestOfTheMoment.
  ///
  /// In fr, this message translates to:
  /// **'Les meilleurs du moment'**
  String get bestOfTheMoment;

  /// No description provided for @joinRanking.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez le classement et devenez le Points Master !'**
  String get joinRanking;

  /// No description provided for @noLeaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Aucun classement disponible'**
  String get noLeaderboard;

  /// No description provided for @playToAppear.
  ///
  /// In fr, this message translates to:
  /// **'Jouez en mode \"Partie Rapide\" pour apparaître dans le classement !'**
  String get playToAppear;

  /// No description provided for @pointsMaster.
  ///
  /// In fr, this message translates to:
  /// **'POINTS MASTER'**
  String get pointsMaster;

  /// No description provided for @howToPlay.
  ///
  /// In fr, this message translates to:
  /// **'Comment jouer'**
  String get howToPlay;

  /// No description provided for @gameGuide.
  ///
  /// In fr, this message translates to:
  /// **'Guide du jeu Points Master'**
  String get gameGuide;

  /// No description provided for @gameRules.
  ///
  /// In fr, this message translates to:
  /// **'Règles du jeu'**
  String get gameRules;

  /// No description provided for @rule1.
  ///
  /// In fr, this message translates to:
  /// **'1. Connectez deux points'**
  String get rule1;

  /// No description provided for @rule1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur un point, puis sur un autre point adjacent pour créer un segment.'**
  String get rule1Desc;

  /// No description provided for @rule2.
  ///
  /// In fr, this message translates to:
  /// **'2. Complétez des carrés'**
  String get rule2;

  /// No description provided for @rule2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Lorsque vous complétez les 4 côtés d\'un carré, vous marquez un point.'**
  String get rule2Desc;

  /// No description provided for @rule3.
  ///
  /// In fr, this message translates to:
  /// **'3. Gagnez des points'**
  String get rule3;

  /// No description provided for @rule3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Le joueur avec le plus de points à la fin de la partie gagne.'**
  String get rule3Desc;

  /// No description provided for @rule4.
  ///
  /// In fr, this message translates to:
  /// **'4. Stratégie'**
  String get rule4;

  /// No description provided for @rule4Desc.
  ///
  /// In fr, this message translates to:
  /// **'Essayez de compléter plusieurs carrés en un seul coup pour maximiser vos points.'**
  String get rule4Desc;

  /// No description provided for @gameModesSection.
  ///
  /// In fr, this message translates to:
  /// **'Modes de jeu'**
  String get gameModesSection;

  /// No description provided for @soloMode.
  ///
  /// In fr, this message translates to:
  /// **'Solo'**
  String get soloMode;

  /// No description provided for @soloModeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Jouez contre l\'intelligence artificielle. Parfait pour s\'entraîner.'**
  String get soloModeDesc;

  /// No description provided for @duoMode.
  ///
  /// In fr, this message translates to:
  /// **'Duo'**
  String get duoMode;

  /// No description provided for @duoModeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Jouez à deux sur le même écran. Idéal pour jouer avec un ami.'**
  String get duoModeDesc;

  /// No description provided for @quickMatchMode.
  ///
  /// In fr, this message translates to:
  /// **'Partie Rapide'**
  String get quickMatchMode;

  /// No description provided for @quickMatchModeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez un adversaire en ligne et jouez en temps réel.'**
  String get quickMatchModeDesc;

  /// No description provided for @privateGameMode.
  ///
  /// In fr, this message translates to:
  /// **'Partie Privée'**
  String get privateGameMode;

  /// No description provided for @privateGameModeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Créez une salle avec un code QR et invitez vos amis.'**
  String get privateGameModeDesc;

  /// No description provided for @tipsAndTricks.
  ///
  /// In fr, this message translates to:
  /// **'Conseils et astuces'**
  String get tipsAndTricks;

  /// No description provided for @tip1.
  ///
  /// In fr, this message translates to:
  /// **'Bloquez votre adversaire'**
  String get tip1;

  /// No description provided for @tip1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Empêchez votre adversaire de compléter des carrés en bloquant ses mouvements.'**
  String get tip1Desc;

  /// No description provided for @tip2.
  ///
  /// In fr, this message translates to:
  /// **'Planifiez vos coups'**
  String get tip2;

  /// No description provided for @tip2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Regardez plusieurs coups à l\'avance pour maximiser vos opportunités.'**
  String get tip2Desc;

  /// No description provided for @tip3.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre temps'**
  String get tip3;

  /// No description provided for @tip3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez un temps limité par tour. Utilisez-le à bon escient.'**
  String get tip3Desc;

  /// No description provided for @tip4.
  ///
  /// In fr, this message translates to:
  /// **'Observez le plateau'**
  String get tip4;

  /// No description provided for @tip4Desc.
  ///
  /// In fr, this message translates to:
  /// **'Identifiez les carrés presque complétés pour prendre l\'avantage.'**
  String get tip4Desc;

  /// No description provided for @faq.
  ///
  /// In fr, this message translates to:
  /// **'Questions fréquentes'**
  String get faq;

  /// No description provided for @faq1.
  ///
  /// In fr, this message translates to:
  /// **'Que se passe-t-il en cas d\'égalité ?'**
  String get faq1;

  /// No description provided for @faq1Desc.
  ///
  /// In fr, this message translates to:
  /// **'En cas d\'égalité, le joueur qui a complété le dernier carré gagne.'**
  String get faq1Desc;

  /// No description provided for @faq2.
  ///
  /// In fr, this message translates to:
  /// **'Puis-je annuler un coup ?'**
  String get faq2;

  /// No description provided for @faq2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Non, les coups sont définitifs. Réfléchissez bien avant de jouer !'**
  String get faq2Desc;

  /// No description provided for @faq3.
  ///
  /// In fr, this message translates to:
  /// **'Que faire si je perds la connexion ?'**
  String get faq3;

  /// No description provided for @faq3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez quelques secondes pour vous reconnecter. Sinon, la partie est perdue.'**
  String get faq3Desc;

  /// No description provided for @faq4.
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionne le classement ?'**
  String get faq4;

  /// No description provided for @faq4Desc.
  ///
  /// In fr, this message translates to:
  /// **'Vos victoires et défaites influencent votre classement. Plus vous gagnez, plus vous montez !'**
  String get faq4Desc;

  /// No description provided for @personalizeExperience.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisez votre expérience'**
  String get personalizeExperience;

  /// No description provided for @configuration.
  ///
  /// In fr, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @guide.
  ///
  /// In fr, this message translates to:
  /// **'Guide du jeu'**
  String get guide;

  /// No description provided for @underDevelopment.
  ///
  /// In fr, this message translates to:
  /// **'En développement'**
  String get underDevelopment;

  /// No description provided for @editProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfileTitle;

  /// No description provided for @profilePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get profilePhoto;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @nameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: MarcAurel, Pega225, Fred2x'**
  String get nameHint;

  /// No description provided for @nameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get nameRequired;

  /// No description provided for @nameValidation.
  ///
  /// In fr, this message translates to:
  /// **'Max 9 caractères, lettres et chiffres uniquement'**
  String get nameValidation;

  /// No description provided for @nameValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir entre 1 et 9 caractères (lettres et chiffres uniquement)'**
  String get nameValidationError;

  /// No description provided for @imageSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sélection de l\'image: {error}'**
  String imageSelectionError(String error);

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès'**
  String get profileUpdatedSuccess;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get save;

  /// No description provided for @deleteMyData.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mes données'**
  String get deleteMyData;

  /// No description provided for @deleteMyDataMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous allez poursuivre sur un navigateur externe'**
  String get deleteMyDataMessage;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @cannotOpenUrl.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'URL'**
  String get cannotOpenUrl;

  /// Avertissement concernant l'absence de fichier de désobscurcissement pour la version 1
  ///
  /// In fr, this message translates to:
  /// **'Aucun fichier de désobscurcissement n\'est associé à cet App Bundle. Si vous utilisez du code obscurci (R8/ProGuard), le fait d\'importer un fichier de désobscurcissement simplifiera l\'analyse et le débogage des plantages et des ANR. Vous pouvez réduire la taille de l\'appli avec R8/ProGuard.'**
  String get noMappingFileWarning;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
