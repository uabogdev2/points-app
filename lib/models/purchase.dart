class Purchase {
  final int id;
  final int userId;
  final String productId;
  final String transactionId;
  final String platform; // 'android' ou 'ios'
  final String? purchaseToken; // Pour Google Play
  final String? receiptData; // Pour App Store
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Purchase({
    required this.id,
    required this.userId,
    required this.productId,
    required this.transactionId,
    required this.platform,
    this.purchaseToken,
    this.receiptData,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      productId: json['product_id'] as String,
      transactionId: json['transaction_id'] as String,
      platform: json['platform'] as String,
      purchaseToken: json['purchase_token'] as String?,
      receiptData: json['receipt_data'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'transaction_id': transactionId,
      'platform': platform,
      'purchase_token': purchaseToken,
      'receipt_data': receiptData,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

