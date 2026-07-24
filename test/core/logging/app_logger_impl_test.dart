import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/logging/app_log_level.dart';
import 'package:weather_app/core/logging/app_logger_impl.dart';

void main() {
  test('writes all enabled levels with context, error, and stack trace', () {
    final records = <AppLogRecord>[];
    final stackTrace = StackTrace.current;
    final logger = AppLoggerImpl(
      minimumLevel: AppLogLevel.trace,
      writer: records.add,
    );

    logger.trace('trace', context: const {'value': 1});
    logger.debug('debug');
    logger.info('info');
    logger.warning('warning');
    logger.error('error', error: StateError('failed'), stackTrace: stackTrace);

    expect(records.map((record) => record.level), AppLogLevel.values);
    expect(records.first.context, {'value': 1});
    expect(records.last.error, contains('failed'));
    expect(records.last.stackTrace, same(stackTrace));
  });

  test('release-style minimum level suppresses verbose records', () {
    final records = <AppLogRecord>[];
    final logger = AppLoggerImpl(
      minimumLevel: AppLogLevel.warning,
      writer: records.add,
    );

    logger
      ..trace('trace')
      ..debug('debug')
      ..info('info')
      ..warning('warning')
      ..error('error');

    expect(records.map((record) => record.level), [
      AppLogLevel.warning,
      AppLogLevel.error,
    ]);
  });

  test('sanitizes messages, context, and errors before writing', () {
    final records = <AppLogRecord>[];
    final logger = AppLoggerImpl(
      minimumLevel: AppLogLevel.trace,
      writer: records.add,
    );

    logger.error(
      'request key=message-secret',
      error: StateError('Bearer error-secret'),
      context: const {'Authorization': 'context-secret'},
    );

    final serialized = [
      records.single.message,
      records.single.context,
      records.single.error,
    ].join(' ');
    expect(serialized, isNot(contains('message-secret')));
    expect(serialized, isNot(contains('error-secret')));
    expect(serialized, isNot(contains('context-secret')));
  });

  test('a failing writer never escapes into application code', () {
    final logger = AppLoggerImpl(
      minimumLevel: AppLogLevel.trace,
      writer: (_) => throw StateError('backend failed'),
    );

    expect(() => logger.error('application error'), returnsNormally);
  });
}
