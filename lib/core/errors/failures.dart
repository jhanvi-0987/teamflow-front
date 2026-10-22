import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network connection failed. Please check your internet connectivity.',
    super.code = 'NETWORK_ERROR',
  });
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Unable to read or write local cache.',
    super.code = 'CACHE_ERROR',
  });
}

class WorkspaceFailure extends Failure {
  const WorkspaceFailure({required super.message, super.code});
}
