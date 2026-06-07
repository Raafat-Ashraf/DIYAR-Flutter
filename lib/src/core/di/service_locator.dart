import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/account/data/datasources/account_remote_data_source.dart';
import '../../features/account/data/repositories/account_repository_impl.dart';
import '../../features/account/domain/repositories/account_repository.dart';
import '../../features/account/domain/usecases/clear_cached_account_profile_use_case.dart';
import '../../features/account/domain/usecases/get_account_profile_use_case.dart';
import '../../features/account/domain/usecases/get_cached_account_profile_use_case.dart';
import '../../features/account/domain/usecases/get_governorates_use_case.dart';
import '../../features/account/domain/usecases/verify_account_use_case.dart';
import '../../features/account/presentation/cubit/account_cubit.dart';
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
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../storage/session_storage.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt
    ..registerLazySingleton(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
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
    ..registerFactory(() => VerifyAccountUseCase(getIt()))
    ..registerFactory(() => ClearCachedAccountProfileUseCase(getIt()))
    ..registerLazySingleton(
      () => AccountCubit(
        getCachedProfile: getIt(),
        getProfile: getIt(),
        getGovernorates: getIt(),
        verifyAccount: getIt(),
        clearCachedProfile: getIt(),
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
