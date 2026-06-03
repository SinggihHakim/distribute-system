/// Model untuk data pengguna (Admin & Driver)
class UserModel {
  final String id;
  final String authId;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'admin' | 'driver'
  final bool isActive;
  final DateTime createdAt;
  final String? storeId;

  const UserModel({
    required this.id,
    required this.authId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.storeId,
  });

  bool get isAdmin => role == 'admin';
  bool get isDriver => role == 'driver';

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      authId: map['auth_id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      role: map['role'] as String,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      storeId: map['store_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_id': authId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'store_id': storeId,
    };
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: $role, storeId: $storeId)';
}
