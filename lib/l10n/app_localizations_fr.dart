// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Points Master';

  @override
  String get appSubtitle => 'Le jeu de stratégie ultime';

  @override
  String get welcome => 'Bienvenue,';

  @override
  String get player => 'Joueur';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get connectToSave =>
      '📝 Connectez-vous pour sauvegarder\nvos scores et défier vos amis !';

  @override
  String acceptTerms(String terms, String privacy) {
    return 'En continuant, vous acceptez nos $terms et notre $privacy';
  }

  @override
  String get terms => 'conditions';

  @override
  String get privacy => 'politique de confidentialité';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get back => 'Retour';

  @override
  String get home => 'Accueil';

  @override
  String get stats => 'Stats';

  @override
  String get leaderboard => 'Classement';

  @override
  String get settings => 'Paramètres';

  @override
  String get help => 'Aide';

  @override
  String get quitApp => 'Quitter l\'application ?';

  @override
  String get quitAppConfirm =>
      'Êtes-vous sûr de vouloir quitter Points Master ?';

  @override
  String get quit => 'Quitter';

  @override
  String get gameModes => 'Modes de jeu';

  @override
  String get chooseAdventure => 'Choisissez votre aventure';

  @override
  String get solo => 'Solo';

  @override
  String get soloSubtitle => 'Défiez l\'intelligence artificielle';

  @override
  String get duo => 'Duo';

  @override
  String get duoSubtitle => '2 joueurs sur le même écran';

  @override
  String get quickMatch => 'Partie Rapide';

  @override
  String get quickMatchSubtitle => 'Trouvez un adversaire en ligne';

  @override
  String get privateGame => 'Partie Privée';

  @override
  String get privateGameSubtitle => 'Créez une salle avec code QR';

  @override
  String get others => 'Autres';

  @override
  String get helpAndSettings => 'Aide et paramètres';

  @override
  String get victories => 'Victoires';

  @override
  String get streak => 'Série';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get editProfileSubtitle => 'Changez votre nom et votre avatar';

  @override
  String get editProfileLimited => 'Modification limitée à 1 fois par semaine';

  @override
  String get profileUpdateLimit =>
      'Vous pouvez modifier votre profil une fois par semaine. Veuillez réessayer plus tard.';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get pushNotificationsSubtitle => 'Recevoir des notifications';

  @override
  String get audio => 'Audio';

  @override
  String get backgroundMusic => 'Musique de fond';

  @override
  String get backgroundMusicSubtitle => 'Activer la musique de fond';

  @override
  String get volume => 'Volume';

  @override
  String get gameSounds => 'Sons de jeu';

  @override
  String get gameSoundsSubtitle => 'Activer les sons (clic, succès)';

  @override
  String get language => 'Langue';

  @override
  String get languageSubtitle => 'Choisir la langue de l\'application';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get systemDefault => 'Par défaut (système)';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutConfirm => 'Déconnexion';

  @override
  String get signOutMessage => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String signOutError(String error) {
    return 'Erreur lors de la déconnexion: $error';
  }

  @override
  String get loading => 'Chargement...';

  @override
  String get loadingGame => 'Chargement de la partie...';

  @override
  String get loadingStats => 'Chargement des stats...';

  @override
  String get loadingLeaderboard => 'Chargement du classement...';

  @override
  String get connectionInProgress => 'Connexion en cours...';

  @override
  String get gameNotFound => 'Partie introuvable';

  @override
  String get forfeit => 'Abandonner ?';

  @override
  String get forfeitMessage => 'Votre adversaire gagnera automatiquement.';

  @override
  String get forfeitAction => 'Abandonner';

  @override
  String get waiting => 'En attente...';

  @override
  String get waitingOpponent => 'Un adversaire va bientôt rejoindre';

  @override
  String get onlineGame => 'Partie en ligne';

  @override
  String gameNumber(int gameId) {
    return 'Partie #$gameId';
  }

  @override
  String get yourTurn => 'À vous de jouer !';

  @override
  String get opponentTurn => 'Tour de l\'adversaire';

  @override
  String get player1 => 'Joueur 1';

  @override
  String get player2 => 'Joueur 2';

  @override
  String get you => 'vous';

  @override
  String get vs => 'VS';

  @override
  String get squares => 'carrés';

  @override
  String get victory => 'Victoire !';

  @override
  String get defeat => 'Défaite';

  @override
  String get draw => 'Match nul !';

  @override
  String get winner => 'Vainqueur';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get updateRequired => 'Mise à jour requise';

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String currentVersion(String version) {
    return 'Version actuelle: $version';
  }

  @override
  String latestVersion(String version) {
    return 'Dernière version: $version';
  }

  @override
  String get updateLater => 'Plus tard';

  @override
  String get update => 'Mettre à jour';

  @override
  String get updateRequiredMessage =>
      'La mise à jour est requise pour continuer.';

  @override
  String get updateError =>
      'Impossible d\'ouvrir le lien. Veuillez mettre à jour manuellement depuis le store.';

  @override
  String get updateUrlError =>
      'URL de mise à jour non disponible. Veuillez mettre à jour depuis le store.';

  @override
  String get gridSize => 'Taille de la grille';

  @override
  String get gridSize3x3 => '3x3';

  @override
  String get gridSize5x5 => '5x5';

  @override
  String get gridSize8x8 => '8x8';

  @override
  String get gridSize12x12 => '12x12';

  @override
  String get difficulty => 'Difficulté';

  @override
  String get chooseDifficulty => 'Choisissez votre niveau de défi';

  @override
  String get beginner => 'Débutant';

  @override
  String get beginnerSubtitle => 'Parfait pour apprendre les règles';

  @override
  String get normal => 'Normal';

  @override
  String get normalSubtitle => 'Un défi équilibré';

  @override
  String get expert => 'Expert';

  @override
  String get expertSubtitle => 'Pour les vrais stratèges';

  @override
  String get gridSizeSubtitle =>
      'Plus la grille est grande, plus c\'est stratégique';

  @override
  String get quickGame => 'Partie rapide • ~2 min';

  @override
  String get classicGame => 'Classique • ~5 min';

  @override
  String get strategicGame => 'Stratégique • ~10 min';

  @override
  String get expertGame => 'Expert • ~20 min';

  @override
  String get createGame => 'Créer une partie';

  @override
  String get createGameSubtitle => 'Générer un code et un QR code';

  @override
  String get joinGame => 'Rejoindre une partie';

  @override
  String get joinGameSubtitle => 'Scanner un QR code ou entrer un code';

  @override
  String get duoInfo =>
      'Jouez à deux sur le même écran !\nPassez le téléphone à votre adversaire.';

  @override
  String get privateGameInfo =>
      'Créez une partie privée et partagez\nle code QR avec votre ami !';

  @override
  String get options => 'Options';

  @override
  String get createOrJoin => 'Créer ou rejoindre une partie';

  @override
  String get statistics => 'Statistiques';

  @override
  String get yourPerformance => 'Vos performances';

  @override
  String get noStatistics => 'Aucune statistique';

  @override
  String get playToUnlock => 'Jouez pour débloquer vos stats !';

  @override
  String get overview => 'Vue d\'ensemble';

  @override
  String get games => 'Parties';

  @override
  String get winRate => 'Taux de victoire';

  @override
  String get rate => 'Taux';

  @override
  String get matchmaking => 'Partie Rapide';

  @override
  String get forRanking => 'Pour le classement';

  @override
  String get playMatchmaking =>
      'Jouez en mode \"Partie Rapide\" pour apparaître dans le classement';

  @override
  String get defeats => 'Défaites';

  @override
  String get bestScore => 'Meilleur score';

  @override
  String get squaresCompleted => 'Carrés complétés';

  @override
  String get currentStreak => 'Série actuelle';

  @override
  String get longestStreak => 'Meilleure série';

  @override
  String get details => 'Détails';

  @override
  String get topPlayers => 'Top Joueurs';

  @override
  String get bestOfTheMoment => 'Les meilleurs du moment';

  @override
  String get joinRanking =>
      'Rejoignez le classement et devenez le Points Master !';

  @override
  String get noLeaderboard => 'Aucun classement disponible';

  @override
  String get playToAppear =>
      'Jouez en mode \"Partie Rapide\" pour apparaître dans le classement !';

  @override
  String get pointsMaster => 'POINTS MASTER';

  @override
  String get howToPlay => 'Comment jouer';

  @override
  String get gameGuide => 'Guide du jeu Points Master';

  @override
  String get gameRules => 'Règles du jeu';

  @override
  String get rule1 => '1. Connectez deux points';

  @override
  String get rule1Desc =>
      'Cliquez sur un point, puis sur un autre point adjacent pour créer un segment.';

  @override
  String get rule2 => '2. Complétez des carrés';

  @override
  String get rule2Desc =>
      'Lorsque vous complétez les 4 côtés d\'un carré, vous marquez un point.';

  @override
  String get rule3 => '3. Gagnez des points';

  @override
  String get rule3Desc =>
      'Le joueur avec le plus de points à la fin de la partie gagne.';

  @override
  String get rule4 => '4. Stratégie';

  @override
  String get rule4Desc =>
      'Essayez de compléter plusieurs carrés en un seul coup pour maximiser vos points.';

  @override
  String get gameModesSection => 'Modes de jeu';

  @override
  String get soloMode => 'Solo';

  @override
  String get soloModeDesc =>
      'Jouez contre l\'intelligence artificielle. Parfait pour s\'entraîner.';

  @override
  String get duoMode => 'Duo';

  @override
  String get duoModeDesc =>
      'Jouez à deux sur le même écran. Idéal pour jouer avec un ami.';

  @override
  String get quickMatchMode => 'Partie Rapide';

  @override
  String get quickMatchModeDesc =>
      'Trouvez un adversaire en ligne et jouez en temps réel.';

  @override
  String get privateGameMode => 'Partie Privée';

  @override
  String get privateGameModeDesc =>
      'Créez une salle avec un code QR et invitez vos amis.';

  @override
  String get tipsAndTricks => 'Conseils et astuces';

  @override
  String get tip1 => 'Bloquez votre adversaire';

  @override
  String get tip1Desc =>
      'Empêchez votre adversaire de compléter des carrés en bloquant ses mouvements.';

  @override
  String get tip2 => 'Planifiez vos coups';

  @override
  String get tip2Desc =>
      'Regardez plusieurs coups à l\'avance pour maximiser vos opportunités.';

  @override
  String get tip3 => 'Gérez votre temps';

  @override
  String get tip3Desc =>
      'Vous avez un temps limité par tour. Utilisez-le à bon escient.';

  @override
  String get tip4 => 'Observez le plateau';

  @override
  String get tip4Desc =>
      'Identifiez les carrés presque complétés pour prendre l\'avantage.';

  @override
  String get faq => 'Questions fréquentes';

  @override
  String get faq1 => 'Que se passe-t-il en cas d\'égalité ?';

  @override
  String get faq1Desc =>
      'En cas d\'égalité, le joueur qui a complété le dernier carré gagne.';

  @override
  String get faq2 => 'Puis-je annuler un coup ?';

  @override
  String get faq2Desc =>
      'Non, les coups sont définitifs. Réfléchissez bien avant de jouer !';

  @override
  String get faq3 => 'Que faire si je perds la connexion ?';

  @override
  String get faq3Desc =>
      'Vous avez quelques secondes pour vous reconnecter. Sinon, la partie est perdue.';

  @override
  String get faq4 => 'Comment fonctionne le classement ?';

  @override
  String get faq4Desc =>
      'Vos victoires et défaites influencent votre classement. Plus vous gagnez, plus vous montez !';

  @override
  String get personalizeExperience => 'Personnalisez votre expérience';

  @override
  String get configuration => 'Configuration';

  @override
  String get guide => 'Guide du jeu';

  @override
  String get underDevelopment => 'En développement';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get profilePhoto => 'Photo de profil';

  @override
  String get name => 'Nom';

  @override
  String get nameHint => 'Ex: MarcAurel, Pega225, Fred2x';

  @override
  String get nameRequired => 'Le nom est requis';

  @override
  String get nameValidation =>
      'Max 9 caractères, lettres et chiffres uniquement';

  @override
  String get nameValidationError =>
      'Le nom doit contenir entre 1 et 9 caractères (lettres et chiffres uniquement)';

  @override
  String imageSelectionError(String error) {
    return 'Erreur lors de la sélection de l\'image: $error';
  }

  @override
  String get profileUpdatedSuccess => 'Profil mis à jour avec succès';

  @override
  String get save => 'Sauvegarder';

  @override
  String get deleteMyData => 'Gérer mon compte';

  @override
  String get deleteMyDataMessage =>
      'Vous allez poursuivre sur un navigateur externe';

  @override
  String get yes => 'Oui';

  @override
  String get close => 'Fermer';

  @override
  String get cannotOpenUrl => 'Impossible d\'ouvrir l\'URL';

  @override
  String get noMappingFileWarning =>
      'Aucun fichier de désobscurcissement n\'est associé à cet App Bundle. Si vous utilisez du code obscurci (R8/ProGuard), le fait d\'importer un fichier de désobscurcissement simplifiera l\'analyse et le débogage des plantages et des ANR. Vous pouvez réduire la taille de l\'appli avec R8/ProGuard.';
}
