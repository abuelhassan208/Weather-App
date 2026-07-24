import 'package:flutter_bloc/flutter_bloc.dart';

import '../logging/app_logger.dart';

final class AppBlocObserver extends BlocObserver {
  const AppBlocObserver({required this.logger});

  final AppLogger logger;

  @override
  void onCreate(BlocBase<Object?> bloc) {
    super.onCreate(bloc);
    _safeLog(() => logger.debug('BLoC created', context: _contextFor(bloc)));
  }

  @override
  void onEvent(Bloc<Object?, Object?> bloc, Object? event) {
    super.onEvent(bloc, event);
    _safeLog(
      () => logger.debug(
        'BLoC event received',
        context: {
          ..._contextFor(bloc),
          'eventType': event.runtimeType.toString(),
        },
      ),
    );
  }

  @override
  void onChange(BlocBase<Object?> bloc, Change<Object?> change) {
    super.onChange(bloc, change);
    if (bloc is Bloc<dynamic, dynamic>) {
      return;
    }

    _safeLog(
      () => logger.trace(
        'BLoC state changed',
        context: {
          ..._contextFor(bloc),
          'currentStateType': change.currentState.runtimeType.toString(),
          'nextStateType': change.nextState.runtimeType.toString(),
        },
      ),
    );
  }

  @override
  void onTransition(
    Bloc<Object?, Object?> bloc,
    Transition<Object?, Object?> transition,
  ) {
    super.onTransition(bloc, transition);
    _safeLog(
      () => logger.debug(
        'BLoC transition',
        context: {
          ..._contextFor(bloc),
          'eventType': transition.event.runtimeType.toString(),
          'currentStateType': transition.currentState.runtimeType.toString(),
          'nextStateType': transition.nextState.runtimeType.toString(),
        },
      ),
    );
  }

  @override
  void onError(BlocBase<Object?> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _safeLog(
      () => logger.error(
        'BLoC error',
        error: error,
        stackTrace: stackTrace,
        context: _contextFor(bloc),
      ),
    );
  }

  @override
  void onClose(BlocBase<Object?> bloc) {
    super.onClose(bloc);
    _safeLog(() => logger.debug('BLoC closed', context: _contextFor(bloc)));
  }

  Map<String, Object?> _contextFor(BlocBase<Object?> bloc) => {
    'blocType': bloc.runtimeType.toString(),
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  };

  void _safeLog(void Function() log) {
    try {
      log();
    } catch (_) {
      // Observability must never change a BLoC or Cubit's behavior.
    }
  }
}
