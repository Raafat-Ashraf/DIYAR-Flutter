import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import '../errors/error_mapper.dart';

class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(message: 'استجابة غير متوقعة من الخادم.');
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    } catch (_) {
      throw const AppFailure(message: 'استجابة غير متوقعة من الخادم.');
    }
  }

  Future<T?> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(message: 'استجابة غير متوقعة من الخادم.');
    }
  }
}
