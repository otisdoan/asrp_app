class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatar;
  final String role; // 'admin' | 'staff' | 'customer'
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    this.fullName,
    this.avatar,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      fullName: json['fullName']?.toString(),
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : (json['isActive']?.toString() == 'true'),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'phone': phone,
        'fullName': fullName,
        'avatar': avatar,
        'role': role,
        'isActive': isActive,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  String get displayName => fullName ?? username;
}
