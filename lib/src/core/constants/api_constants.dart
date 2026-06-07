class ApiConstants {
  const ApiConstants._();

  static const baseUrl = 'https://diyar.runasp.net/';

  static const login = '/api/Auth/Login';
  static const register = '/api/Auth/Register';
  static const confirmEmail = '/api/Auth/ConfirmEmail';
  static const resendConfirmationEmail =
      '/api/Auth/ResendConfirmationEmail';
  static const forgetPassword = '/api/Auth/ForgetPassword';
  static const resetPassword = '/api/Auth/ResetPassword';
  static const googleLogin = '/api/Auth/GoogleLogin';
}
