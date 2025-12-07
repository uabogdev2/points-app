import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  // Forcer l'arrêt du chargement (pour éviter les blocages)
  void forceStopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  // Initialiser depuis le stockage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialiser les notifications en arrière-plan (non bloquant)
      // Ne pas attendre pour éviter de bloquer le démarrage
      _notificationService.initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⚠️ Timeout initialisation notifications (non bloquant)');
        },
      ).catchError((e) {
        debugPrint('⚠️ Erreur initialisation notifications (non bloquant): $e');
      });
      
      // Vérifier le token en premier (rapide)
      final token = await StorageService.getToken()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ Timeout récupération token');
              return null;
            },
          );
      
      if (token != null) {
        // Vérifier si le token est valide en récupérant le profil avec timeout très court
        try {
          _user = await ApiService.getMe()
              .timeout(
                const Duration(seconds: 3),
                onTimeout: () {
                  debugPrint('⚠️ Timeout récupération profil - garder le token (erreur réseau probable)');
                  throw TimeoutException('Timeout récupération profil');
                },
              );
          debugPrint('✅ Profil récupéré avec succès - utilisateur connecté');
        } on TimeoutException {
          // Timeout = probablement erreur réseau, ne pas supprimer le token
          debugPrint('⚠️ Timeout récupération profil - erreur réseau probable, token conservé');
          _user = null;
          // Ne pas supprimer le token en cas de timeout (erreur réseau)
        } catch (e) {
          // Vérifier si c'est une erreur 401 (token invalide) ou autre
          final statusCode = (e as dynamic).statusCode;
          final errorString = e.toString();
          
          if (statusCode == 401 || errorString.contains('401') || errorString.contains('Unauthorized')) {
            // Token vraiment invalide, supprimer le stockage
            debugPrint('❌ Token invalide (401) - suppression du stockage');
            try {
              await StorageService.clearAll().timeout(
                const Duration(seconds: 1),
                onTimeout: () {
                  debugPrint('⚠️ Timeout clearAll');
                },
              );
            } catch (e2) {
              debugPrint('❌ Erreur clearAll: $e2');
            }
          } else {
            // Autre erreur (réseau, serveur, etc.) - ne pas supprimer le token
            debugPrint('⚠️ Erreur récupération profil (non-401, status: $statusCode): $e - token conservé');
          }
          _user = null;
        }
        
        // Mettre à jour le token FCM après la connexion (non bloquant, en arrière-plan)
        _updateFCMTokenIfNeeded().catchError((e) {
          debugPrint('⚠️ Erreur FCM (non bloquant): $e');
        });
      } else {
        _user = null;
      }
    } catch (e) {
      // Erreur lors de la récupération du token depuis le stockage
      debugPrint('❌ Erreur initialisation AuthProvider (récupération token): $e');
      // Ne pas supprimer le stockage si c'est juste une erreur de lecture
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateFCMTokenIfNeeded() async {
    try {
      developer.log('🔄 Vérification du token FCM...', name: 'AuthProvider');
      final fcmToken = await _notificationService.getToken();
      if (fcmToken != null) {
        developer.log('📱 Token FCM obtenu: ${fcmToken.substring(0, 20)}...', name: 'AuthProvider');
        await ApiService.updateFCMToken(fcmToken);
        developer.log('✅ Token FCM mis à jour avec succès', name: 'AuthProvider');
      } else {
        developer.log('⚠️ Aucun token FCM disponible', name: 'AuthProvider');
      }
    } catch (e, stackTrace) {
      developer.log('❌ Erreur lors de la mise à jour du token FCM: $e', name: 'AuthProvider');
      developer.log('❌ Stack trace: $stackTrace', name: 'AuthProvider');
      // Erreur silencieuse, on continue
    }
  }
  
  /// Force la mise à jour du token FCM (utile pour les tests)
  Future<void> refreshFCMToken() async {
    await _updateFCMTokenIfNeeded();
  }

  // Connexion Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      developer.log('🔐 Début de la connexion Google...', name: 'AuthProvider');
      _user = await _authService.signInWithGoogle();
      developer.log('✅ Connexion Google réussie - User: ${_user?.name ?? "null"}', name: 'AuthProvider');
      
      // Mettre à jour le token FCM après la connexion (ne pas bloquer si ça échoue)
      try {
        await _updateFCMTokenIfNeeded();
      } catch (e) {
        developer.log('⚠️ Erreur FCM (non bloquante): $e', name: 'AuthProvider');
      }
      
      _isLoading = false;
      notifyListeners();
      developer.log('✅ AuthProvider: isAuthenticated = ${isAuthenticated}', name: 'AuthProvider');
      return true;
    } catch (e, stackTrace) {
      developer.log('❌ Erreur lors de la connexion Google: $e', name: 'AuthProvider');
      developer.log('❌ Stack trace: $stackTrace', name: 'AuthProvider');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Connexion Apple
  Future<bool> signInWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithApple();
      
      // Mettre à jour le token FCM après la connexion
      await _updateFCMTokenIfNeeded();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      developer.log('🔴 Début de la déconnexion...', name: 'AuthProvider');
      
      // Supprimer le token FCM avant la déconnexion (ne pas bloquer si ça échoue)
      try {
        await _notificationService.deleteToken();
        developer.log('✅ Token FCM supprimé', name: 'AuthProvider');
      } catch (e) {
        developer.log('⚠️ Erreur lors de la suppression du token FCM (non bloquante): $e', name: 'AuthProvider');
      }
      
      // Déconnexion Firebase et Google
      await _authService.signOut();
      developer.log('✅ Services de déconnexion appelés', name: 'AuthProvider');
      
      // Nettoyer le stockage local
      await StorageService.clearAll();
      developer.log('✅ Stockage local nettoyé', name: 'AuthProvider');
      
      // Réinitialiser l'utilisateur
      _user = null;
      developer.log('✅ Utilisateur réinitialisé', name: 'AuthProvider');
      
    } catch (e, stackTrace) {
      developer.log('❌ Erreur lors de la déconnexion: $e', name: 'AuthProvider');
      developer.log('❌ Stack trace: $stackTrace', name: 'AuthProvider');
      _error = e.toString();
      // Même en cas d'erreur, on nettoie l'état local
      _user = null;
      await StorageService.clearAll();
    } finally {
      _isLoading = false;
      notifyListeners();
      developer.log('✅ Déconnexion terminée - isAuthenticated: ${isAuthenticated}', name: 'AuthProvider');
    }
  }

  // Mettre à jour l'utilisateur
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}

