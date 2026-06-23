import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/account/data/datasources/account_remote_data_source.dart';
import '../../features/account/data/repositories/account_repository_impl.dart';
import '../../features/account/domain/repositories/account_repository.dart';
import '../../features/account/domain/usecases/clear_cached_account_profile_use_case.dart';
import '../../features/account/domain/usecases/get_account_profile_use_case.dart';
import '../../features/account/domain/usecases/get_cached_account_profile_use_case.dart';
import '../../features/account/domain/usecases/get_governorate_cities_use_case.dart';
import '../../features/account/domain/usecases/get_governorates_use_case.dart';
import '../../features/account/domain/usecases/verify_account_use_case.dart';
import '../../features/account/presentation/cubit/account_cubit.dart';
import '../../features/admin/data/datasources/admin_remote_data_source.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/domain/usecases/change_verification_status_use_case.dart';
import '../../features/admin/domain/usecases/get_pending_users_count_use_case.dart';
import '../../features/admin/domain/usecases/get_pending_users_use_case.dart';
import '../../features/admin/presentation/cubit/pending_verification_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/google_auth_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_session_use_case.dart';
import '../../features/auth/domain/usecases/confirm_email_use_case.dart';
import '../../features/auth/domain/usecases/forgot_password_use_case.dart';
import '../../features/auth/domain/usecases/get_saved_accounts_use_case.dart';
import '../../features/auth/domain/usecases/login_use_case.dart';
import '../../features/auth/domain/usecases/login_with_google_use_case.dart';
import '../../features/auth/domain/usecases/login_with_saved_account_use_case.dart';
import '../../features/auth/domain/usecases/logout_use_case.dart';
import '../../features/auth/domain/usecases/register_use_case.dart';
import '../../features/auth/domain/usecases/resend_confirmation_use_case.dart';
import '../../features/auth/domain/usecases/reset_password_use_case.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/requests/data/datasources/request_remote_data_source.dart';
import '../../features/requests/data/repositories/request_repository_impl.dart';
import '../../features/requests/domain/repositories/request_repository.dart';
import '../../features/requests/domain/usecases/add_comment_use_case.dart';
import '../../features/requests/domain/usecases/create_request_use_case.dart';
import '../../features/requests/domain/usecases/get_request_chart_data_use_case.dart';
import '../../features/requests/domain/usecases/get_request_by_id_use_case.dart';
import '../../features/requests/domain/usecases/get_requests_use_case.dart';
import '../../features/requests/presentation/cubit/create_request_cubit.dart';
import '../../features/requests/presentation/cubit/request_stats_cubit.dart';
import '../../features/requests/presentation/cubit/requests_cubit.dart';
import '../../features/showcases/data/datasources/showcase_remote_data_source.dart';
import '../../features/showcases/data/repositories/showcase_repository_impl.dart';
import '../../features/showcases/domain/repositories/showcase_repository.dart';
import '../../features/showcases/domain/usecases/create_showcase_use_case.dart';
import '../../features/showcases/domain/usecases/get_showcases_use_case.dart';
import '../../features/showcases/presentation/cubit/create_showcase_cubit.dart';
import '../../features/showcases/presentation/cubit/showcases_cubit.dart';
import '../../features/specializations/data/datasources/specialization_remote_data_source.dart';
import '../../features/specializations/data/repositories/specialization_repository_impl.dart';
import '../../features/specializations/domain/repositories/specialization_repository.dart';
import '../../features/specializations/domain/usecases/create_specialization_use_case.dart';
import '../../features/specializations/domain/usecases/get_measurement_units_use_case.dart';
import '../../features/specializations/domain/usecases/get_specializations_use_case.dart';
import '../../features/specializations/domain/usecases/toggle_specialization_delete_use_case.dart';
import '../../features/specializations/domain/usecases/update_specialization_use_case.dart';
import '../../features/specializations/presentation/admin/cubit/admin_specializations_cubit.dart';
import '../../features/notifications/data/datasources/notification_remote_data_source.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/quotations/data/datasources/quotation_remote_data_source.dart';
import '../../features/quotations/data/repositories/quotation_repository_impl.dart';
import '../../features/quotations/domain/repositories/quotation_repository.dart';
import '../../features/quotations/domain/usecases/accept_quotation_use_case.dart';
import '../../features/quotations/domain/usecases/cancel_quotation_use_case.dart';
import '../../features/quotations/domain/usecases/create_quotation_use_case.dart';
import '../../features/quotations/domain/usecases/get_quotations_use_case.dart';
import '../../features/quotations/presentation/cubit/create_quotation_cubit.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../services/fcm_service.dart';
import '../services/signalr_service.dart';
import '../storage/session_storage.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt
    ..registerLazySingleton(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          resetOnError: true,
        ),
      ),
    )
    ..registerLazySingleton(() => SessionStorage(getIt()))
    ..registerLazySingleton(() {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        ),
      );
      dio.interceptors.add(AuthInterceptor(getIt()));
      return dio;
    })
    ..registerLazySingleton(() => ApiClient(getIt()))
    ..registerLazySingleton<AccountRemoteDataSource>(
      () => AccountRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(getIt(), getIt()),
    )
    ..registerFactory(() => GetCachedAccountProfileUseCase(getIt()))
    ..registerFactory(() => GetAccountProfileUseCase(getIt()))
    ..registerFactory(() => GetGovernoratesUseCase(getIt()))
    ..registerFactory(() => GetGovernorateCitiesUseCase(getIt()))
    ..registerFactory(() => VerifyAccountUseCase(getIt()))
    ..registerFactory(() => ClearCachedAccountProfileUseCase(getIt()))
    ..registerLazySingleton(
      () => AccountCubit(
        getCachedProfile: getIt(),
        getProfile: getIt(),
        getGovernorates: getIt(),
        getGovernorateCities: getIt(),
        getSpecializations: getIt(),
        verifyAccount: getIt(),
        clearCachedProfile: getIt(),
      ),
    )
    ..registerLazySingleton<AdminRemoteDataSource>(
      () => AdminRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AdminRepository>(
      () => AdminRepositoryImpl(getIt()),
    )
    ..registerFactory(() => GetPendingUsersUseCase(getIt()))
    ..registerFactory(() => GetPendingUsersCountUseCase(getIt()))
    ..registerFactory(() => ChangeVerificationStatusUseCase(getIt()))
    ..registerFactory(
      () => PendingVerificationCubit(
        getPendingUsers: getIt(),
        getPendingUsersCount: getIt(),
        changeVerificationStatus: getIt(),
      ),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton(GoogleAuthService.new)
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => CheckSessionUseCase(getIt()))
    ..registerFactory(() => GetSavedAccountsUseCase(getIt()))
    ..registerFactory(() => LoginUseCase(getIt()))
    ..registerFactory(() => LoginWithSavedAccountUseCase(getIt()))
    ..registerFactory(() => LoginWithGoogleUseCase(getIt()))
    ..registerFactory(() => RegisterUseCase(getIt()))
    ..registerFactory(() => ConfirmEmailUseCase(getIt()))
    ..registerFactory(() => ResendConfirmationUseCase(getIt()))
    ..registerFactory(() => ForgotPasswordUseCase(getIt()))
    ..registerFactory(() => ResetPasswordUseCase(getIt()))
    ..registerFactory(() => LogoutUseCase(getIt()))
    ..registerLazySingleton<SpecializationRemoteDataSource>(
      () => SpecializationRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<SpecializationRepository>(
      () => SpecializationRepositoryImpl(getIt()),
    )
    ..registerFactory(() => GetSpecializationsUseCase(getIt()))
    ..registerFactory(() => GetMeasurementUnitsUseCase(getIt()))
    ..registerFactory(() => CreateSpecializationUseCase(getIt()))
    ..registerFactory(() => UpdateSpecializationUseCase(getIt()))
    ..registerFactory(() => ToggleSpecializationDeleteUseCase(getIt()))
    ..registerFactory(
      () => AdminSpecializationsCubit(
        getSpecializations: getIt(),
        getMeasurementUnits: getIt(),
        createSpecialization: getIt(),
        updateSpecialization: getIt(),
        toggleSpecializationDelete: getIt(),
      ),
    )
    ..registerLazySingleton<ShowcaseRemoteDataSource>(
      () => ShowcaseRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ShowcaseRepository>(
      () => ShowcaseRepositoryImpl(getIt()),
    )
    ..registerFactory(() => CreateShowcaseUseCase(getIt()))
    ..registerFactory(() => GetShowcasesUseCase(getIt()))
    ..registerFactory(() => CreateShowcaseCubit(createShowcase: getIt()))
    ..registerFactory(() => ShowcasesCubit(getShowcases: getIt()))
    ..registerLazySingleton<RequestRemoteDataSource>(
      () => RequestRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<RequestRepository>(
      () => RequestRepositoryImpl(getIt()),
    )
    ..registerFactory(() => GetRequestsUseCase(getIt()))
    ..registerFactory(() => GetRequestByIdUseCase(getIt()))
    ..registerFactory(() => CreateRequestUseCase(getIt()))
    ..registerFactory(() => GetRequestChartDataUseCase(getIt()))
    ..registerFactory(() => AddCommentUseCase(getIt()))
    ..registerFactory(() => RequestsCubit(getRequests: getIt()))
    ..registerFactory(() => RequestStatsCubit(getChartData: getIt()))
    ..registerFactory(
      () => CreateRequestCubit(
        createRequest: getIt(),
        getSpecializations: getIt(),
        getGovernorates: getIt(),
        getGovernorateCities: getIt(),
      ),
    )
    ..registerLazySingleton(() => SignalRService(getIt()))
    ..registerLazySingleton(() => FcmService(getIt()))
    ..registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton(
      () => NotificationsCubit(
        dataSource: getIt(),
        signalRService: getIt(),
      ),
    )
    ..registerLazySingleton<QuotationRemoteDataSource>(
      () => QuotationRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<QuotationRepository>(
      () => QuotationRepositoryImpl(getIt()),
    )
    ..registerFactory(() => GetQuotationsUseCase(getIt()))
    ..registerFactory(() => CreateQuotationUseCase(getIt()))
    ..registerFactory(() => CancelQuotationUseCase(getIt()))
    ..registerFactory(() => AcceptQuotationUseCase(getIt()))
    ..registerFactory(() => CreateQuotationCubit(createQuotation: getIt()))
    ..registerLazySingleton(
      () => AuthBloc(
        checkSession: getIt(),
        getSavedAccounts: getIt(),
        login: getIt(),
        loginWithSavedAccount: getIt(),
        loginWithGoogle: getIt(),
        register: getIt(),
        confirmEmail: getIt(),
        resendConfirmation: getIt(),
        forgotPassword: getIt(),
        resetPassword: getIt(),
        logout: getIt(),
      ),
    );
}
