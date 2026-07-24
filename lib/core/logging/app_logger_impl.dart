import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'app_log_level.dart';
import 'app_logger.dart';
import 'log_sanitizer.dart';

typedef AppLogWriter = void Function(AppLogRecord record);

final class AppLogRecord {
  const AppLogRecord({
    required this.level,
    required this.message,
    required this.context,
    this.error,
    this.stackTrace,
  });

  final AppLogLevel level;
  final String message;
  final Map<String, Object?> context;
  final Object? error;
  final StackTrace? stackTrace;
}

final class AppLoggerImpl implements AppLogger {
  AppLoggerImpl({
    AppLogLevel? minimumLevel,
    this._sanitizer = const LogSanitizer(),
    AppLogWriter? writer,
  }) : minimumLevel =
           minimumLevel ??
           (kReleaseMode ? AppLogLevel.warning : AppLogLevel.trace),
       _writer = writer ?? _writeToDeveloperLog;

  final AppLogLevel minimumLevel;
  final LogSanitizer _sanitizer;
  final AppLogWriter _writer;

  @override
  void trace(String message, {Map<String, Object?> context = const {}}) {
    _log(AppLogLevel.trace, message, context: context);
  }

  @override
  void debug(String message, {Map<String, Object?> context = const {}}) {
    _log(AppLogLevel.debug, message, context: context);
  }

  @override
  void info(String message, {Map<String, Object?> context = const {}}) {
    _log(AppLogLevel.info, message, context: context);
  }

  @override
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _log(
      AppLogLevel.warning,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _log(
      AppLogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  void _log(
    AppLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    if (!minimumLevel.allows(level)) {
      return;
    }

    try {
      _writer(
        AppLogRecord(
          level: level,
          message: _sanitizer.sanitizeText(message),
          context: _sanitizer.sanitizeMap(context),
          error: _sanitizer.sanitize(error),
          stackTrace: stackTrace,
        ),
      );
    } catch (_) {
      // Logging is observational and must never affect application behavior.
    }
  }

  static void _writeToDeveloperLog(AppLogRecord record) {
    developer.log(
      record.context.isEmpty
          ? record.message
          : '${record.message} ${record.context}',
      name: 'weather_app.${record.level.name}',
      level: _developerLevel(record.level),
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }

  static int _developerLevel(AppLogLevel level) => switch (level) {
    AppLogLevel.trace => 300,
    AppLogLevel.debug => 500,
    AppLogLevel.info => 800,
    AppLogLevel.warning => 900,
    AppLogLevel.error => 1000,
  };
}
