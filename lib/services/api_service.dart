import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import '../models/user.dart';
import '../models/game.dart';
import '../models/invitation.dart';
import '../models/version_check.dart';
import '../models/leaderboard_entry.dart';
import 'storage_service.dart';
import 'device_service.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth
  static Future<Map<String, dynamic>> login(String firebaseToken) async {
    try {
      final url = '${ApiConfig.baseUrl}/auth/login';
      debugPrint('🔐 Tentative de connexion: $url');
      
      // Récupérer les informations de l'appareil
      final deviceInfo = await DeviceService.getDeviceInfo();
      debugPrint('📱 Informations appareil: $deviceInfo');
      
      final requestBody = {
        'token': firebaseToken,
        'device_type': deviceInfo['device_type'],
        'device_id': deviceInfo['device_id'],
        'app_version': deviceInfo['app_version'],
        'country': deviceInfo['country'],
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('📡 Réponse login: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        final token = data['token'] as String;
        final isNewUser = data['is_new_user'] as bool? ?? false;
        
        // Sauvegarder le token
        await StorageService.saveToken(token);
        await StorageService.saveFirebaseUid(user.firebaseUid);
        await StorageService.saveUserId(user.id);
        
        // Si c'est un nouvel utilisateur (détecté par la base de données), sauvegarder cette information
        if (isNewUser) {
          await StorageService.setIsNewUser(true);
          await StorageService.setHasCompletedFirstLogin(false);
          debugPrint('🆕 Nouvel utilisateur détecté par la base de données');
        } else {
          // Si ce n'est pas un nouvel utilisateur, s'assurer que le flag est à false
          await StorageService.setIsNewUser(false);
        }
        
        debugPrint('✅ Connexion réussie pour: ${user.name} (nouvel utilisateur: $isNewUser)');
        return data;
      } else {
        String errorMessage = 'Erreur de connexion';
        
        // Essayer d'extraire un message d'erreur du HTML ou JSON
        try {
          if (response.body.contains('<!DOCTYPE html>')) {
            // C'est une page d'erreur HTML (Laravel error page)
            if (response.body.contains('Data too long for column')) {
              errorMessage = 'Erreur serveur: La base de données n\'est pas correctement configurée. Contactez l\'administrateur.';
            } else if (response.body.contains('SQLSTATE')) {
              errorMessage = 'Erreur serveur: Problème de base de données. Contactez l\'administrateur.';
            } else {
              errorMessage = 'Erreur serveur (${response.statusCode}). Vérifiez la configuration du backend.';
            }
          } else {
            // Essayer de parser comme JSON
            final errorData = jsonDecode(response.body) as Map<String, dynamic>;
            errorMessage = errorData['error'] as String? ?? errorData['message'] as String? ?? errorMessage;
          }
        } catch (e) {
          // Si on ne peut pas parser, utiliser le message par défaut
          errorMessage = 'Erreur de connexion (${response.statusCode})';
        }
        
        debugPrint('❌ Erreur login: ${response.statusCode} - $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Exception lors de la connexion: $e');
      rethrow;
    }
  }

  static Future<User> getMe() async {
    try {
      final url = '${ApiConfig.baseUrl}/auth/me';
      debugPrint('👤 Récupération du profil: $url');
      
      final headers = await _getHeaders();
      debugPrint('🔑 Headers: ${headers.keys}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📡 Réponse getMe: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        // Créer une exception avec le code de statut pour pouvoir le vérifier
        final exception = Exception('Échec de récupération du profil: ${response.statusCode} - ${response.body}');
        (exception as dynamic).statusCode = response.statusCode;
        throw exception;
      }
    } catch (e) {
      debugPrint('❌ Exception lors de la récupération du profil: $e');
      rethrow;
    }
  }

  // Update Profile
  static Future<User> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final url = '${ApiConfig.baseUrl}/auth/profile';
      debugPrint('👤 Mise à jour du profil: $url');
      
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('📡 Réponse updateProfile: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['error'] as String? ?? errorData['message'] as String? ?? 'Erreur de mise à jour du profil';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Exception lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  // FCM Token Management
  static Future<bool> updateFCMToken(String fcmToken) async {
    try {
      final url = '${ApiConfig.baseUrl}/fcm/token';
      debugPrint('📱 Mise à jour token FCM: $url');
      debugPrint('📱 Token FCM: ${fcmToken.substring(0, 20)}... (${fcmToken.length} caractères)');
      
      final headers = await _getHeaders();
      debugPrint('📱 Headers: ${headers.containsKey('Authorization') ? 'Authorization présent' : 'Authorization manquant'}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      debugPrint('📡 Réponse FCM token: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Token FCM mis à jour avec succès');
        return true;
      } else {
        // Ne pas faire échouer l'app si FCM échoue, juste logger
        debugPrint('⚠️ Échec de mise à jour du token FCM: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      // Ne pas faire échouer l'app si FCM échoue
      debugPrint('⚠️ Exception lors de la mise à jour du token FCM: $e');
      debugPrint('⚠️ Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<void> deleteFCMToken() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/fcm/token'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Token FCM supprimé avec succès');
      } else {
        debugPrint('⚠️ Échec de suppression du token FCM: ${response.statusCode} - ${response.body}');
        // Ne pas throw pour ne pas bloquer la déconnexion
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la suppression du token FCM (non bloquante): $e');
      // Ne pas throw pour ne pas bloquer la déconnexion
    }
  }

  // Version
  static Future<VersionCheck> checkVersion(String platform, String version) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/version/check?platform=$platform&version=$version'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return VersionCheck.fromJson(data);
    } else {
      throw Exception('Échec de vérification de version: ${response.statusCode}');
    }
  }

  // Matchmaking
  static Future<Map<String, dynamic>> findMatch(int gridSize) async {
    try {
      final url = '${ApiConfig.baseUrl}/matchmaking/find';
      debugPrint('📡 [API] POST $url');
      debugPrint('📡 [API] Body: {"grid_size": $gridSize}');
      
      final headers = await _getHeaders();
      debugPrint('📡 [API] Headers: ${headers.keys}');
      debugPrint('📡 [API] Authorization présent: ${headers.containsKey('Authorization')}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'grid_size': gridSize}),
      );

      debugPrint('📡 [API] Réponse status: ${response.statusCode}');
      debugPrint('📡 [API] Réponse body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [API] Données parsées avec succès');
        debugPrint('✅ [API] Type de data[\'game\']: ${data['game'].runtimeType}');
        debugPrint('✅ [API] Contenu de data[\'game\']: ${data['game']}');
        
        // Gérer le cas où 'game' pourrait être une liste ou un objet
        dynamic gameData = data['game'];
        if (gameData is List && gameData.isNotEmpty) {
          // Si c'est une liste, prendre le premier élément
          gameData = gameData[0];
          debugPrint('⚠️ [API] game est une liste, utilisation du premier élément');
        } else if (gameData is List && gameData.isEmpty) {
          throw Exception('Aucune partie trouvée dans la réponse');
        }
        
        return {
          'game': Game.fromJson(gameData as Map<String, dynamic>),
          'matched': data['matched'] as bool,
        };
      } else {
        debugPrint('❌ [API] Erreur HTTP ${response.statusCode}');
        debugPrint('❌ [API] Body erreur: ${response.body}');
        throw Exception('Échec de recherche de partie: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Exception findMatch: $e');
      debugPrint('❌ [API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Invitations
  static Future<Invitation> sendInvitation(int toUserId, int gridSize) async {
    try {
      final url = '${ApiConfig.baseUrl}/invitations';
      debugPrint('📧 [API] POST $url');
      debugPrint('📧 [API] Body: {"to_user_id": $toUserId, "grid_size": $gridSize}');
      
      final headers = await _getHeaders();
      debugPrint('📧 [API] Headers: ${headers.keys}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'to_user_id': toUserId,
          'grid_size': gridSize,
        }),
      );

      debugPrint('📧 [API] Réponse status: ${response.statusCode}');
      debugPrint('📧 [API] Réponse body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [API] Invitation créée avec succès');
        return Invitation.fromJson(data);
      } else {
        debugPrint('❌ [API] Erreur HTTP ${response.statusCode}');
        debugPrint('❌ [API] Body erreur: ${response.body}');
        throw Exception('Échec d\'envoi d\'invitation: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Exception sendInvitation: $e');
      debugPrint('❌ [API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<Invitation>> getInvitations() async {
    try {
      final url = '${ApiConfig.baseUrl}/invitations';
      debugPrint('📧 [API] GET $url');
      
      final headers = await _getHeaders();
      debugPrint('📧 [API] Headers: ${headers.keys}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📧 [API] Réponse status: ${response.statusCode}');
      debugPrint('📧 [API] Réponse body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        debugPrint('✅ [API] ${data.length} invitations récupérées');
        return data.map((e) => Invitation.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        debugPrint('❌ [API] Erreur HTTP ${response.statusCode}');
        debugPrint('❌ [API] Body erreur: ${response.body}');
        throw Exception('Échec de récupération des invitations: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Exception getInvitations: $e');
      debugPrint('❌ [API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<Game> acceptInvitation(int invitationId) async {
    try {
      final url = '${ApiConfig.baseUrl}/invitations/$invitationId/accept';
      debugPrint('📧 [API] POST $url');
      
      final headers = await _getHeaders();
      debugPrint('📧 [API] Headers: ${headers.keys}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📧 [API] Réponse status: ${response.statusCode}');
      debugPrint('📧 [API] Réponse body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [API] Invitation acceptée, Game ID: ${data['id']}');
        return Game.fromJson(data);
      } else {
        debugPrint('❌ [API] Erreur HTTP ${response.statusCode}');
        debugPrint('❌ [API] Body erreur: ${response.body}');
        throw Exception('Échec d\'acceptation d\'invitation: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Exception acceptInvitation: $e');
      debugPrint('❌ [API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> rejectInvitation(int invitationId) async {
    try {
      final url = '${ApiConfig.baseUrl}/invitations/$invitationId/reject';
      debugPrint('📧 [API] POST $url');
      
      final headers = await _getHeaders();
      debugPrint('📧 [API] Headers: ${headers.keys}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📧 [API] Réponse status: ${response.statusCode}');
      debugPrint('📧 [API] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ [API] Invitation rejetée avec succès');
      } else {
        debugPrint('❌ [API] Erreur HTTP ${response.statusCode}');
        debugPrint('❌ [API] Body erreur: ${response.body}');
        throw Exception('Échec de rejet d\'invitation: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Exception rejectInvitation: $e');
      debugPrint('❌ [API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Games
  static Future<Map<String, dynamic>> getGames({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('${ApiConfig.baseUrl}/games').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Échec de récupération des parties: ${response.statusCode}');
    }
  }

  static Future<Game> createGame(int gridSize, {int? opponentId}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/games'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'grid_size': gridSize,
        if (opponentId != null) 'opponent_id': opponentId,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Game.fromJson(data);
    } else {
      throw Exception('Échec de création de partie: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> forfeitGame(int gameId) async {
    try {
      final url = '${ApiConfig.baseUrl}/games/$gameId/forfeit';
      debugPrint('📡 [API] POST $url');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📡 [API] Réponse status: ${response.statusCode}');
      debugPrint('📡 [API] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [API] Partie abandonnée avec succès');
        return data;
      } else {
        debugPrint('❌ [API] Erreur HTTP ${response.statusCode} - Body: ${response.body}');
        throw Exception('Échec d\'abandon de la partie: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Exception forfeitGame: $e');
      debugPrint('❌ [API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Passe le tour automatiquement à l'adversaire (quand le timer expire)
  static Future<Map<String, dynamic>> skipTurn(int gameId) async {
    try {
      final url = '${ApiConfig.baseUrl}/games/$gameId/skip-turn';
      debugPrint('📡 [API] POST $url');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📡 [API] Réponse status: ${response.statusCode}');
      debugPrint('📡 [API] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [API] Tour passé automatiquement');
        return data;
      } else {
        debugPrint('❌ [API] Erreur HTTP ${response.statusCode} - Body: ${response.body}');
        throw Exception('Échec de passage du tour: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Exception skipTurn: $e');
      debugPrint('❌ [API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<Game> getGame(int gameId) async {
    try {
      final url = '${ApiConfig.baseUrl}/games/$gameId';
      debugPrint('📡 [API] GET $url');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📡 [API] Réponse status: ${response.statusCode}');
      debugPrint('📡 [API] Réponse body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [API] Partie récupérée avec succès - ID: ${data['id']}, Status: ${data['status']}, Players: ${(data['players'] as List?)?.length ?? 0}');
        return Game.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('❌ [API] Partie introuvable (404) - Game ID: $gameId');
        throw Exception('Partie introuvable (404). La partie n\'existe peut-être pas encore ou vous n\'y avez pas accès.');
      } else if (response.statusCode == 403) {
        debugPrint('❌ [API] Accès refusé (403) - Game ID: $gameId');
        throw Exception('Accès refusé. Vous n\'êtes pas autorisé à accéder à cette partie.');
      } else {
        debugPrint('❌ [API] Erreur HTTP ${response.statusCode} - Body: ${response.body}');
        throw Exception('Échec de récupération de la partie: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Exception getGame: $e');
      debugPrint('❌ [API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> makeMove(
    int gameId,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/games/$gameId/move'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'from_row': fromRow,
        'from_col': fromCol,
        'to_row': toRow,
        'to_col': toCol,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'move': Move.fromJson(data['move'] as Map<String, dynamic>),
        'game': Game.fromJson(data['game'] as Map<String, dynamic>),
      };
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] as String? ?? 'Échec du mouvement');
    }
  }

  // Private Games
  static Future<Map<String, dynamic>> createPrivateGame(int gridSize) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/games/private/create'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'grid_size': gridSize,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'game': Game.fromJson(data['game'] as Map<String, dynamic>),
        'room_code': data['room_code'] as String,
      };
    } else {
      throw Exception('Échec de création de partie privée: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> joinByCode(String roomCode) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/games/private/join'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'room_code': roomCode.toUpperCase(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'game': Game.fromJson(data['game'] as Map<String, dynamic>),
        'joined': data['joined'] as bool? ?? false,
      };
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] as String? ?? 'Échec de connexion à la partie');
    }
  }

  static Future<Map<String, dynamic>> getGameInfoByCode(String roomCode) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/games/private/info?room_code=${roomCode.toUpperCase()}'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] as String? ?? 'Partie introuvable');
    }
  }

  // Annuler la recherche de partie rapide
  static Future<void> cancelMatch(int gameId) async {
    try {
      final url = '${ApiConfig.baseUrl}/matchmaking/cancel';
      debugPrint('📡 [API] POST $url - Game ID: $gameId');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'game_id': gameId}),
      );

      debugPrint('📡 [API] Réponse status: ${response.statusCode}');
      debugPrint('📡 [API] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ [API] Recherche annulée avec succès');
      } else {
        debugPrint('⚠️ [API] Erreur HTTP ${response.statusCode} - Body: ${response.body}');
        // Ne pas throw pour ne pas bloquer si l'annulation échoue
      }
    } catch (e) {
      debugPrint('⚠️ [API] Exception cancelMatch (non bloquant): $e');
      // Ne pas throw pour ne pas bloquer si l'annulation échoue
    }
  }

  // Annuler une partie privée
  static Future<void> cancelPrivateGame(int gameId) async {
    try {
      final url = '${ApiConfig.baseUrl}/games/private/cancel';
      debugPrint('📡 [API] POST $url - Game ID: $gameId');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'game_id': gameId}),
      );

      debugPrint('📡 [API] Réponse status: ${response.statusCode}');
      debugPrint('📡 [API] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ [API] Partie privée annulée avec succès');
      } else {
        debugPrint('⚠️ [API] Erreur HTTP ${response.statusCode} - Body: ${response.body}');
        // Ne pas throw pour ne pas bloquer si l'annulation échoue
      }
    } catch (e) {
      debugPrint('⚠️ [API] Exception cancelPrivateGame (non bloquant): $e');
      // Ne pas throw pour ne pas bloquer si l'annulation échoue
    }
  }

  // Statistics
  static Future<Statistic> getStatistics() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/statistics'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Statistic.fromJson(data);
    } else {
      throw Exception('Échec de récupération des statistiques: ${response.statusCode}');
    }
  }

  static Future<LeaderboardResponse> getLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/leaderboard?limit=$limit&offset=$offset';
      debugPrint('📊 [API] GET $url');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📊 [API] Réponse status: ${response.statusCode}');
      debugPrint('📊 [API] Réponse body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [API] Classement récupéré: ${data['total']} joueurs');
        return LeaderboardResponse.fromJson(data);
      } else {
        debugPrint('❌ [API] Erreur HTTP ${response.statusCode} - Body: ${response.body}');
        throw Exception('Échec de récupération du classement: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Exception getLeaderboard: $e');
      debugPrint('❌ [API] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // AdMob - Récupération des IDs (publique, pas besoin d'auth)
  static Future<Map<String, dynamic>?> get(String url) async {
    try {
      debugPrint('📡 [API] GET $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📡 [API] Réponse status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        debugPrint('⚠️ [API] Erreur HTTP ${response.statusCode} - Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [API] Exception GET: $e');
      return null;
    }
  }
}

