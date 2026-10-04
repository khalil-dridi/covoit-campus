class User {
  final int? id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String? phone;
  final String? profileImage;
  final String? university;
  final String role;
  final bool isVerified;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    this.phone,
    this.profileImage,
    this.university,
    this.role = 'passenger',
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'phone': phone,
      'profile_image': profileImage,
      'university': university,
      'role': role,
      'is_verified': isVerified ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      phone: map['phone'] as String?,
      profileImage: map['profile_image'] as String?,
      university: map['university'] as String?,
      role: map['role'] as String,
      isVerified: map['is_verified'] == 1,
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}   