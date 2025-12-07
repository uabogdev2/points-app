import 'user.dart';

class Invitation {
  final int id;
  final int fromUserId;
  final int toUserId;
  final User? fromUser;
  final User? toUser;
  final String status; // pending, accepted, rejected, expired
  final int gridSize;
  final DateTime createdAt;
  final DateTime? expiresAt;

  Invitation({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.fromUser,
    this.toUser,
    required this.status,
    required this.gridSize,
    required this.createdAt,
    this.expiresAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as int,
      fromUserId: json['from_user_id'] as int,
      toUserId: json['to_user_id'] as int,
      fromUser: json['from_user'] != null
          ? User.fromJson(json['from_user'] as Map<String, dynamic>)
          : null,
      toUser: json['to_user'] != null
          ? User.fromJson(json['to_user'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String,
      gridSize: json['grid_size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'from_user': fromUser?.toJson(),
      'to_user': toUser?.toJson(),
      'status': status,
      'grid_size': gridSize,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

