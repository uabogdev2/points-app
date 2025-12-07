import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../models/game.dart';
import '../models/invitation.dart';
import '../providers/auth_provider.dart';

/// Vérifie si les notifications push sont activées (pour le handler en arrière-plan)
Future<bool> _arePushNotificationsEnabledBackground() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('push_notifications_enabled') ?? true;
  } catch (e) {
    debugPrint('❌ [NOTIF] Erreur vérification paramètres (background): $e');
    return true; // Par défaut activées
  }
}

/// Handler pour les notifications en arrière-plan
/// DOIT être une fonction top-level ou statique
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Vérifier si les notifications push sont activées
  final enabled = await _arePushNotificationsEnabledBackground();
  if (!enabled) {
    debugPrint('🔔 [NOTIF] Notification ignorée en arrière-plan (notifications push désactivées)');
    return;
  }
  
  debugPrint('🔔 Notification reçue en arrière-plan');
  debugPrint('🔔 Titre: ${message.notification?.title}');
  debugPrint('🔔 Corps: ${message.notification?.body}');
  debugPrint('🔔 Données: ${message.data}');
  debugPrint('🔔 Message ID: ${message.messageId}');
  
  // Traiter selon le type
  final type = message.data['type'] as String?;
  debugPrint('🔔 Type de notification: $type');
  
  switch (type) {
    case 'invitation':
      // TODO: Naviguer vers l'écran d'invitations
      debugPrint('✅ Nouvelle invitation: ${message.data['invitation_id']}');
      break;
    case 'game_turn':
      // TODO: Naviguer vers la partie
      debugPrint('✅ Tour de jeu: ${message.data['game_id']}');
      break;
    case 'game_finished':
      // TODO: Afficher les résultats
      debugPrint('✅ Partie terminée: ${message.data['game_id']}');
      break;
    case 'global':
      // TODO: Afficher la notification globale
      debugPrint('✅ Notification globale: ${message.data['notification_id']}');
      break;
    case 'test':
      debugPrint('✅ Notification de test reçue');
      break;
    case 'info':
    case 'warning':
    case 'success':
    case 'error':
      // Types de notifications AppNotification
      debugPrint('✅ Notification de type $type reçue: ${message.data['notification_id']}');
      break;
    default:
      debugPrint('⚠️ Type de notification inconnu: $type');
      debugPrint('⚠️ Données complètes: ${message.data}');
  }
}

class NotificationService {
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  FirebaseMessaging get messaging {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }
  
  // Callbacks
  Function(Invitation)? onInvitationReceived;
  Function(int)? onGameTurn;
  Function(int)? onGameFinished;
  Function(Map<String, dynamic>)? onGlobalNotification;
  // Callback pour la navigation vers un écran spécifique
  Function(String)? onNavigateToScreen;
  // Action en attente si le callback n'est pas encore configuré
  String? _pendingAction;
  
  /// Définit le callback de navigation et traite l'action en attente si elle existe
  void setNavigateToScreenCallback(Function(String)? callback, {bool checkAuth = true}) {
    onNavigateToScreen = callback;
    
    // Vérifier s'il y a une action en attente dans le stockage persistant
    _checkAndProcessPendingAction(callback, checkAuth: checkAuth);
  }
  
  /// Vérifie et traite l'action en attente (depuis le stockage ou la mémoire)
  Future<void> _checkAndProcessPendingAction(Function(String)? callback, {bool checkAuth = true}) async {
    if (callback == null) return;
    
    // Vérifier d'abord le stockage persistant (pour les cas où l'app a été fermée)
    final storedAction = await StorageService.getPendingNotificationAction();
    if (storedAction != null && storedAction.isNotEmpty) {
      debugPrint('🔔 Action trouvée dans le stockage: $storedAction');
      
      // Vérifier l'état de connexion si nécessaire
      if (checkAuth) {
        // Attendre un peu pour que AuthProvider soit initialisé
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Traiter l'action
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          callback(storedAction);
        });
      });
      
      // Nettoyer le stockage après traitement
      await StorageService.clearPendingNotificationAction();
      return;
    }
    
    // Sinon, vérifier l'action en mémoire
    if (_pendingAction != null && _pendingAction!.isNotEmpty) {
      final action = _pendingAction!;
      _pendingAction = null;
      debugPrint('🔔 Traitement de l\'action en attente (mémoire): $action');
      
      if (checkAuth) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          callback(action);
        });
      });
    }
  }

  /// Initialise Firebase Messaging
  Future<void> initialize() async {
    debugPrint('🔔 Initialisation de Firebase Messaging...');
    
    // Vérifier que Firebase est initialisé
    try {
      Firebase.app(); // Vérifier que Firebase est initialisé
    } catch (e) {
      debugPrint('❌ Firebase non initialisé, impossible d\'initialiser NotificationService: $e');
      return;
    }
    
    // Initialiser FirebaseMessaging de manière lazy
    _messaging ??= FirebaseMessaging.instance;
    
    // Initialiser les notifications locales pour afficher en foreground
    await _initializeLocalNotifications();
    
    // Demander la permission (iOS)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('🔔 Statut de permission: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Permission de notification accordée');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️ Permission de notification provisoire');
    } else {
      debugPrint('❌ Permission de notification refusée: ${settings.authorizationStatus}');
      return;
    }

    // Configurer le handler pour les notifications en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Handler arrière-plan configuré');

    // Écouter les notifications en foreground
    FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(message).catchError((e) {
        debugPrint('❌ Erreur lors du traitement de la notification foreground: $e');
      });
    });
    debugPrint('✅ Listener foreground configuré');

    // Écouter les notifications quand l'app est en arrière-plan et ouverte
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageOpened(message);
    });
    debugPrint('✅ Listener onMessageOpenedApp configuré');

    // Vérifier si l'app a été ouverte depuis une notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 App ouverte depuis une notification (initial message)');
      await _handleMessageOpened(initialMessage);
    }

    // Obtenir le token FCM initial
    await _getAndUpdateToken();
    debugPrint('✅ Token FCM initial obtenu');

    // Écouter les changements de token
    messaging.onTokenRefresh.listen(_onTokenRefresh);
    debugPrint('✅ Listener onTokenRefresh configuré');
    
    debugPrint('✅ Firebase Messaging initialisé avec succès');
  }
  
  /// Initialise les notifications locales pour afficher en foreground
  Future<void> _initializeLocalNotifications() async {
    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Supprimer l'ancien canal s'il existe (pour pouvoir le recréer avec le nouveau son)
        try {
          await androidImplementation.deleteNotificationChannel('points_master_channel');
          debugPrint('🗑️ [NOTIF] Ancien canal supprimé');
        } catch (e) {
          debugPrint('ℹ️ [NOTIF] Aucun canal existant à supprimer');
        }
      }
      
      // Créer le canal Android pour les notifications avec son personnalisé
      // Utiliser un nom de canal avec version pour forcer la recréation avec le son
      const androidChannel = AndroidNotificationChannel(
        'points_master_channel_v2',
        'Points Master Notifications',
        description: 'Notifications pour Points Master',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('clic_square'),
        enableVibration: true,
      );
      
      // Créer le canal (nécessaire pour Android 8.0+)
      await androidImplementation?.createNotificationChannel(androidChannel);
      debugPrint('✅ [NOTIF] Canal Android créé avec son personnalisé: clic_square');
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      if (initialized ?? false) {
        debugPrint('✅ Notifications locales initialisées avec succès');
      } else {
        debugPrint('⚠️ Notifications locales non initialisées');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'initialisation des notifications locales: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
  
  /// Gère le tap sur une notification locale
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification locale tapée: ${response.payload}');
    // Traiter le payload si nécessaire
  }
  
  /// Affiche une notification locale (pour foreground)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'points_master_channel_v2',
        'Points Master Notifications',
        channelDescription: 'Notifications pour Points Master',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('clic_square'),
        enableVibration: true,
        icon: '@drawable/ic_stat_motification_logo',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Pour iOS, utiliser le nom sans extension
        // iOS cherche automatiquement le fichier avec les extensions .caf, .aif, .wav, .mp3
        sound: 'clic-square',
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: data != null ? data.toString() : null,
      );
      
      debugPrint('✅ Notification locale affichée (ID: $notificationId): $title');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'affichage de la notification locale: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Vérifie si les notifications push sont activées
  Future<bool> _arePushNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('push_notifications_enabled') ?? true;
    } catch (e) {
      debugPrint('❌ [NOTIF] Erreur vérification paramètres: $e');
      return true; // Par défaut activées
    }
  }

  /// Gère les notifications en foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Vérifier si les notifications push sont activées
    final enabled = await _arePushNotificationsEnabled();
    if (!enabled) {
      debugPrint('🔔 [NOTIF] Notification ignorée (notifications push désactivées)');
      return;
    }
    
    debugPrint('🔔 Notification reçue en foreground');
    debugPrint('🔔 Titre: ${message.notification?.title}');
    debugPrint('🔔 Corps: ${message.notification?.body}');
    debugPrint('🔔 Données: ${message.data}');
    debugPrint('🔔 Message ID: ${message.messageId}');
    debugPrint('🔔 From: ${message.from}');
    
    // Afficher la notification localement (car Android ne l'affiche pas automatiquement en foreground)
    if (message.notification != null) {
      try {
        await _showLocalNotification(
          title: message.notification!.title ?? 'Points Master',
          body: message.notification!.body ?? '',
          data: message.data,
        );
        debugPrint('✅ Notification locale affichée avec succès');
      } catch (e, stackTrace) {
        debugPrint('❌ Erreur lors de l\'affichage de la notification locale: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
    } else {
      debugPrint('⚠️ Notification sans titre/corps, affichage avec données uniquement');
      // Afficher quand même avec les données
      final title = message.data['title'] as String? ?? 'Points Master';
      final body = message.data['body'] as String? ?? message.data['message'] as String? ?? 'Nouvelle notification';
      try {
        await _showLocalNotification(
          title: title,
          body: body,
          data: message.data,
        );
      } catch (e) {
        debugPrint('❌ Erreur lors de l\'affichage: $e');
      }
    }
    
    await _processNotification(message);
  }

  /// Gère les notifications qui ouvrent l'app
  Future<void> _handleMessageOpened(RemoteMessage message) async {
    debugPrint('🔔 App ouverte depuis une notification');
    debugPrint('🔔 Titre: ${message.notification?.title}');
    debugPrint('🔔 Corps: ${message.notification?.body}');
    debugPrint('🔔 Données: ${message.data}');
    
    // Traiter la notification immédiatement
    await _processNotification(message);
    
    // Si le callback de navigation n'est pas encore configuré, stocker l'action pour plus tard
    final data = message.data;
    final actionType = data['action_type'] as String?;
    if (actionType != null && onNavigateToScreen == null) {
      debugPrint('⚠️ Callback de navigation pas encore configuré, action stockée: $actionType');
      // Le callback sera configuré dans home_screen.dart et traitera l'action
    }
  }

  /// Traite une notification selon son type
  Future<void> _processNotification(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] as String?;
    
    debugPrint('🔔 Traitement de la notification - Type: $type');
    debugPrint('🔔 Données complètes: $data');

    switch (type) {
      case 'invitation':
        final invitationId = int.tryParse(data['invitation_id'] as String? ?? '');
        if (invitationId != null) {
          debugPrint('✅ Traitement invitation: $invitationId');
          onInvitationReceived?.call(Invitation(
            id: invitationId,
            fromUserId: int.tryParse(data['from_user_id'] as String? ?? '') ?? 0,
            toUserId: 0,
            status: 'pending',
            gridSize: int.tryParse(data['grid_size'] as String? ?? '') ?? 5,
            createdAt: DateTime.now(),
          ));
        } else {
          debugPrint('⚠️ Invitation ID invalide: ${data['invitation_id']}');
        }
        break;

      case 'game_turn':
        final gameId = int.tryParse(data['game_id'] as String? ?? '');
        if (gameId != null) {
          debugPrint('✅ Traitement tour de jeu: $gameId');
          onGameTurn?.call(gameId);
        } else {
          debugPrint('⚠️ Game ID invalide: ${data['game_id']}');
        }
        break;

      case 'game_finished':
        final gameId = int.tryParse(data['game_id'] as String? ?? '');
        if (gameId != null) {
          debugPrint('✅ Traitement fin de partie: $gameId');
          onGameFinished?.call(gameId);
        } else {
          debugPrint('⚠️ Game ID invalide: ${data['game_id']}');
        }
        break;

      case 'global':
        debugPrint('✅ Traitement notification globale');
        onGlobalNotification?.call(data);
        break;
        
      case 'test':
        debugPrint('✅ Notification de test reçue et traitée');
        // Afficher un message pour les notifications de test
        break;
        
      case 'info':
      case 'warning':
      case 'success':
      case 'error':
        // Types de notifications AppNotification (info, warning, success, error)
        debugPrint('✅ Notification de type $type reçue et traitée');
        
        // Vérifier s'il y a une action à effectuer
        final actionType = data['action_type'] as String?;
        if (actionType != null && actionType.isNotEmpty) {
          debugPrint('🔔 Action demandée: $actionType');
          
          // Stocker l'action dans le stockage persistant pour qu'elle survive au redémarrage
          await StorageService.savePendingNotificationAction(actionType);
          
          // Vérifier si l'utilisateur est connecté
          // Note: On ne peut pas accéder directement à AuthProvider ici, donc on stocke et on laisse HomeScreen gérer
          if (onNavigateToScreen != null) {
            // Si le callback est configuré, vérifier l'état de connexion avant de naviguer
            // On laisse HomeScreen gérer la vérification de l'état de connexion
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 500), () {
                onNavigateToScreen!(actionType);
              });
            });
          } else {
            // Stocker l'action pour plus tard si le callback n'est pas encore configuré
            debugPrint('⚠️ Callback de navigation pas encore configuré, action stockée: $actionType');
            _pendingAction = actionType;
          }
        }
        
        // Traiter comme une notification globale
        onGlobalNotification?.call(data);
        break;
        
      default:
        debugPrint('⚠️ Type de notification non géré: $type');
        debugPrint('⚠️ Données: $data');
        
        // Vérifier s'il y a une action à effectuer même pour les types inconnus
        final actionType = data['action_type'] as String?;
        if (actionType != null) {
          if (onNavigateToScreen != null) {
            onNavigateToScreen!(actionType);
          } else {
            // Stocker l'action pour plus tard si le callback n'est pas encore configuré
            debugPrint('⚠️ Callback de navigation pas encore configuré, action stockée: $actionType');
            _pendingAction = actionType;
          }
          debugPrint('🔔 Action demandée: $actionType');
          onNavigateToScreen?.call(actionType);
        }
        
        // Traiter quand même comme une notification globale
        onGlobalNotification?.call(data);
    }
  }

  /// Obtient et met à jour le token FCM
  Future<void> _getAndUpdateToken() async {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('Token FCM obtenu: $token');
        // Ne pas mettre à jour ici si l'utilisateur n'est pas connecté
        // La mise à jour sera faite après la connexion dans AuthProvider
        // await ApiService.updateFCMToken(token);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention du token FCM: $e');
    }
  }

  /// Gère le rafraîchissement du token FCM
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('Nouveau token FCM: $newToken');
    try {
      // Vérifier si l'utilisateur est connecté avant de mettre à jour
      final token = await StorageService.getToken();
      if (token != null) {
        await ApiService.updateFCMToken(newToken);
        debugPrint('✅ Token FCM mis à jour après rafraîchissement');
      } else {
        debugPrint('⚠️ Token FCM rafraîchi mais utilisateur non connecté, mise à jour différée');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la mise à jour du token FCM (non bloquante): $e');
      // Ne pas throw pour ne pas bloquer l'app
    }
  }

  /// Supprime le token FCM (lors de la déconnexion)
  Future<void> deleteToken() async {
    try {
      await messaging.deleteToken();
      await ApiService.deleteFCMToken();
      debugPrint('Token FCM supprimé');
    } catch (e) {
      debugPrint('Erreur lors de la suppression du token FCM: $e');
    }
  }

  /// Obtient le token FCM actuel
  Future<String?> getToken() async {
    return await messaging.getToken();
  }
}

