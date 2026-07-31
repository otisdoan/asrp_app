class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatar;
  final String? gender;
  final String? birthday;
  final String? brandId;
  final String? branchId;
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
    this.brandId,
    this.branchId,
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
      id: (json['id'] ?? json['_id'] ?? json['customerId'] ?? json['userId'])?.toString() ?? '',
      username: (json['username'] ?? json['userName'] ?? json['phoneNumber'] ?? json['phone'])?.toString() ?? '',
      email: json['email']?.toString(),
      phone: (json['phone'] ?? json['phoneNumber'])?.toString(),
      fullName: json['fullName']?.toString(),
      avatar: json['avatar']?.toString(),
      gender: json['gender']?.toString(),
      birthday: json['birthday']?.toString(),
      brandId: json['brandId']?.toString(),
      branchId: json['branchId']?.toString(),
      role: resolvedRole,
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : (json['isActive'] == null || json['isActive']?.toString() == 'true'),
      points: (json['points'] as num?)?.toInt() ?? 
              (json['totalPoints'] as num?)?.toInt() ?? 
              (json['dxCoins'] as num?)?.toInt() ?? 
              int.tryParse(json['points']?.toString() ?? '') ?? 0,
      tier: json['tier']?.toString() ?? json['membershipTier']?.toString(),
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
        'brandId': brandId,
        'branchId': branchId,
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

  /// Member tier calculation based on points/DX
  String get tierName {
    if (tier != null && tier!.isNotEmpty) {
      final t = tier!.toLowerCase();
      if (t.contains('diamond') || t.contains('kim cương')) return 'Hạng Kim Cương';
      if (t.contains('gold') || t.contains('vàng')) return 'Hạng Vàng';
      if (t.contains('silver') || t.contains('bạc')) return 'Hạng Bạc';
      if (t.contains('bronze') || t.contains('đồng')) return 'Hạng Đồng';
    }
    if (points >= 15000) return 'Hạng Kim Cương';
    if (points >= 5000) return 'Hạng Vàng';
    if (points >= 1000) return 'Hạng Bạc';
    return 'Hạng Đồng';
  }

  String get nextTierName {
    if (points >= 15000) return 'Tối Cao';
    if (points >= 5000) return 'Kim Cương';
    if (points >= 1000) return 'Vàng';
    return 'Bạc';
  }

  int get nextTierMilestone {
    if (points >= 15000) return 15000;
    if (points >= 5000) return 15000;
    if (points >= 1000) return 5000;
    return 1000;
  }

  int get currentTierMinPoints {
    if (points >= 15000) return 15000;
    if (points >= 5000) return 5000;
    if (points >= 1000) return 1000;
    return 0;
  }

  double get tierProgress {
    if (points >= 15000) return 1.0;
    final minP = currentTierMinPoints;
    final maxP = nextTierMilestone;
    final range = maxP - minP;
    if (range <= 0) return 1.0;
    return ((points - minP) / range).clamp(0.0, 1.0);
  }

  int get pointsNeededForNextTier {
    if (points >= 15000) return 0;
    return (nextTierMilestone - points).clamp(0, 999999);
  }
}
