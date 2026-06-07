import 'package:equatable/equatable.dart';

class AppFailure extends Equatable implements Exception {
  const AppFailure({
    required this.message,
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];

  @override
  String toString() => message;
}
