import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';

class DioClient {
  DioClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          sendTimeout: ApiConstants.sendTimeout,
          responseType: ResponseType.json,
          headers: const {'Accept': 'application/json'},
        ),
      );

  final Dio dio;

  AppException mapDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _mapStatusCode(exception.response?.statusCode);

      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const UnknownException();
    }
  }

  AppException _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return const BadRequestException();
      case 401:
      case 403:
        return const UnauthorizedException();
      case 404:
        return const NotFoundException();
      case 500:
      case 502:
      case 503:
      case 504:
        return const ServerException();
      default:
        return const UnknownException();
    }
  }
}
