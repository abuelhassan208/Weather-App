import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/errors/app_exception.dart';
import 'package:weather_app/core/network/dio_client.dart';

void main() {
  group('DioClient.mapDioException', () {
    late DioClient client;

    setUp(() => client = DioClient());

    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      test('$type maps to TimeoutException', () {
        final result = client.mapDioException(_exception(type: type));

        expect(result, isA<TimeoutException>());
        expect(result, isNot(isA<DioException>()));
      });
    }

    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.badCertificate,
    ]) {
      test('$type maps to NetworkException', () {
        final result = client.mapDioException(_exception(type: type));

        expect(result, isA<NetworkException>());
        expect(result, isNot(isA<DioException>()));
      });
    }

    for (final type in [DioExceptionType.cancel, DioExceptionType.unknown]) {
      test('$type maps to UnknownException', () {
        final result = client.mapDioException(
          _exception(type: type, error: StateError('transport failure')),
        );

        expect(result, isA<UnknownException>());
        expect(result, isNot(isA<DioException>()));
      });
    }

    final statusCases = <int, Type>{
      400: BadRequestException,
      401: UnauthorizedException,
      403: UnauthorizedException,
      404: NotFoundException,
      500: ServerException,
      502: ServerException,
      503: ServerException,
      599: ServerException,
      418: UnknownException,
    };

    for (final entry in statusCases.entries) {
      test('badResponse ${entry.key} maps to ${entry.value}', () {
        final result = client.mapDioException(
          _exception(
            type: DioExceptionType.badResponse,
            statusCode: entry.key,
            includeResponse: true,
          ),
        );

        expect(result.runtimeType, entry.value);
        expect(result, isNot(isA<DioException>()));
      });
    }

    test('badResponse with a null status maps to UnknownException', () {
      final result = client.mapDioException(
        _exception(type: DioExceptionType.badResponse, includeResponse: true),
      );

      expect(result, isA<UnknownException>());
    });

    test('badResponse without a response maps to UnknownException', () {
      final result = client.mapDioException(
        _exception(type: DioExceptionType.badResponse),
      );

      expect(result, isA<UnknownException>());
    });

    test('exception type takes precedence over attached response status', () {
      final result = client.mapDioException(
        _exception(
          type: DioExceptionType.receiveTimeout,
          statusCode: 500,
          includeResponse: true,
        ),
      );

      expect(result, isA<TimeoutException>());
    });
  });
}

DioException _exception({
  required DioExceptionType type,
  int? statusCode,
  bool includeResponse = false,
  Object? error,
}) {
  final requestOptions = RequestOptions(path: '/current.json');

  return DioException(
    requestOptions: requestOptions,
    type: type,
    error: error,
    response: includeResponse
        ? Response<Object?>(
            requestOptions: requestOptions,
            statusCode: statusCode,
          )
        : null,
  );
}
