import 'package:dio/dio.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../errors/error_mapper.dart';

class BanInterceptor extends Interceptor {
  BanInterceptor(this._getAuthBloc);

  final AuthBloc Function() _getAuthBloc;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 403) {
      final failure = ErrorMapper.fromResponseBody(err.response?.data, 403);
      if (failure?.code == 'User.Banned') {
        final msg = failure?.message ?? 'تم حظر هذا الحساب. يرجى التواصل مع المسؤول.';
        _getAuthBloc().add(AuthBanDetected(message: msg));
      }
    }
    handler.next(err);
  }
}
