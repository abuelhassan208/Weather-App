import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/logging/app_logger.dart';
import 'package:weather_app/core/observers/app_bloc_observer.dart';

void main() {
  late BlocObserver previousObserver;

  setUp(() => previousObserver = Bloc.observer);
  tearDown(() => Bloc.observer = previousObserver);

  test('records create, event, transition, error, and close', () async {
    final logger = _RecordingLogger();
    Bloc.observer = AppBlocObserver(logger: logger);
    final bloc = _TestBloc();

    bloc.add(const _Increment());
    await bloc.stream.firstWhere((state) => state == 1);
    bloc.reportError(StateError('test failure'), StackTrace.current);
    await bloc.close();

    expect(logger.messages, contains('BLoC created'));
    expect(logger.messages, contains('BLoC event received'));
    expect(logger.messages, contains('BLoC transition'));
    expect(logger.messages, isNot(contains('BLoC state changed')));
    expect(logger.messages, contains('BLoC error'));
    expect(logger.messages, contains('BLoC closed'));
    expect(logger.contexts, contains(containsPair('eventType', '_Increment')));
    expect(logger.errors.single, isA<StateError>());
    expect(logger.stackTraces.single, isNotNull);
  });

  test('records Cubit changes without requiring events', () async {
    final logger = _RecordingLogger();
    Bloc.observer = AppBlocObserver(logger: logger);
    final cubit = _TestCubit();

    cubit.increment();
    await cubit.close();

    expect(logger.messages, contains('BLoC state changed'));
    expect(
      logger.contexts,
      contains(
        allOf(
          containsPair('blocType', '_TestCubit'),
          containsPair('currentStateType', 'int'),
          containsPair('nextStateType', 'int'),
        ),
      ),
    );
  });

  test('does not log secret event fields or change bloc behavior', () async {
    final logger = _RecordingLogger();
    Bloc.observer = AppBlocObserver(logger: logger);
    final bloc = _TestBloc();

    bloc.add(const _SecretEvent('do-not-log-this-token'));
    final state = await bloc.stream.first;
    await bloc.close();

    expect(state, 1);
    expect(logger.serialized, isNot(contains('do-not-log-this-token')));
    expect(logger.serialized, contains('_SecretEvent'));
  });

  test('a failing logger does not alter bloc behavior', () async {
    Bloc.observer = const AppBlocObserver(logger: _ThrowingLogger());
    final bloc = _TestBloc();

    bloc.add(const _Increment());
    expect(await bloc.stream.first, 1);
    await expectLater(bloc.close(), completes);
  });
}

sealed class _TestEvent {
  const _TestEvent();
}

final class _Increment extends _TestEvent {
  const _Increment();
}

final class _SecretEvent extends _TestEvent {
  const _SecretEvent(this.secret);

  final String secret;
}

final class _TestBloc extends Bloc<_TestEvent, int> {
  _TestBloc() : super(0) {
    on<_TestEvent>((event, emit) => emit(state + 1));
  }

  void reportError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);
  }
}

final class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);

  void increment() => emit(state + 1);
}

final class _RecordingLogger extends NoopAppLogger {
  final messages = <String>[];
  final contexts = <Map<String, Object?>>[];
  final errors = <Object?>[];
  final stackTraces = <StackTrace?>[];

  String get serialized => '$messages $contexts $errors';

  void _record(
    String message,
    Map<String, Object?> context, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
    contexts.add(context);
    if (error != null) {
      errors.add(error);
      stackTraces.add(stackTrace);
    }
  }

  @override
  void trace(String message, {Map<String, Object?> context = const {}}) {
    _record(message, context);
  }

  @override
  void debug(String message, {Map<String, Object?> context = const {}}) {
    _record(message, context);
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _record(message, context, error: error, stackTrace: stackTrace);
  }
}

final class _ThrowingLogger extends NoopAppLogger {
  const _ThrowingLogger();

  @override
  void debug(String message, {Map<String, Object?> context = const {}}) {
    throw StateError('logger failed');
  }

  @override
  void trace(String message, {Map<String, Object?> context = const {}}) {
    throw StateError('logger failed');
  }
}
