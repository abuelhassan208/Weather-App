import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import 'interceptors/api_logging_interceptor.dart';

class DioClient {
  DioClient({AppLogger logger = const NoopAppLogger()})
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          sendTimeout: ApiConstants.sendTimeout,
          responseType: ResponseType.json,
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      ApiLoggingInterceptor(logger: logger, mapException: mapDioException),
    );
  }

  final Dio dio;

  AppException mapDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _mapStatusCode(exception.response?.statusCode);

      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const UnknownException();
    }
  }

  AppException _mapStatusCode(int? statusCode) {
    if (statusCode != null && statusCode >= 500 && statusCode <= 599) {
      return const ServerException();
    }

    switch (statusCode) {
      case 400:
        return const BadRequestException();
      case 401:
      case 403:
        return const UnauthorizedException();
      case 404:
        return const NotFoundException();
      default:
        return const UnknownException();
    }
  }
}
