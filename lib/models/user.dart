enum UserRole { admin, uye }

class User {
  final String id;
  final String name;
  final String username;
  final String password;
  final String? phone;
  final String? email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final String? profileImage;
  final bool isGuest; // Üyeliksiz giriş

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.phone,
    this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.profileImage,
    this.isGuest = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'phone': phone,
      'email': email,
      'role': role.toString(),
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'profileImage': profileImage,
      'isGuest': isGuest,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      password: map['password'],
      phone: map['phone'],
      email: map['email'],
      role: UserRole.values.firstWhere((e) => e.toString() == map['role']),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      profileImage: map['profileImage'],
      isGuest: map['isGuest'] ?? false,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
    String? phone,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    String? profileImage,
    bool? isGuest,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      profileImage: profileImage ?? this.profileImage,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => toMap();
  
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);
}
