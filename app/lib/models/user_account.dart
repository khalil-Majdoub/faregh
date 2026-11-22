enum UserRole {
  user,
  society,
}

class UserAccount {
  final String id;
  final String fullName;
  final String email;
  final String password;
  final UserRole role;
  final String city;

  /// If [role] == [UserRole.society], links this account to its [SocietyPlace.id].
  final String? societyPlaceId;

  const UserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.city = 'Sousse',
    this.societyPlaceId,
  });

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'User';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role.name,
      'city': city,
      'societyPlaceId': societyPlaceId,
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String? ?? 'user';
    final parsedRole = UserRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => UserRole.user,
    );

    return UserAccount(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: parsedRole,
      city: json['city'] as String? ?? 'Sousse',
      societyPlaceId: json['societyPlaceId'] as String?,
    );
  }
}
