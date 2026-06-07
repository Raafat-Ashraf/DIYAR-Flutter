import 'package:dio/dio.dart';

class LoginRequestModel {
  const LoginRequestModel({required this.email, required this.password});

  final String email;
  final String password;

  FormData toFormData() => FormData.fromMap({
        'Email': email,
        'Password': password,
      });
}

class RegisterRequestModel {
  const RegisterRequestModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;

  FormData toFormData() => FormData.fromMap({
        'FirstName': firstName,
        'LastName': lastName,
        'Email': email,
        'PhoneNumber': phoneNumber,
        'Password': password,
        'ConfirmPassword': confirmPassword,
      });
}
