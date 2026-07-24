import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../logging/app_logger.dart';
import '../../logging/log_sanitizer.dart';

typedef RequestIdFactory = String Function();
typedef UtcClock = DateTime Function();
typedef ExceptionMapper = Object Function(DioException exception);

final class ApiLoggingInterceptor extends Interceptor {
  ApiLoggingInterceptor({
    required this.logger,
    required this.mapException,
    this.sanitizer = const LogSanitizer(),
    this.includeBodies = kDebugMode,
    RequestIdFactory? requestIdFactory,
    UtcClock? now,
  }) : _requestIdFactory = requestIdFactory ?? _nextRequestId,
       _now = now ?? _utcNow;

  static const String _requestIdKey = 'app.logging.requestId';
  static const String _startedAtKey = 'app.logging.startedAt';
  static var _requestSequence = 0;

  final AppLogger logger;
  final ExceptionMapper mapException;
  final LogSanitizer sanitizer;
  final bool includeBodies;
  final RequestIdFactory _requestIdFactory;
  final UtcClock _now;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = _requestIdFactory();
    options.extra[_requestIdKey] = requestId;
    options.extra[_startedAtKey] = _now().toUtc().toIso8601String();

    _safeLog(() {
      logger.info(
        'API request started',
        context: {
          'requestId': requestId,
          'operation': _operationFor(options.path),
          'method': options.method,
          'path': _safePath(options),
          'queryParameterKeys': options.queryParameters.keys.toList(),
          'hasRequestBody': options.data != null,
          if (includeBodies) ...{
            'query': sanitizer.sanitize(options.queryParameters),
            'headers': sanitizer.sanitize(options.headers),
            if (options.data != null)
              'requestBody': sanitizer.encode(options.data),
          },
        },
      );
    });

    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;

    _safeLog(() {
      logger.info(
        'API response succeeded',
        context: {
          'requestId': options.extra[_requestIdKey] ?? 'unknown',
          'statusCode': response.statusCode,
          'durationMs': _durationInMilliseconds(options),
          'contentType': response.headers.value(Headers.contentTypeHeader),
          'approximateSize': _approximateSize(response.data),
          'summary': _weatherSummary(response.data),
          if (includeBodies)
            'responseBody': sanitizer.encode(response.data, maxLength: 4096),
        },
      );
    });

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;

    _safeLog(() {
      logger.warning(
        'API request failed',
        error: mapException(err),
        stackTrace: err.stackTrace,
        context: {
          'requestId': options.extra[_requestIdKey] ?? 'unknown',
          'exceptionType': err.type.name,
          'statusCode': err.response?.statusCode,
          'durationMs': _durationInMilliseconds(options),
          'path': _safePath(options),
          if (includeBodies && err.response?.data != null)
            'responseBody': sanitizer.encode(
              err.response?.data,
              maxLength: 4096,
            ),
        },
      );
    });

    handler.next(err);
  }

  int? _durationInMilliseconds(RequestOptions options) {
    final rawStartedAt = options.extra[_startedAtKey];
    final startedAt = rawStartedAt is String
        ? DateTime.tryParse(rawStartedAt)
        : null;
    return startedAt == null
        ? null
        : _now().toUtc().difference(startedAt).inMilliseconds;
  }

  String _safePath(RequestOptions options) {
    final path =
        Uri.tryParse(options.path)?.path ?? options.path.split('?').first;
    return path.startsWith('/') ? path : '/$path';
  }

  static String _operationFor(String path) =>
      path.contains('current') ? 'weather.fetchCurrent' : 'api.request';

  static int _approximateSize(Object? data) => data?.toString().length ?? 0;

  Object _weatherSummary(Object? data) {
    if (data is! Map) {
      return const {'payloadType': 'nonObject'};
    }

    final location = data['location'];
    final current = data['current'];
    final condition = current is Map ? current['condition'] : null;

    return sanitizer.sanitize({
          if (location is Map) 'location': location['name'],
          if (current is Map) 'temperature': current['temp_c'],
          if (condition is Map) 'condition': condition['text'],
        }) ??
        const {};
  }

  void _safeLog(void Function() log) {
    try {
      log();
    } catch (_) {
      // A logging backend must not alter the Dio interceptor chain.
    }
  }

  static String _nextRequestId() {
    _requestSequence++;
    return '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestSequence';
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
