import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.emailVerifiedAt,
    required this.createdAt,
  });

  bool get isEmailVerified => emailVerifiedAt != null;

  @override
  List<Object?> get props => [id, email, name, emailVerifiedAt, createdAt];
}
