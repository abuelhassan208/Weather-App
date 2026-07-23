import 'dart:async';

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
    final weather = WeatherModel(
      cityName: 'Cairo',
      country: 'Egypt',
      temperatureC: 30.0,
      feelsLikeC: 32.0,
      conditionText: 'Sunny',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/113.png',
      humidity: 40,
      windKph: 10.0,
      lastUpdated: DateTime.utc(2026, 7, 22, 18),
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
          (_) async => WeatherResult(weather: weather, isFromCache: false),
        );
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => [
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
          (_) async => WeatherResult(
            weather: weather,
            isFromCache: true,
            cachedAt: DateTime.utc(2026, 7, 23, 10),
          ),
        );
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => [
        WeatherLoading(),
        WeatherSuccess(
          weather: weather,
          isFromCache: true,
          cachedAt: DateTime.utc(2026, 7, 23, 10),
        ),
      ],
      verify: (_) {
        verify(() => repository.getCurrentWeather('Cairo')).called(1);
      },
    );

    blocTest<WeatherBloc, WeatherState>(
      'passes Arabic language to repository without recreating bloc',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo', languageCode: 'ar'),
        ).thenAnswer(
          (_) async => WeatherResult(weather: weather, isFromCache: false),
        );
        return WeatherBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const WeatherRequested('Cairo', languageCode: 'ar')),
      expect: () => [
        const WeatherLoading(),
        WeatherSuccess(weather: weather, isFromCache: false),
      ],
      verify: (_) {
        verify(
          () => repository.getCurrentWeather('Cairo', languageCode: 'ar'),
        ).called(1);
      },
    );

    test(
      'retry after a successful request repeats the same city and language',
      () async {
        when(
          () => repository.getCurrentWeather('Cairo', languageCode: 'ar'),
        ).thenAnswer(
          (_) async => WeatherResult(weather: weather, isFromCache: false),
        );
        final bloc = WeatherBloc(repository: repository);
        final states = <WeatherState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const WeatherRequested('Cairo', languageCode: 'ar'));
        await bloc.stream.firstWhere((state) => state is WeatherSuccess);
        bloc.add(const WeatherRetryRequested());
        await bloc.stream.firstWhere(
          (state) => state is WeatherSuccess && states.length >= 4,
        );

        expect(states, [
          const WeatherLoading(),
          WeatherSuccess(weather: weather, isFromCache: false),
          const WeatherLoading(),
          WeatherSuccess(weather: weather, isFromCache: false),
        ]);
        verify(
          () => repository.getCurrentWeather('Cairo', languageCode: 'ar'),
        ).called(2);

        await subscription.cancel();
        await bloc.close();
      },
    );

    test('retry after a failure repeats the same city', () async {
      when(
        () => repository.getCurrentWeather('Cairo'),
      ).thenThrow(const NetworkException());
      final bloc = WeatherBloc(repository: repository);
      final states = <WeatherState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const WeatherRequested('Cairo'));
      await bloc.stream.firstWhere((state) => state is WeatherFailure);
      bloc.add(const WeatherRetryRequested());
      await bloc.stream.firstWhere(
        (state) => state is WeatherFailure && states.length >= 4,
      );

      expect(states, const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.noInternet),
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.noInternet),
      ]);
      verify(() => repository.getCurrentWeather('Cairo')).called(2);

      await subscription.cancel();
      await bloc.close();
    });

    test('retry without a previous request is a safe no-op', () async {
      final bloc = WeatherBloc(repository: repository);
      final states = <WeatherState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const WeatherRetryRequested());
      bloc.add(const WeatherRetryRequested());
      await bloc.close();

      expect(bloc.state, const WeatherInitial());
      expect(states, isEmpty);
      verifyNever(() => repository.getCurrentWeather(any()));

      await subscription.cancel();
    });

    test('retry uses the most recent search request', () async {
      final londonWeather = WeatherModel(
        cityName: 'London',
        country: 'United Kingdom',
        temperatureC: 18,
        feelsLikeC: 17,
        conditionText: 'Cloudy',
        iconUrl: '',
        humidity: 70,
        windKph: 12,
        lastUpdated: DateTime.utc(2026, 7, 23, 10),
      );
      when(() => repository.getCurrentWeather('Cairo')).thenAnswer(
        (_) async => WeatherResult(weather: weather, isFromCache: false),
      );
      when(
        () => repository.getCurrentWeather('London', languageCode: 'ar'),
      ).thenAnswer(
        (_) async => WeatherResult(weather: londonWeather, isFromCache: false),
      );
      final bloc = WeatherBloc(repository: repository);

      bloc.add(const WeatherRequested('Cairo'));
      await bloc.stream.firstWhere((state) => state is WeatherSuccess);
      bloc.add(const WeatherRequested('London', languageCode: 'ar'));
      await bloc.stream.firstWhere(
        (state) => state is WeatherSuccess && state.weather == londonWeather,
      );
      bloc.add(const WeatherRetryRequested());
      await bloc.stream.firstWhere(
        (state) => state is WeatherSuccess && state.weather == londonWeather,
      );

      verify(() => repository.getCurrentWeather('Cairo')).called(1);
      verify(
        () => repository.getCurrentWeather('London', languageCode: 'ar'),
      ).called(2);
      verifyNoMoreInteractions(repository);

      await bloc.close();
    });

    test('retry while loading restarts the same request', () async {
      final firstRequest = Completer<WeatherResult>();
      final retryRequest = Completer<WeatherResult>();
      final firstStarted = Completer<void>();
      final retryStarted = Completer<void>();
      var callCount = 0;
      when(() => repository.getCurrentWeather('Cairo')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          firstStarted.complete();
          return firstRequest.future;
        }
        retryStarted.complete();
        return retryRequest.future;
      });
      final bloc = WeatherBloc(repository: repository);
      final states = <WeatherState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const WeatherRequested('Cairo'));
      await firstStarted.future;
      bloc.add(const WeatherRetryRequested());
      await retryStarted.future;

      retryRequest.complete(
        WeatherResult(weather: weather, isFromCache: false),
      );
      await bloc.stream.firstWhere((state) => state is WeatherSuccess);
      firstRequest.complete(
        WeatherResult(weather: weather, isFromCache: false),
      );
      await firstRequest.future;

      expect(states.whereType<WeatherSuccess>(), [
        WeatherSuccess(weather: weather, isFromCache: false),
      ]);
      verify(() => repository.getCurrentWeather('Cairo')).called(2);

      await subscription.cancel();
      await bloc.close();
    });

    test('a new search while retrying wins over the retry result', () async {
      final retryRequest = Completer<WeatherResult>();
      final londonRequest = Completer<WeatherResult>();
      final retryStarted = Completer<void>();
      final londonStarted = Completer<void>();
      var cairoCallCount = 0;
      final londonWeather = WeatherModel(
        cityName: 'London',
        country: 'United Kingdom',
        temperatureC: 18,
        feelsLikeC: 17,
        conditionText: 'Cloudy',
        iconUrl: '',
        humidity: 70,
        windKph: 12,
        lastUpdated: DateTime.utc(2026, 7, 23, 10),
      );
      when(() => repository.getCurrentWeather('Cairo')).thenAnswer((_) {
        cairoCallCount++;
        if (cairoCallCount == 1) {
          return Future.value(
            WeatherResult(weather: weather, isFromCache: false),
          );
        }
        retryStarted.complete();
        return retryRequest.future;
      });
      when(() => repository.getCurrentWeather('London')).thenAnswer((_) {
        londonStarted.complete();
        return londonRequest.future;
      });
      final bloc = WeatherBloc(repository: repository);
      final states = <WeatherState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const WeatherRequested('Cairo'));
      await bloc.stream.firstWhere((state) => state is WeatherSuccess);
      bloc.add(const WeatherRetryRequested());
      await retryStarted.future;
      bloc.add(const WeatherRequested('London'));
      await londonStarted.future;

      londonRequest.complete(
        WeatherResult(weather: londonWeather, isFromCache: false),
      );
      await bloc.stream.firstWhere(
        (state) => state is WeatherSuccess && state.weather == londonWeather,
      );
      retryRequest.complete(
        WeatherResult(weather: weather, isFromCache: false),
      );
      await retryRequest.future;

      expect(
        bloc.state,
        WeatherSuccess(weather: londonWeather, isFromCache: false),
      );
      expect(states.whereType<WeatherSuccess>().last.weather, londonWeather);
      verify(() => repository.getCurrentWeather('Cairo')).called(2);
      verify(() => repository.getCurrentWeather('London')).called(1);

      await subscription.cancel();
      await bloc.close();
    });

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
      'emits [WeatherLoading, WeatherFailure(invalidCity)] when NotFoundException occurs',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(const NotFoundException());
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

    blocTest<WeatherBloc, WeatherState>(
      'maps DataParsingException explicitly to WeatherFailure(unknown)',
      build: () {
        when(
          () => repository.getCurrentWeather('Cairo'),
        ).thenThrow(const DataParsingException());
        return WeatherBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const WeatherRequested('Cairo')),
      expect: () => const [
        WeatherLoading(),
        WeatherFailure(type: WeatherFailureType.unknown),
      ],
    );

    test('latest success wins when an older request succeeds later', () async {
      final cairoRequest = Completer<WeatherResult>();
      final londonRequest = Completer<WeatherResult>();
      final cairoStarted = Completer<void>();
      final londonStarted = Completer<void>();
      final londonWeather = WeatherModel(
        cityName: 'London',
        country: 'United Kingdom',
        temperatureC: 18,
        feelsLikeC: 17,
        conditionText: 'Cloudy',
        iconUrl: '',
        humidity: 70,
        windKph: 12,
        lastUpdated: DateTime.utc(2026, 7, 23, 10),
      );
      when(() => repository.getCurrentWeather('Cairo')).thenAnswer((_) {
        cairoStarted.complete();
        return cairoRequest.future;
      });
      when(() => repository.getCurrentWeather('London')).thenAnswer((_) {
        londonStarted.complete();
        return londonRequest.future;
      });
      final bloc = WeatherBloc(repository: repository);
      final states = <WeatherState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const WeatherRequested('Cairo'));
      await cairoStarted.future;
      bloc.add(const WeatherRequested('London'));
      await londonStarted.future;

      final londonSuccess = bloc.stream.firstWhere(
        (state) =>
            state == WeatherSuccess(weather: londonWeather, isFromCache: false),
      );
      londonRequest.complete(
        WeatherResult(weather: londonWeather, isFromCache: false),
      );
      await londonSuccess;
      cairoRequest.complete(
        WeatherResult(weather: weather, isFromCache: false),
      );
      await Future<void>.value();

      expect(
        bloc.state,
        WeatherSuccess(weather: londonWeather, isFromCache: false),
      );
      expect(
        states,
        isNot(contains(WeatherSuccess(weather: weather, isFromCache: false))),
      );

      await subscription.cancel();
      await bloc.close();
    });

    test('older failure cannot replace the latest success', () async {
      final cairoRequest = Completer<WeatherResult>();
      final londonRequest = Completer<WeatherResult>();
      final cairoStarted = Completer<void>();
      final londonStarted = Completer<void>();
      final londonWeather = WeatherModel(
        cityName: 'London',
        country: 'United Kingdom',
        temperatureC: 18,
        feelsLikeC: 17,
        conditionText: 'Cloudy',
        iconUrl: '',
        humidity: 70,
        windKph: 12,
        lastUpdated: DateTime.utc(2026, 7, 23, 10),
      );
      when(() => repository.getCurrentWeather('Cairo')).thenAnswer((_) {
        cairoStarted.complete();
        return cairoRequest.future;
      });
      when(() => repository.getCurrentWeather('London')).thenAnswer((_) {
        londonStarted.complete();
        return londonRequest.future;
      });
      final bloc = WeatherBloc(repository: repository);
      final states = <WeatherState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const WeatherRequested('Cairo'));
      await cairoStarted.future;
      bloc.add(const WeatherRequested('London'));
      await londonStarted.future;

      final londonSuccess = bloc.stream.firstWhere(
        (state) => state is WeatherSuccess && state.weather == londonWeather,
      );
      londonRequest.complete(
        WeatherResult(weather: londonWeather, isFromCache: false),
      );
      await londonSuccess;
      cairoRequest.completeError(const NetworkException());
      await Future<void>.value();

      expect(
        bloc.state,
        WeatherSuccess(weather: londonWeather, isFromCache: false),
      );
      expect(states.whereType<WeatherFailure>(), isEmpty);

      await subscription.cancel();
      await bloc.close();
    });

    test('older success cannot replace the latest failure', () async {
      final cairoRequest = Completer<WeatherResult>();
      final londonRequest = Completer<WeatherResult>();
      final cairoStarted = Completer<void>();
      final londonStarted = Completer<void>();
      when(() => repository.getCurrentWeather('Cairo')).thenAnswer((_) {
        cairoStarted.complete();
        return cairoRequest.future;
      });
      when(() => repository.getCurrentWeather('London')).thenAnswer((_) {
        londonStarted.complete();
        return londonRequest.future;
      });
      final bloc = WeatherBloc(repository: repository);
      final states = <WeatherState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const WeatherRequested('Cairo'));
      await cairoStarted.future;
      bloc.add(const WeatherRequested('London'));
      await londonStarted.future;

      final londonFailure = bloc.stream.firstWhere(
        (state) =>
            state == const WeatherFailure(type: WeatherFailureType.noInternet),
      );
      londonRequest.completeError(const NetworkException());
      await londonFailure;
      cairoRequest.complete(
        WeatherResult(weather: weather, isFromCache: false),
      );
      await Future<void>.value();

      expect(
        bloc.state,
        const WeatherFailure(type: WeatherFailureType.noInternet),
      );
      expect(states.whereType<WeatherSuccess>(), isEmpty);

      await subscription.cancel();
      await bloc.close();
    });

    test(
      'older cached result cannot replace the latest fresh result',
      () async {
        final cairoRequest = Completer<WeatherResult>();
        final londonRequest = Completer<WeatherResult>();
        final cairoStarted = Completer<void>();
        final londonStarted = Completer<void>();
        final londonWeather = WeatherModel(
          cityName: 'London',
          country: 'United Kingdom',
          temperatureC: 18,
          feelsLikeC: 17,
          conditionText: 'Cloudy',
          iconUrl: '',
          humidity: 70,
          windKph: 12,
          lastUpdated: DateTime.utc(2026, 7, 23, 10),
        );
        when(() => repository.getCurrentWeather('Cairo')).thenAnswer((_) {
          cairoStarted.complete();
          return cairoRequest.future;
        });
        when(() => repository.getCurrentWeather('London')).thenAnswer((_) {
          londonStarted.complete();
          return londonRequest.future;
        });
        final bloc = WeatherBloc(repository: repository);
        final states = <WeatherState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const WeatherRequested('Cairo'));
        await cairoStarted.future;
        bloc.add(const WeatherRequested('London'));
        await londonStarted.future;

        final londonSuccess = bloc.stream.firstWhere(
          (state) => state is WeatherSuccess && state.weather == londonWeather,
        );
        londonRequest.complete(
          WeatherResult(weather: londonWeather, isFromCache: false),
        );
        await londonSuccess;
        cairoRequest.complete(
          WeatherResult(
            weather: weather,
            isFromCache: true,
            cachedAt: DateTime.utc(2026, 7, 23, 10),
          ),
        );
        await Future<void>.value();

        expect(
          bloc.state,
          WeatherSuccess(weather: londonWeather, isFromCache: false),
        );
        expect(
          states.whereType<WeatherSuccess>().where(
            (state) => state.isFromCache,
          ),
          isEmpty,
        );

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'only the third of three overlapping requests determines final state',
      () async {
        final requests = <String, Completer<WeatherResult>>{
          'Cairo': Completer<WeatherResult>(),
          'London': Completer<WeatherResult>(),
          'Paris': Completer<WeatherResult>(),
        };
        final starts = <String, Completer<void>>{
          'Cairo': Completer<void>(),
          'London': Completer<void>(),
          'Paris': Completer<void>(),
        };
        final londonWeather = WeatherModel(
          cityName: 'London',
          country: 'United Kingdom',
          temperatureC: 18,
          feelsLikeC: 17,
          conditionText: 'Cloudy',
          iconUrl: '',
          humidity: 70,
          windKph: 12,
          lastUpdated: DateTime.utc(2026, 7, 23, 10),
        );
        final parisWeather = WeatherModel(
          cityName: 'Paris',
          country: 'France',
          temperatureC: 22,
          feelsLikeC: 22,
          conditionText: 'Clear',
          iconUrl: '',
          humidity: 55,
          windKph: 8,
          lastUpdated: DateTime.utc(2026, 7, 23, 11),
        );
        for (final city in requests.keys) {
          when(() => repository.getCurrentWeather(city)).thenAnswer((_) {
            starts[city]!.complete();
            return requests[city]!.future;
          });
        }
        final bloc = WeatherBloc(repository: repository);
        final states = <WeatherState>[];
        final subscription = bloc.stream.listen(states.add);

        for (final city in requests.keys) {
          bloc.add(WeatherRequested(city));
          await starts[city]!.future;
        }

        final parisSuccess = bloc.stream.firstWhere(
          (state) => state is WeatherSuccess && state.weather == parisWeather,
        );
        requests['Paris']!.complete(
          WeatherResult(weather: parisWeather, isFromCache: false),
        );
        await parisSuccess;
        requests['London']!.complete(
          WeatherResult(weather: londonWeather, isFromCache: false),
        );
        requests['Cairo']!.complete(
          WeatherResult(weather: weather, isFromCache: false),
        );
        await Future<void>.value();

        expect(
          bloc.state,
          WeatherSuccess(weather: parisWeather, isFromCache: false),
        );
        expect(
          states.whereType<WeatherSuccess>().map((state) => state.weather),
          [parisWeather],
        );

        await subscription.cancel();
        await bloc.close();
      },
    );
  });
}
