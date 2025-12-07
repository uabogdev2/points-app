import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  // Utiliser un getter lazy pour éviter les erreurs si Firebase n'est pas encore initialisé
  firebase_auth.FirebaseAuth get _auth {
    try {
      return firebase_auth.FirebaseAuth.instance;
    } catch (e) {
      debugPrint('❌ Erreur accès FirebaseAuth: $e');
      // Réessayer d'initialiser Firebase si nécessaire
      throw Exception('Firebase n\'est pas initialisé. Veuillez redémarrer l\'application.');
    }
  }
  
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Connexion Google
  Future<User> signInWithGoogle() async {
    try {
      debugPrint('🔵 Étape 1: Début de la connexion Google...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('🔵 Étape 1.5: Résultat signIn: ${googleUser?.email ?? "null"}');
      if (googleUser == null) {
        debugPrint('❌ Connexion Google annulée par l\'utilisateur');
        throw Exception('Connexion Google annulée');
      }
      debugPrint('✅ Étape 1: Compte Google sélectionné: ${googleUser.email}');

      debugPrint('🔵 Étape 2: Authentification Google...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint('✅ Étape 2: Authentification Google réussie');

      debugPrint('🔵 Étape 3: Création du credential Firebase...');
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔵 Étape 4: Connexion à Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        debugPrint('❌ Échec: firebaseUser est null');
        throw Exception('Échec de la connexion Firebase');
      }
      debugPrint('✅ Étape 4: Connexion Firebase réussie: ${firebaseUser.uid}');

      debugPrint('🔵 Étape 5: Obtention du token Firebase ID...');
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        debugPrint('❌ Échec: idToken est null');
        throw Exception('Impossible d\'obtenir le token Firebase');
      }
      debugPrint('✅ Étape 5: Token Firebase obtenu (${idToken.length} caractères)');

      debugPrint('🔵 Étape 6: Connexion à l\'API backend...');
      final response = await ApiService.login(idToken);
      debugPrint('✅ Étape 6: Connexion API réussie');
      
      return User.fromJson(response['user'] as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur complète de connexion Google: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Erreur de connexion Google: $e');
    }
  }

  // Connexion Apple
  Future<User> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase_auth.OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Échec de la connexion Firebase');
      }

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw Exception('Impossible d\'obtenir le token Firebase');
      }
      final response = await ApiService.login(idToken);
      return User.fromJson(response['user'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur de connexion Apple: $e');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      debugPrint('🔴 Début de la déconnexion...');
      
      // Déconnexion Google
      await _googleSignIn.signOut();
      debugPrint('✅ Déconnexion Google réussie');
      
      // Déconnexion Firebase
      await _auth.signOut();
      debugPrint('✅ Déconnexion Firebase réussie');
      
      debugPrint('✅ Déconnexion complète réussie');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
      debugPrint('Stack trace: $stackTrace');
      // Ne pas throw pour permettre la déconnexion même en cas d'erreur
    }
  }

  // Vérifier si l'utilisateur est connecté
  bool get isSignedIn => _auth.currentUser != null;

  // Obtenir l'utilisateur Firebase actuel
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;
}

