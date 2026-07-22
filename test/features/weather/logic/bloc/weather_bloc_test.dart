import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_app/core/errors/app_exception.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';
import 'package:weather_app/features/weather/data/repositories/weather_repository.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_bloc.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_event.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_state.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  group('WeatherBloc', () {
    const weather = WeatherModel(
      cityName: 'Cairo',
      country: 'Egypt',
      temperatureC: 30.0,
      feelsLikeC: 32.0,
      conditionText: 'Sunny',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/113.png',
      humidity: 40,
      windKph: 10.0,
      lastUpdated: '2026-07-22 18:00',
    );

    late MockWeatherRepository repository;

    setUp(() {
      repository = MockWeatherRepository();
    });

    test('initial state is WeatherInitial', () {
      final bloc = WeatherBloc(repository: repository);
      expect(bloc.state, const WeatherInitial());
    });

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherSuccess(isFromCache: false)] on successful fresh request',
      build: () {
        when(() => repository.getCurrentWeather('Cairo')).thenAnswer(
          (_) async =>
              const WeatherResult(weather: weather, isFromCache: false),
        );
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherSuccess(weather: weather, isFromCache: false),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherSuccess(isFromCache: true)] on successful cached request',
      build: () {
        when(() => repository.getCurrentWeather('Cairo')).thenAnswer(
          (_) async => const WeatherResult(weather: weather, isFromCache: true),
        );
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherSuccess(weather: weather, isFromCache: true),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherFailure(invalidCity)] when BadRequestException occurs',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(const BadRequestException());
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.invalidCity),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherFailure(noInternet)] when NetworkException occurs',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(const NetworkException());
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.noInternet),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherFailure(timeout)] when TimeoutException occurs',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(const TimeoutException());
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.timeout),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherFailure(unauthorized)] when UnauthorizedException occurs',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(const UnauthorizedException());
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.unauthorized),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherFailure(server)] when ServerException occurs',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(const ServerException());
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.server),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherFailure(cache)] when CacheException occurs',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(const CacheException());
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.cache),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherFailure(configuration)] when ConfigurationException occurs',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(const ConfigurationException());
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.configuration),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'emits [WeatherLoading, WeatherFailure(unknown)] when an unexpected exception occurs',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(Exception('Unexpected error'));
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.unknown),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );
  });
}
