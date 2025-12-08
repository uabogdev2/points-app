// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Points Master';

  @override
  String get appSubtitle => 'The ultimate strategy game';

  @override
  String get welcome => 'Welcome,';

  @override
  String get player => 'Player';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get connectToSave =>
      '📝 Sign in to save\nyour scores and challenge your friends!';

  @override
  String acceptTerms(String terms, String privacy) {
    return 'By continuing, you agree to our $terms and our $privacy';
  }

  @override
  String get terms => 'terms';

  @override
  String get privacy => 'privacy policy';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get home => 'Home';

  @override
  String get stats => 'Stats';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get quitApp => 'Quit the application?';

  @override
  String get quitAppConfirm => 'Are you sure you want to quit Points Master?';

  @override
  String get quit => 'Quit';

  @override
  String get gameModes => 'Game Modes';

  @override
  String get chooseAdventure => 'Choose your adventure';

  @override
  String get solo => 'Solo';

  @override
  String get soloSubtitle => 'Challenge artificial intelligence';

  @override
  String get duo => 'Duo';

  @override
  String get duoSubtitle => '2 players on the same screen';

  @override
  String get quickMatch => 'Quick Match';

  @override
  String get quickMatchSubtitle => 'Find an opponent online';

  @override
  String get privateGame => 'Private Game';

  @override
  String get privateGameSubtitle => 'Create a room with QR code';

  @override
  String get others => 'Others';

  @override
  String get helpAndSettings => 'Help and settings';

  @override
  String get victories => 'Victories';

  @override
  String get streak => 'Streak';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editProfileSubtitle => 'Change your name and avatar';

  @override
  String get editProfileLimited => 'Limited to once per week';

  @override
  String get profileUpdateLimit =>
      'You can edit your profile once per week. Please try again later.';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsSubtitle => 'Receive notifications';

  @override
  String get audio => 'Audio';

  @override
  String get backgroundMusic => 'Background music';

  @override
  String get backgroundMusicSubtitle => 'Enable background music';

  @override
  String get volume => 'Volume';

  @override
  String get gameSounds => 'Game sounds';

  @override
  String get gameSoundsSubtitle => 'Enable sounds (click, success)';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose the application language';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get systemDefault => 'Default (system)';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out';

  @override
  String get signOutMessage => 'Are you sure you want to sign out?';

  @override
  String signOutError(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get loadingGame => 'Loading game...';

  @override
  String get loadingStats => 'Loading stats...';

  @override
  String get loadingLeaderboard => 'Loading leaderboard...';

  @override
  String get connectionInProgress => 'Connecting...';

  @override
  String get gameNotFound => 'Game not found';

  @override
  String get forfeit => 'Forfeit?';

  @override
  String get forfeitMessage => 'Your opponent will automatically win.';

  @override
  String get forfeitAction => 'Forfeit';

  @override
  String get waiting => 'Waiting...';

  @override
  String get waitingOpponent => 'An opponent will join soon';

  @override
  String get onlineGame => 'Online game';

  @override
  String gameNumber(int gameId) {
    return 'Game #$gameId';
  }

  @override
  String get yourTurn => 'Your turn!';

  @override
  String get opponentTurn => 'Opponent\'s turn';

  @override
  String get player1 => 'Player 1';

  @override
  String get player2 => 'Player 2';

  @override
  String get you => 'you';

  @override
  String get vs => 'VS';

  @override
  String get squares => 'squares';

  @override
  String get victory => 'Victory!';

  @override
  String get defeat => 'Defeat';

  @override
  String get draw => 'Draw!';

  @override
  String get winner => 'Winner';

  @override
  String get backToHome => 'Back to home';

  @override
  String get updateRequired => 'Update required';

  @override
  String get updateAvailable => 'Update available';

  @override
  String currentVersion(String version) {
    return 'Current version: $version';
  }

  @override
  String latestVersion(String version) {
    return 'Latest version: $version';
  }

  @override
  String get updateLater => 'Later';

  @override
  String get update => 'Update';

  @override
  String get updateRequiredMessage => 'The update is required to continue.';

  @override
  String get updateError =>
      'Unable to open the link. Please update manually from the store.';

  @override
  String get updateUrlError =>
      'Update URL not available. Please update from the store.';

  @override
  String get gridSize => 'Grid size';

  @override
  String get gridSize3x3 => '3x3';

  @override
  String get gridSize5x5 => '5x5';

  @override
  String get gridSize8x8 => '8x8';

  @override
  String get gridSize12x12 => '12x12';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get chooseDifficulty => 'Choose your challenge level';

  @override
  String get beginner => 'Beginner';

  @override
  String get beginnerSubtitle => 'Perfect for learning the rules';

  @override
  String get normal => 'Normal';

  @override
  String get normalSubtitle => 'A balanced challenge';

  @override
  String get expert => 'Expert';

  @override
  String get expertSubtitle => 'For true strategists';

  @override
  String get gridSizeSubtitle => 'The larger the grid, the more strategic';

  @override
  String get quickGame => 'Quick game • ~2 min';

  @override
  String get classicGame => 'Classic • ~5 min';

  @override
  String get strategicGame => 'Strategic • ~10 min';

  @override
  String get expertGame => 'Expert • ~20 min';

  @override
  String get createGame => 'Create a game';

  @override
  String get createGameSubtitle => 'Generate a code and QR code';

  @override
  String get joinGame => 'Join a game';

  @override
  String get joinGameSubtitle => 'Scan a QR code or enter a code';

  @override
  String get duoInfo =>
      'Play together on the same screen!\nPass the phone to your opponent.';

  @override
  String get privateGameInfo =>
      'Create a private game and share\nthe QR code with your friend!';

  @override
  String get options => 'Options';

  @override
  String get createOrJoin => 'Create or join a game';

  @override
  String get statistics => 'Statistics';

  @override
  String get yourPerformance => 'Your performance';

  @override
  String get noStatistics => 'No statistics';

  @override
  String get playToUnlock => 'Play to unlock your stats!';

  @override
  String get overview => 'Overview';

  @override
  String get games => 'Games';

  @override
  String get winRate => 'Win rate';

  @override
  String get rate => 'Rate';

  @override
  String get matchmaking => 'Quick Match';

  @override
  String get forRanking => 'For ranking';

  @override
  String get playMatchmaking =>
      'Play in \"Quick Match\" mode to appear in the leaderboard';

  @override
  String get defeats => 'Defeats';

  @override
  String get bestScore => 'Best score';

  @override
  String get squaresCompleted => 'Squares completed';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get longestStreak => 'Longest streak';

  @override
  String get details => 'Details';

  @override
  String get topPlayers => 'Top Players';

  @override
  String get bestOfTheMoment => 'The best of the moment';

  @override
  String get joinRanking =>
      'Join the leaderboard and become the Points Master!';

  @override
  String get noLeaderboard => 'No leaderboard available';

  @override
  String get playToAppear =>
      'Play in \"Quick Match\" mode to appear in the leaderboard!';

  @override
  String get pointsMaster => 'POINTS MASTER';

  @override
  String get howToPlay => 'How to play';

  @override
  String get gameGuide => 'Points Master game guide';

  @override
  String get gameRules => 'Game rules';

  @override
  String get rule1 => '1. Connect two points';

  @override
  String get rule1Desc =>
      'Click on a point, then on another adjacent point to create a segment.';

  @override
  String get rule2 => '2. Complete squares';

  @override
  String get rule2Desc =>
      'When you complete the 4 sides of a square, you score a point.';

  @override
  String get rule3 => '3. Score points';

  @override
  String get rule3Desc =>
      'The player with the most points at the end of the game wins.';

  @override
  String get rule4 => '4. Strategy';

  @override
  String get rule4Desc =>
      'Try to complete multiple squares in a single move to maximize your points.';

  @override
  String get gameModesSection => 'Game modes';

  @override
  String get soloMode => 'Solo';

  @override
  String get soloModeDesc =>
      'Play against artificial intelligence. Perfect for training.';

  @override
  String get duoMode => 'Duo';

  @override
  String get duoModeDesc =>
      'Play together on the same screen. Ideal for playing with a friend.';

  @override
  String get quickMatchMode => 'Quick Match';

  @override
  String get quickMatchModeDesc =>
      'Find an opponent online and play in real time.';

  @override
  String get privateGameMode => 'Private Game';

  @override
  String get privateGameModeDesc =>
      'Create a room with a QR code and invite your friends.';

  @override
  String get tipsAndTricks => 'Tips and tricks';

  @override
  String get tip1 => 'Block your opponent';

  @override
  String get tip1Desc =>
      'Prevent your opponent from completing squares by blocking their moves.';

  @override
  String get tip2 => 'Plan your moves';

  @override
  String get tip2Desc =>
      'Look several moves ahead to maximize your opportunities.';

  @override
  String get tip3 => 'Manage your time';

  @override
  String get tip3Desc => 'You have limited time per turn. Use it wisely.';

  @override
  String get tip4 => 'Observe the board';

  @override
  String get tip4Desc =>
      'Identify nearly completed squares to gain an advantage.';

  @override
  String get faq => 'Frequently asked questions';

  @override
  String get faq1 => 'What happens in case of a tie?';

  @override
  String get faq1Desc =>
      'In case of a tie, the player who completed the last square wins.';

  @override
  String get faq2 => 'Can I undo a move?';

  @override
  String get faq2Desc => 'No, moves are final. Think carefully before playing!';

  @override
  String get faq3 => 'What if I lose connection?';

  @override
  String get faq3Desc =>
      'You have a few seconds to reconnect. Otherwise, the game is lost.';

  @override
  String get faq4 => 'How does ranking work?';

  @override
  String get faq4Desc =>
      'Your wins and losses affect your ranking. The more you win, the higher you climb!';

  @override
  String get personalizeExperience => 'Personalize your experience';

  @override
  String get configuration => 'Configuration';

  @override
  String get guide => 'Game guide';

  @override
  String get underDevelopment => 'Under development';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get name => 'Name';

  @override
  String get nameHint => 'Ex: MarcAurel, Pega225, Fred2x';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameValidation => 'Max 9 characters, letters and numbers only';

  @override
  String get nameValidationError =>
      'Name must contain between 1 and 9 characters (letters and numbers only)';

  @override
  String imageSelectionError(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get save => 'Save';

  @override
  String get deleteMyData => 'Manage my account';

  @override
  String get deleteMyDataMessage => 'You will continue on an external browser';

  @override
  String get yes => 'Yes';

  @override
  String get close => 'Close';

  @override
  String get cannotOpenUrl => 'Cannot open URL';

  @override
  String get noMappingFileWarning =>
      'No deobfuscation file is associated with this App Bundle. If you use obfuscated code (R8/ProGuard), importing a deobfuscation file will simplify crash and ANR analysis and debugging. You can reduce app size with R8/ProGuard.';
}
