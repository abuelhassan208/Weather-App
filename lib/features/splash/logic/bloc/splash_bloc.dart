import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({this.duration = splashDuration}) : super(const SplashInitial()) {
    on<SplashStarted>(_onStarted, transformer: droppable());
  }

  static const Duration splashDuration = Duration(milliseconds: 1200);

  final Duration duration;
  Timer? _timer;
  Completer<void>? _delayCompleter;
  var _isClosing = false;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    if (state is! SplashInitial) {
      return;
    }

    emit(const SplashLoading());
    _delayCompleter = Completer<void>();
    _timer = Timer(duration, _completeDelay);
    await _delayCompleter!.future;

    if (!emit.isDone && !_isClosing) {
      emit(const SplashCompleted());
    }
  }

  void _completeDelay() {
    final completer = _delayCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  Future<void> close() {
    _isClosing = true;
    _timer?.cancel();
    _completeDelay();
    return super.close();
  }
}
