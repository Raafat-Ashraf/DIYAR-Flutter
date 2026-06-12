class ApiConstants {
  const ApiConstants._();

  static const baseUrl = 'https://diyar.runasp.net/';

  static const login = '/api/Auth/Login';
  static const register = '/api/Auth/Register';
  static const confirmEmail = '/api/Auth/ConfirmEmail';
  static const resendConfirmationEmail = '/api/Auth/ResendConfirmationEmail';
  static const forgetPassword = '/api/Auth/ForgetPassword';
  static const resetPassword = '/api/Auth/ResetPassword';
  static const googleLogin = '/api/Auth/GoogleLogin';
  static const accountProfile = '/api/Account/Profile';
  static const verifyAccount = '/api/Account/VerifyAccount';
  static const governorates = '/api/Governorates/GetAll';
  static const governorateById = '/api/Governorates/Get';
  static const getAllPendingUsers = '/api/Users/GetAllPendingUsers';
  static const changeUserVerificationStatus =
      '/api/Users/ChangeUserVerevecationStatus';
  static const getAllSpecializations = '/api/Specializations/GetAll';
  static const getAllMeasurementUnits =
      '/api/Specializations/GetAllMeasurementUnits';
  static const createSpecialization = '/api/Specializations/Create';
  static const updateSpecialization = '/api/Specializations/Update';
  static const toggleDeleteSpecialization = '/api/Specializations/ToggleDelete';
}
