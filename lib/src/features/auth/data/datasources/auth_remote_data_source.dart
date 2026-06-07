import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/backend_message_translator.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_user.dart';
import '../models/auth_request_models.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUser> login(LoginRequestModel request);
  Future<String> register(RegisterRequestModel request);
  Future<String> confirmEmail(String email, String otp);
  Future<String> resendConfirmationEmail(String email);
  Future<String> forgotPassword(String email);
  Future<String> resetPassword(String email, String otp, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuthUser> login(LoginRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: request.toFormData(),
    );
    return AuthUser.fromJson(response);
  }

  @override
  Future<String> register(RegisterRequestModel request) async {
    final message = await _client.post<String>(
      ApiConstants.register,
      data: request.toFormData(),
    );
    return BackendMessageTranslator.translate(message);
  }

  @override
  Future<String> confirmEmail(String email, String otp) async {
    final message = await _client.post<String>(
      ApiConstants.confirmEmail,
      data: {'email': email, 'otp': otp},
    );
    return BackendMessageTranslator.translate(message);
  }

  @override
  Future<String> resendConfirmationEmail(String email) async {
    final message = await _client.post<String>(
      ApiConstants.resendConfirmationEmail,
      data: {'email': email},
    );
    return BackendMessageTranslator.translate(message);
  }

  @override
  Future<String> forgotPassword(String email) async {
    final message = await _client.post<String>(
      ApiConstants.forgetPassword,
      data: {'email': email},
    );
    return BackendMessageTranslator.translate(message);
  }

  @override
  Future<String> resetPassword(String email, String otp, String newPassword) async {
    final message = await _client.post<String>(
      ApiConstants.resetPassword,
      data: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
    return BackendMessageTranslator.translate(message);
  }
}
