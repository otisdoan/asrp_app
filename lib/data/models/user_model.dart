class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatar;
  final String? gender;
  final String? birthday;
  final String role; // 'Admin' | 'Staff' | 'Customer'
  final bool isActive;
  final int points;
  final String? tier;
  final String? address;
  final String createdAt;
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    this.fullName,
    this.avatar,
    this.gender,
    this.birthday,
    required this.role,
    required this.isActive,
    this.points = 0,
    this.tier,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String resolvedRole = 'Customer';
    if (json['role'] != null) {
      resolvedRole = json['role'].toString();
    } else if (json['roles'] != null) {
      if (json['roles'] is List && (json['roles'] as List).isNotEmpty) {
        final firstRole = (json['roles'] as List).first;
        if (firstRole is Map) {
          resolvedRole = (firstRole['name'] ?? firstRole['roleName'] ?? firstRole['role'] ?? '').toString();
        } else {
          resolvedRole = firstRole.toString();
        }
      } else {
        resolvedRole = json['roles'].toString();
      }
    }

    if (resolvedRole.trim().isEmpty) {
      resolvedRole = 'Customer';
    }

    return UserModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      fullName: json['fullName']?.toString(),
      avatar: json['avatar']?.toString(),
      gender: json['gender']?.toString(),
      birthday: json['birthday']?.toString(),
      role: resolvedRole,
      isActive: json['isActive'] is bool ? json['isActive'] as bool : (json['isActive']?.toString() == 'true'),
      points: json['points'] is int
          ? json['points'] as int
          : int.tryParse(json['points']?.toString() ?? '') ?? 0,
      tier: json['tier']?.toString(),
      address: json['address']?.toString(),
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
        'gender': gender,
        'birthday': birthday,
        'role': role,
        'roles': [role],
        'isActive': isActive,
        'points': points,
        'tier': tier,
        'address': address,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  String get displayName => fullName ?? username;
}
