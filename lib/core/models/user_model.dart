// Removed Firebase dependency - using Supabase now

enum UserRole { admin, staff }

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String? fcmToken;
  final int? age;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? department;
  final String? position;
  final DateTime? dateOfBirth;
  final String? emergencyContact;
  final String? emergencyPhone;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.fcmToken,
    this.age,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.department,
    this.position,
    this.dateOfBirth,
    this.emergencyContact,
    this.emergencyPhone,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Helper function to get value with both camelCase and snake_case support
    String getString(String camelCase, String snakeCase, {String defaultValue = ''}) {
      return map[snakeCase]?.toString() ?? map[camelCase]?.toString() ?? defaultValue;
    }

    DateTime? getDateTime(String camelCase, String snakeCase) {
      final value = map[snakeCase] ?? map[camelCase];
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    return UserModel(
      id: getString('id', 'id'),
      email: getString('email', 'email'),
      name: getString('name', 'name'),
      phoneNumber: getString('phoneNumber', 'phone_number'),
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role']?.toString() ?? 'staff'),
        orElse: () => UserRole.staff,
      ),
      profileImageUrl: map['profile_image_url'] ?? map['profileImageUrl'],
      createdAt: getDateTime('createdAt', 'created_at') ?? DateTime.now(),
      lastLoginAt: getDateTime('lastLoginAt', 'last_login_at'),
      isActive: map['is_active'] ?? map['isActive'] ?? true,
      fcmToken: map['fcm_token'] ?? map['fcmToken'],
      age: map['age'] is int ? map['age'] : (map['age'] != null ? int.tryParse(map['age'].toString()) : null),
      address: map['address'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zip_code'] ?? map['zipCode'],
      department: map['department'],
      position: map['position'],
      dateOfBirth: getDateTime('dateOfBirth', 'date_of_birth'),
      emergencyContact: map['emergency_contact'] ?? map['emergencyContact'],
      emergencyPhone: map['emergency_phone'] ?? map['emergencyPhone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'role': role.name,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
      'fcm_token': fcmToken,
      'age': age,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'department': department,
      'position': position,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    UserRole? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? fcmToken,
    int? age,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? department,
    String? position,
    DateTime? dateOfBirth,
    String? emergencyContact,
    String? emergencyPhone,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      age: age ?? this.age,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      department: department ?? this.department,
      position: position ?? this.position,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
}

