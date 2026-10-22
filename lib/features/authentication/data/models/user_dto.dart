import '../../domain/models/user.dart';

class UserDto {
  final String id;
  final String email;
  final String name;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;

  UserDto({
    required this.id,
    required this.email,
    required this.name,
    this.emailVerifiedAt,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.parse(json['emailVerifiedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  User toDomain() {
    return User(
      id: id,
      email: email,
      name: name,
      emailVerifiedAt: emailVerifiedAt,
      createdAt: createdAt,
    );
  }
}
