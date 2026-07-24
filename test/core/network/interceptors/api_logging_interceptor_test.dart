import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/errors/app_exception.dart';
import 'package:weather_app/core/logging/app_logger.dart';
import 'package:weather_app/core/network/interceptors/api_logging_interceptor.dart';

void main() {
  test(
    'logs a sanitized request and response without changing either',
    () async {
      final logger = _RecordingLogger();
      final times = [
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 1, 0, 0, 0, 250),
      ].iterator;
      final dio = Dio();
      dio.interceptors.add(
        ApiLoggingInterceptor(
          logger: logger,
          mapException: (_) => const UnknownException(),
          includeBodies: true,
          requestIdFactory: () => 'request-1',
          now: () {
            times.moveNext();
            return times.current;
          },
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                headers: Headers.fromMap({
                  Headers.contentTypeHeader: ['application/json'],
                }),
                data: {
                  'location': {'name': 'Cairo'},
                  'current': {
                    'temp_c': 29,
                    'condition': {'text': 'Sunny'},
                    'secret': 'response-secret',
                  },
                },
              ),
              true,
            );
          },
        ),
      );

      final response = await dio.get<Object?>(
        '/v1/current.json',
        queryParameters: const {'key': 'api-secret', 'q': 'Cairo'},
        options: Options(
          headers: const {'Authorization': 'Bearer auth-secret'},
        ),
      );

      expect(response.statusCode, 200);
      expect(response.requestOptions.queryParameters['key'], 'api-secret');
      expect(logger.infos, hasLength(2));
      final logs = logger.infos.join(' ');
      expect(logs, contains('request-1'));
      expect(logs, contains('/v1/current.json'));
      expect(logs, contains('250'));
      expect(logs, contains('Cairo'));
      expect(logs, isNot(contains('api-secret')));
      expect(logs, isNot(contains('auth-secret')));
      expect(logs, isNot(contains('response-secret')));
    },
  );

  test('release-style logging omits request and response bodies', () async {
    final logger = _RecordingLogger();
    final dio = Dio();
    dio.interceptors.add(
      ApiLoggingInterceptor(
        logger: logger,
        mapException: (_) => const UnknownException(),
        includeBodies: false,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<Object?>(
            requestOptions: options,
            statusCode: 200,
            data: const {'secret': 'response-secret'},
          ),
          true,
        ),
      ),
    );

    await dio.post<Object?>(
      '/v1/current.json',
      data: const {'password': 'request-secret'},
    );

    final logs = logger.infos.join(' ');
    expect(logs, isNot(contains('requestBody')));
    expect(logs, isNot(contains('responseBody')));
    expect(logs, isNot(contains('request-secret')));
    expect(logs, isNot(contains('response-secret')));
  });

  for (final type in [
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.badResponse,
  ]) {
    test('logs and preserves $type errors', () async {
      final logger = _RecordingLogger();
      final dio = Dio();
      dio.interceptors.add(
        ApiLoggingInterceptor(
          logger: logger,
          mapException: (_) => const UnknownException(),
          includeBodies: true,
          requestIdFactory: () => 'failed-request',
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: type,
                response: type == DioExceptionType.badResponse
                    ? Response<Object?>(
                        requestOptions: options,
                        statusCode: 500,
                        data: const {'token': 'response-secret'},
                      )
                    : null,
              ),
              true,
            );
          },
        ),
      );

      await expectLater(
        dio.get<Object?>('/v1/current.json'),
        throwsA(
          isA<DioException>().having((error) => error.type, 'type', type),
        ),
      );

      expect(logger.warnings, hasLength(1));
      expect(logger.warnings.single, contains(type.name));
      expect(logger.warnings.single, isNot(contains('response-secret')));
    });
  }

  test('a failing logger does not interrupt the request', () async {
    final dio = Dio();
    dio.interceptors.add(
      ApiLoggingInterceptor(
        logger: _ThrowingLogger(),
        mapException: (_) => const UnknownException(),
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<Object?>(requestOptions: options, statusCode: 204),
          true,
        ),
      ),
    );

    final response = await dio.get<Object?>('/health');
    expect(response.statusCode, 204);
  });
}

class _RecordingLogger extends NoopAppLogger {
  final infos = <String>[];
  final warnings = <String>[];

  @override
  void info(String message, {Map<String, Object?> context = const {}}) {
    infos.add('$message $context');
  }

  @override
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    warnings.add('$message $error $context');
  }
}

class _ThrowingLogger extends NoopAppLogger {
  @override
  void info(String message, {Map<String, Object?> context = const {}}) {
    throw StateError('logger failed');
  }
}
