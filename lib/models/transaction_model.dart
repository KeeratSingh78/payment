
enum TransactionType { sent, received, qrPayment }
enum TransactionStatus { pending, completed, failed, cancelled }

class TransactionModel {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String referenceId;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? senderName;
  final String? receiverName;

  TransactionModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.type,
    required this.status,
    required this.referenceId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.senderName,
    this.receiverName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['transaction_type'],
        orElse: () => TransactionType.sent,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      referenceId: json['reference_id'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      senderName: json['sender_name'] as String?,
      receiverName: json['receiver_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'amount': amount,
      'transaction_type': type.name,
      'status': status.name,
      'reference_id': referenceId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedAmount {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String get statusText {
    switch (status) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get typeText {
    switch (type) {
      case TransactionType.sent:
        return 'Sent';
      case TransactionType.received:
        return 'Received';
      case TransactionType.qrPayment:
        return 'QR Payment';
    }
  }
}

class FraudLogModel {
  final String id;
  final String userId;
  final String fraudType;
  final String description;
  final String severity;
  final bool isResolved;
  final bool alertSent;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  FraudLogModel({
    required this.id,
    required this.userId,
    required this.fraudType,
    required this.description,
    required this.severity,
    required this.isResolved,
    required this.alertSent,
    required this.createdAt,
    this.resolvedAt,
  });

  factory FraudLogModel.fromJson(Map<String, dynamic> json) {
    return FraudLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fraudType: json['fraud_type'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      isResolved: json['is_resolved'] as bool,
      alertSent: json['alert_sent'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'fraud_type': fraudType,
      'description': description,
      'severity': severity,
      'is_resolved': isResolved,
      'alert_sent': alertSent,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  FraudLogModel copyWith({
    String? id,
    String? userId,
    String? fraudType,
    String? description,
    String? severity,
    bool? isResolved,
    bool? alertSent,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return FraudLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fraudType: fraudType ?? this.fraudType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      isResolved: isResolved ?? this.isResolved,
      alertSent: alertSent ?? this.alertSent,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

class VoiceCommandModel {
  final String id;
  final String userId;
  final String commandText;
  final String? processedText;
  final String? actionTaken;
  final double? confidenceScore;
  final String? language;
  final DateTime createdAt;

  VoiceCommandModel({
    required this.id,
    required this.userId,
    required this.commandText,
    this.processedText,
    this.actionTaken,
    this.confidenceScore,
    this.language,
    required this.createdAt,
  });

  factory VoiceCommandModel.fromJson(Map<String, dynamic> json) {
    return VoiceCommandModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      commandText: json['command_text'] as String,
      processedText: json['processed_text'] as String?,
      actionTaken: json['action_taken'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      language: json['language'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'command_text': commandText,
      'processed_text': processedText,
      'action_taken': actionTaken,
      'confidence_score': confidenceScore,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
