import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/splash/logic/bloc/splash_bloc.dart';
import 'package:weather_app/features/splash/logic/bloc/splash_event.dart';
import 'package:weather_app/features/splash/logic/bloc/splash_state.dart';

void main() {
  const testDuration = Duration(milliseconds: 10);

  test('starts in SplashInitial', () {
    final bloc = SplashBloc(duration: testDuration);
    addTearDown(bloc.close);

    expect(bloc.state, const SplashInitial());
  });

  blocTest<SplashBloc, SplashState>(
    'emits loading then completed after the configured duration',
    build: () => SplashBloc(duration: testDuration),
    act: (bloc) => bloc.add(const SplashStarted()),
    wait: testDuration,
    expect: () => const [SplashLoading(), SplashCompleted()],
  );

  blocTest<SplashBloc, SplashState>(
    'does not complete before the configured duration',
    build: () => SplashBloc(duration: testDuration),
    act: (bloc) => bloc.add(const SplashStarted()),
    wait: const Duration(milliseconds: 1),
    expect: () => const [SplashLoading()],
  );

  blocTest<SplashBloc, SplashState>(
    'ignores repeated SplashStarted events',
    build: () => SplashBloc(duration: testDuration),
    act: (bloc) {
      bloc
        ..add(const SplashStarted())
        ..add(const SplashStarted())
        ..add(const SplashStarted());
    },
    wait: testDuration,
    expect: () => const [SplashLoading(), SplashCompleted()],
  );

  test('can close safely before the wait completes', () async {
    final bloc = SplashBloc(duration: const Duration(seconds: 1))
      ..add(const SplashStarted());

    await Future<void>.delayed(Duration.zero);
    await expectLater(bloc.close(), completes);
  });
}
