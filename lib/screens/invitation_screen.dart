import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../models/invitation.dart';
import '../models/game_mode.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sound_button.dart';
import '../mixins/background_music_mixin.dart';
import 'game_screen.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> with SingleTickerProviderStateMixin, BackgroundMusicMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('📧 [INVITATION] Chargement des invitations...');
      context.read<InvitationProvider>().loadInvitations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.inbox), text: 'Reçues'),
              Tab(icon: Icon(Icons.send), text: 'Envoyer'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ReceivedInvitationsTab(),
                _SendInvitationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedInvitationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<InvitationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${provider.error}',
                  style: TextStyle(color: Colors.red[300]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SoundElevatedButton(
                  onPressed: () {
                    debugPrint('🔄 [INVITATION] Rechargement des invitations...');
                    provider.loadInvitations();
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final receivedInvitations = provider.invitations
            .where((i) => i.toUserId == context.read<AuthProvider>().user?.id)
            .toList();

        if (receivedInvitations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune invitation reçue',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () {
            debugPrint('🔄 [INVITATION] Refresh des invitations reçues');
            return provider.loadInvitations();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: receivedInvitations.length,
            itemBuilder: (context, index) {
              final invitation = receivedInvitations[index];
              return _InvitationCard(
                invitation: invitation,
                isReceived: true,
                onAccept: () => _handleAccept(context, provider, invitation),
                onReject: () => _handleReject(context, provider, invitation),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleAccept(BuildContext context, InvitationProvider provider, Invitation invitation) async {
    debugPrint('✅ [INVITATION] Acceptation invitation ID: ${invitation.id}');
    final game = await provider.acceptInvitation(invitation.id);
    if (game != null) {
      debugPrint('✅ [INVITATION] Invitation acceptée, Game ID: ${game.id}');
      if (context.mounted) {
        // Nettoyer l'état du GameProvider avant de naviguer vers la nouvelle partie
        final gameProvider = context.read<GameProvider>();
        gameProvider.resetStateForNewGame();
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameScreen(gameId: game.id),
          ),
        );
      }
    } else {
      debugPrint('❌ [INVITATION] Erreur acceptation: ${provider.error}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${provider.error ?? "Échec d\'acceptation"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, InvitationProvider provider, Invitation invitation) async {
    debugPrint('❌ [INVITATION] Rejet invitation ID: ${invitation.id}');
    final success = await provider.rejectInvitation(invitation.id);
    if (success) {
      debugPrint('✅ [INVITATION] Invitation rejetée');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation rejetée')),
        );
      }
    } else {
      debugPrint('❌ [INVITATION] Erreur rejet: ${provider.error}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SendInvitationTab extends StatefulWidget {
  @override
  State<_SendInvitationTab> createState() => _SendInvitationTabState();
}

class _SendInvitationTabState extends State<_SendInvitationTab> {
  final _userIdController = TextEditingController();
  int? _selectedGridSize;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation(BuildContext context) async {
    final userIdText = _userIdController.text.trim();
    if (userIdText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un ID utilisateur')),
      );
      return;
    }

    final userId = int.tryParse(userIdText);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID utilisateur invalide')),
      );
      return;
    }

    if (_selectedGridSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une taille de grille')),
      );
      return;
    }

    debugPrint('📧 [INVITATION] Envoi invitation à User ID: $userId, GridSize: $_selectedGridSize');
    
    final provider = context.read<InvitationProvider>();
    final invitation = await provider.sendInvitation(userId, _selectedGridSize!);

    if (invitation != null && mounted) {
      debugPrint('✅ [INVITATION] Invitation envoyée avec succès, ID: ${invitation.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation envoyée!')),
      );
      _userIdController.clear();
      setState(() => _selectedGridSize = null);
    } else if (mounted) {
      debugPrint('❌ [INVITATION] Erreur envoi: ${provider.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${provider.error ?? "Échec d'envoi"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Envoyer une invitation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez l\'ID de l\'utilisateur que vous souhaitez inviter',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _userIdController,
            decoration: const InputDecoration(
              labelText: 'ID Utilisateur',
              hintText: 'Ex: 1',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text(
            'Taille de la grille',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...GridSize.values.map((size) {
            return RadioListTile<int>(
              title: Text(size.label),
              value: size.value,
              groupValue: _selectedGridSize,
              onChanged: (value) {
                setState(() => _selectedGridSize = value);
              },
            );
          }),
          const SizedBox(height: 32),
          Consumer<InvitationProvider>(
            builder: (context, provider, child) {
              return SoundElevatedButton(
                onPressed: provider.isLoading ? null : () => _sendInvitation(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Envoyer l\'invitation'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final Invitation invitation;
  final bool isReceived;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _InvitationCard({
    required this.invitation,
    required this.isReceived,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final user = isReceived ? invitation.fromUser : invitation.toUser;
    final statusColor = _getStatusColor(invitation.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          user?.name[0].toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Utilisateur inconnu',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Grille ${invitation.gridSize}x${invitation.gridSize}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(invitation.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (invitation.status == 'pending' && isReceived && !invitation.isExpired) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SoundElevatedButton(
                      onPressed: onAccept,
                      child: const Text('Accepter'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      case 'expired':
        return 'Expirée';
      default:
        return status;
    }
  }
}


