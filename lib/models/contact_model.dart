class ContactModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? upiId;
  final bool isFrequent;
  final DateTime createdAt;

  ContactModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.upiId,
    required this.isFrequent,
    required this.createdAt,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      upiId: json['upi_id'] as String?,
      isFrequent: json['is_frequent'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'upi_id': upiId,
      'is_frequent': isFrequent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ContactModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? upiId,
    bool? isFrequent,
    DateTime? createdAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      upiId: upiId ?? this.upiId,
      isFrequent: isFrequent ?? this.isFrequent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
