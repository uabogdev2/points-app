import 'package:flutter/foundation.dart';
import '../models/invitation.dart';
import '../models/game.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

class InvitationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final SocketService _socketService = SocketService();
  List<Invitation> _invitations = [];
  bool _isLoading = false;
  String? _error;

  List<Invitation> get invitations => _invitations;
  List<Invitation> get pendingInvitations =>
      _invitations.where((i) => i.status == 'pending' && !i.isExpired).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  InvitationProvider() {
    _setupNotificationListeners();
    _setupSocketListeners();
  }

  void _setupNotificationListeners() {
    _notificationService.onInvitationReceived = (Invitation invitation) {
      // Recharger les invitations quand une nouvelle est reçue
      loadInvitations();
    };
  }

  void _setupSocketListeners() {
    // Écouter les invitations via Socket.IO (en complément de FCM)
    // Note: Le backend doit émettre l'événement 'invitation-received' via Socket.IO
    // Pour l'instant, on utilise principalement FCM, mais Socket.IO peut être utilisé
    // pour une mise à jour instantanée si l'app est ouverte
  }

  // Charger les invitations
  Future<void> loadInvitations() async {
    debugPrint('📧 [INVITATION_PROVIDER] Chargement des invitations...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _invitations = await ApiService.getInvitations();
      debugPrint('✅ [INVITATION_PROVIDER] ${_invitations.length} invitations chargées');
    } catch (e, stackTrace) {
      debugPrint('❌ [INVITATION_PROVIDER] Erreur chargement: $e');
      debugPrint('❌ [INVITATION_PROVIDER] Stack trace: $stackTrace');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Envoyer une invitation
  Future<Invitation?> sendInvitation(int toUserId, int gridSize) async {
    debugPrint('📧 [INVITATION_PROVIDER] Envoi invitation - User ID: $toUserId, GridSize: $gridSize');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final invitation = await ApiService.sendInvitation(toUserId, gridSize);
      debugPrint('✅ [INVITATION_PROVIDER] Invitation envoyée, ID: ${invitation.id}');
      await loadInvitations(); // Recharger la liste
      return invitation;
    } catch (e, stackTrace) {
      debugPrint('❌ [INVITATION_PROVIDER] Erreur envoi: $e');
      debugPrint('❌ [INVITATION_PROVIDER] Stack trace: $stackTrace');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Accepter une invitation
  Future<Game?> acceptInvitation(int invitationId) async {
    debugPrint('✅ [INVITATION_PROVIDER] Acceptation invitation ID: $invitationId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final game = await ApiService.acceptInvitation(invitationId);
      debugPrint('✅ [INVITATION_PROVIDER] Invitation acceptée avec succès, Game ID: ${game.id}');
      await loadInvitations(); // Recharger la liste
      return game;
    } catch (e, stackTrace) {
      debugPrint('❌ [INVITATION_PROVIDER] Erreur acceptation: $e');
      debugPrint('❌ [INVITATION_PROVIDER] Stack trace: $stackTrace');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rejeter une invitation
  Future<bool> rejectInvitation(int invitationId) async {
    debugPrint('❌ [INVITATION_PROVIDER] Rejet invitation ID: $invitationId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.rejectInvitation(invitationId);
      debugPrint('✅ [INVITATION_PROVIDER] Invitation rejetée avec succès');
      await loadInvitations(); // Recharger la liste
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [INVITATION_PROVIDER] Erreur rejet: $e');
      debugPrint('❌ [INVITATION_PROVIDER] Stack trace: $stackTrace');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

