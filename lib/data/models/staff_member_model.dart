class StaffMemberModel {
  final String id;
  final String fullName;
  final String phone;
  final String role; // 'Admin' | 'Manager' | 'Staff'
  final String branchName; // Chi nhánh liên kết (e.g. 'Quận 1', 'Quận 3')
  final String createdAt;

  const StaffMemberModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.branchName,
    required this.createdAt,
  });

  StaffMemberModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? role,
    String? branchName,
    String? createdAt,
  }) {
    return StaffMemberModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      branchName: branchName ?? this.branchName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    return StaffMemberModel(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      fullName: (json['fullName'] ?? json['FullName'])?.toString() ?? '',
      phone: (json['phone'] ?? json['Phone'] ?? json['phoneNumber'] ?? json['PhoneNumber'])?.toString() ?? '',
      role: (json['role'] ?? json['Role'])?.toString() ?? 'Staff',
      branchName: (json['branchName'] ?? json['BranchName'])?.toString() ?? 'Quận 1',
      createdAt: (json['createdAt'] ?? json['CreatedAt'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'role': role,
        'branchName': branchName,
        'createdAt': createdAt,
      };
}
