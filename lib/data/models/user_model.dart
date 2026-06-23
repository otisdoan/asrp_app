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

  // Role priority: highest-privilege role wins when user has multiple roles.
  static const _rolePriority = <String, int>{
    'SuperAdmin': 0,
    'Admin': 1,
    'Manager': 2,
    'Staff': 3,
    'Customer': 4,
  };

  static String _pickHighestRole(List<dynamic> roles) {
    String best = 'Customer';
    int bestPriority = _rolePriority['Customer'] ?? 99;

    for (final r in roles) {
      final String name;
      if (r is Map) {
        name = (r['name'] ?? r['roleName'] ?? r['role'] ?? '').toString();
      } else {
        name = r.toString();
      }
      final priority = _rolePriority[name] ?? 99;
      if (priority < bestPriority) {
        bestPriority = priority;
        best = name;
      }
    }
    return best;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String resolvedRole = 'Customer';
    if (json['role'] != null) {
      resolvedRole = json['role'].toString();
    } else if (json['roles'] != null) {
      if (json['roles'] is List && (json['roles'] as List).isNotEmpty) {
        resolvedRole = _pickHighestRole(json['roles'] as List);
      } else {
        resolvedRole = json['roles'].toString();
      }
    }

    if (resolvedRole.trim().isEmpty) {
      resolvedRole = 'Customer';
    }

    return UserModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      username: (json['username'] ?? json['userName'])?.toString() ?? '',
      email: json['email']?.toString(),
      phone: (json['phone'] ?? json['phoneNumber'])?.toString(),
      fullName: json['fullName']?.toString(),
      avatar: json['avatar']?.toString(),
      gender: json['gender']?.toString(),
      birthday: json['birthday']?.toString(),
      role: resolvedRole,
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : (json['isActive'] == null || json['isActive']?.toString() == 'true'),
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
