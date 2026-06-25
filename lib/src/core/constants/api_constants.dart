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
  static const getPendingUsersCount = '/api/Users/GetPendingUsersCount';
  static const changeUserVerificationStatus =
      '/api/Users/ChangeUserVerificationStatus';
  static const getAllSpecializations = '/api/Specializations/GetAll';
  static const getAllMeasurementUnits =
      '/api/Specializations/GetAllMeasurementUnits';
  static const createSpecialization = '/api/Specializations/Create';
  static const updateSpecialization = '/api/Specializations/Update';
  static const toggleDeleteSpecialization = '/api/Specializations/ToggleDelete';
  static const createShowcase = '/api/Showcases/Create';
  static const getAllShowcases = '/api/Showcases/GetAll';
  static const updateShowcase = '/api/Showcases/Update';
  static const deleteShowcase = '/api/Showcases/Delete';
  static const toggleShowcaseOpen = '/api/Showcases/ToggleOpen';
  static const createRequest = '/api/Requests/Create';
  static const getAllRequests = '/api/Requests/GetAll';
  static const getRequestById = '/api/Requests/GetById';
  static const requestChartData = '/api/Requests/GetChartData';
  static const addRequestComment = '/api/Requests/AddComment';
  static const acceptQuotation = '/api/Requests/AcceptQuotation';

  static const getAllQuotations = '/api/Quotations/GetAll';
  static const createQuotation = '/api/Quotations/Create';
  static const cancelQuotation = '/api/Quotations/Cancel';
  static const quotationChartData = '/api/Quotations/GetChartData';
  static const rejectQuotation = '/api/Quotations/Reject';
  static const cancelRequest = '/api/Requests/Cancel';
  static const broadcastNotification = '/api/Notifications/Broadcast';
  static const searchUsers = '/api/Users/Search';
  static const getUserProfile = '/api/Account/PublicProfile';
  static const updateProfile = '/api/Account/UpdateProfile';
  static const updateWorkCities = '/api/Account/UpdateWorkCities';
  static const updateSpecializations = '/api/Account/UpdateSpecializations';
  static const changePassword = '/api/Account/ChangePassword';

  static const getUserRatings = '/api/UserRatings/GetUserRatings';
  static const rateUser = '/api/UserRatings/Rate';
  static const deleteRating = '/api/UserRatings/DeleteRating';

  static const registerDeviceToken = '/api/Account/RegisterDeviceToken';
  static const getAllNotifications = '/api/Notifications/GetAll';
  static const unreadNotificationsCount = '/api/Notifications/UnreadCount';
  static const markNotificationRead = '/api/Notifications/MarkAsRead';
}
