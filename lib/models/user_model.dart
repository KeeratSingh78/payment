class UserModel {
  final String id;
  final String phone;
  final String name;
  final String trustedContact;
  final double balance;
  final String upiId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? pinHash; // Store PIN hash for verification
  final String? duressPinHash; // Store duress PIN hash

  UserModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.trustedContact,
    required this.balance,
    required this.upiId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.pinHash,
    this.duressPinHash,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String,
      trustedContact: json['trusted_contact'] as String,
      balance: (json['balance'] as num).toDouble(),
      upiId: json['upi_id'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      pinHash: json['pin_hash'] as String?,
      duressPinHash: json['duress_pin_hash'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'trusted_contact': trustedContact,
      'balance': balance,
      'upi_id': upiId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'pin_hash': pinHash,
      'duress_pin_hash': duressPinHash,
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? trustedContact,
    double? balance,
    String? upiId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? pinHash,
    String? duressPinHash,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      trustedContact: trustedContact ?? this.trustedContact,
      balance: balance ?? this.balance,
      upiId: upiId ?? this.upiId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinHash: pinHash ?? this.pinHash,
      duressPinHash: duressPinHash ?? this.duressPinHash,
    );
  }
}
