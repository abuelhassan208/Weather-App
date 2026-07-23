import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/errors/app_exception.dart';
import 'package:weather_app/core/network/dio_client.dart';
import 'package:weather_app/core/network/internet_connection_service.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';
import 'package:weather_app/features/weather/data/repositories/weather_repository.dart';
import 'package:weather_app/features/weather/data/services/weather_cache_service.dart';
import 'package:weather_app/features/weather/data/services/weather_service.dart';

class FakeWeatherService extends WeatherService {
  FakeWeatherService({
    required super.dioClient,
    String apiKey = 'fake_api_key',
    this.result,
    this.error,
  }) : super(apiKey: apiKey);

  WeatherModel? result;
  Object? error;
  int callCount = 0;
  String? receivedCity;

  @override
  Future<WeatherModel> fetchCurrentWeather(
    String city, {
    String languageCode = 'en',
  }) async {
    callCount++;
    receivedCity = city;

    if (error != null) {
      throw error!;
    }

    return result!;
  }
}

class FailingSaveCacheService extends WeatherCacheService {
  FailingSaveCacheService({required super.preferences});

  @override
  Future<void> saveWeather(
    String requestedCity,
    WeatherModel weather, {
    String languageCode = 'en',
  }) async {
    throw const CacheException('Failed to save weather data.');
  }
}

void main() {
  group('WeatherRepository', () {
    final remoteWeather = WeatherModel(
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

    final cachedWeather = WeatherModel(
      cityName: 'Alexandria',
      country: 'Egypt',
      temperatureC: 27.0,
      feelsLikeC: 29.0,
      conditionText: 'Partly cloudy',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/116.png',
      humidity: 60,
      windKph: 15.0,
      lastUpdated: DateTime.utc(2026, 7, 22, 17),
    );

    late SharedPreferences preferences;
    late WeatherCacheService cacheService;
    late DioClient dioClient;
    late DateTime currentTime;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      currentTime = DateTime.utc(2026, 7, 23, 10);
      cacheService = WeatherCacheService(
        preferences: preferences,
        now: () => currentTime,
      );
      dioClient = DioClient();
    });

    test(
      'returns remote weather data and saves to cache when internet is available and request succeeds',
      () async {
        final fakeService = FakeWeatherService(
          dioClient: dioClient,
          result: remoteWeather,
        );
        final connectionService = InternetConnectionService(
          internetCheck: () async => true,
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: connectionService,
        );

        final result = await repository.getCurrentWeather('Cairo');

        expect(
          result,
          WeatherResult(weather: remoteWeather, isFromCache: false),
        );
        expect(fakeService.callCount, 1);
        expect(fakeService.receivedCity, 'Cairo');
        expect(await cacheService.getCachedWeather('Cairo'), remoteWeather);
      },
    );

    test(
      'returns cached weather data when internet is unavailable and cache exists',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        final fakeService = FakeWeatherService(dioClient: dioClient);
        final connectionService = InternetConnectionService(
          internetCheck: () async => false,
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: connectionService,
        );

        final result = await repository.getCurrentWeather('Cairo');

        expect(
          result,
          WeatherResult(
            weather: cachedWeather,
            isFromCache: true,
            cachedAt: currentTime,
          ),
        );
        expect(fakeService.callCount, 0);
      },
    );

    test(
      'throws NetworkException when internet is unavailable and cache is empty',
      () async {
        final fakeService = FakeWeatherService(dioClient: dioClient);
        final connectionService = InternetConnectionService(
          internetCheck: () async => false,
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: connectionService,
        );

        expectLater(
          () => repository.getCurrentWeather('Cairo'),
          throwsA(isA<NetworkException>()),
        );
        expect(fakeService.callCount, 0);
      },
    );

    test(
      'returns cached weather data when network fails with NetworkException and cache exists',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        final fakeService = FakeWeatherService(
          dioClient: dioClient,
          error: const NetworkException(),
        );
        final connectionService = InternetConnectionService(
          internetCheck: () async => true,
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: connectionService,
        );

        final result = await repository.getCurrentWeather('Cairo');

        expect(
          result,
          WeatherResult(
            weather: cachedWeather,
            isFromCache: true,
            cachedAt: currentTime,
          ),
        );
      },
    );

    test(
      'returns cached weather data when request times out and cache exists',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        final fakeService = FakeWeatherService(
          dioClient: dioClient,
          error: const TimeoutException(),
        );
        final connectionService = InternetConnectionService(
          internetCheck: () async => true,
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: connectionService,
        );

        final result = await repository.getCurrentWeather('Cairo');

        expect(
          result,
          WeatherResult(
            weather: cachedWeather,
            isFromCache: true,
            cachedAt: currentTime,
          ),
        );
      },
    );

    test(
      'rethrows NetworkException when network fails and cache is empty',
      () async {
        final fakeService = FakeWeatherService(
          dioClient: dioClient,
          error: const NetworkException(),
        );
        final connectionService = InternetConnectionService(
          internetCheck: () async => true,
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: connectionService,
        );

        expectLater(
          () => repository.getCurrentWeather('Cairo'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test(
      'rethrows BadRequestException on invalid city and does not fallback to cache',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        final fakeService = FakeWeatherService(
          dioClient: dioClient,
          error: const BadRequestException(),
        );
        final connectionService = InternetConnectionService(
          internetCheck: () async => true,
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: connectionService,
        );

        expectLater(
          () => repository.getCurrentWeather('InvalidCity'),
          throwsA(isA<BadRequestException>()),
        );
      },
    );

    test(
      'returns remote weather when saving cache fails without throwing CacheException',
      () async {
        final fakeService = FakeWeatherService(
          dioClient: dioClient,
          result: remoteWeather,
        );
        final failingCacheService = FailingSaveCacheService(
          preferences: preferences,
        );
        final connectionService = InternetConnectionService(
          internetCheck: () async => true,
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: failingCacheService,
          connectionService: connectionService,
        );

        final result = await repository.getCurrentWeather('Cairo');

        expect(
          result,
          WeatherResult(weather: remoteWeather, isFromCache: false),
        );
      },
    );

    test('rethrows CacheException when cached data is corrupted', () async {
      await preferences.setString('cached_weather_cairo_en', 'invalid-json');
      final fakeService = FakeWeatherService(dioClient: dioClient);
      final connectionService = InternetConnectionService(
        internetCheck: () async => false,
      );
      final repository = WeatherRepository(
        weatherService: fakeService,
        cacheService: cacheService,
        connectionService: connectionService,
      );

      expectLater(
        () => repository.getCurrentWeather('Cairo'),
        throwsA(isA<CacheException>()),
      );
    });

    test('does not return Cairo cache for offline London request', () async {
      await cacheService.saveWeather('Cairo', cachedWeather);
      final fakeService = FakeWeatherService(dioClient: dioClient);
      final repository = WeatherRepository(
        weatherService: fakeService,
        cacheService: cacheService,
        connectionService: InternetConnectionService(
          internetCheck: () async => false,
        ),
      );

      expectLater(
        () => repository.getCurrentWeather('London'),
        throwsA(isA<NetworkException>()),
      );
      expect(fakeService.callCount, 0);
    });

    test(
      'uses Cairo cache for normalized city variants while offline',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        final fakeService = FakeWeatherService(dioClient: dioClient);
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: InternetConnectionService(
            internetCheck: () async => false,
          ),
        );

        for (final city in ['Cairo', 'cairo', 'CAIRO', '  Cairo  ']) {
          final result = await repository.getCurrentWeather(city);

          expect(
            result,
            WeatherResult(
              weather: cachedWeather,
              isFromCache: true,
              cachedAt: currentTime,
            ),
          );
        }
        expect(fakeService.callCount, 0);
      },
    );

    test(
      'does not return Cairo cache when London network request fails',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        final fakeService = FakeWeatherService(
          dioClient: dioClient,
          error: const NetworkException(),
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: InternetConnectionService(
            internetCheck: () async => true,
          ),
        );

        expectLater(
          () => repository.getCurrentWeather('London'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test('does not return Cairo cache when London request times out', () async {
      await cacheService.saveWeather('Cairo', cachedWeather);
      final fakeService = FakeWeatherService(
        dioClient: dioClient,
        error: const TimeoutException(),
      );
      final repository = WeatherRepository(
        weatherService: fakeService,
        cacheService: cacheService,
        connectionService: InternetConnectionService(
          internetCheck: () async => true,
        ),
      );

      expectLater(
        () => repository.getCurrentWeather('London'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test(
      'offline request preserves NetworkException for expired cache',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        currentTime = currentTime.add(const Duration(minutes: 30));
        final repository = WeatherRepository(
          weatherService: FakeWeatherService(dioClient: dioClient),
          cacheService: cacheService,
          connectionService: InternetConnectionService(
            internetCheck: () async => false,
          ),
        );

        await expectLater(
          repository.getCurrentWeather('Cairo'),
          throwsA(isA<NetworkException>()),
        );
        expect(preferences.containsKey('cached_weather_cairo_en'), isFalse);
      },
    );

    test(
      'network failure preserves NetworkException for expired cache',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        currentTime = currentTime.add(const Duration(minutes: 31));
        final repository = WeatherRepository(
          weatherService: FakeWeatherService(
            dioClient: dioClient,
            error: const NetworkException(),
          ),
          cacheService: cacheService,
          connectionService: InternetConnectionService(
            internetCheck: () async => true,
          ),
        );

        await expectLater(
          repository.getCurrentWeather('Cairo'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test('timeout preserves TimeoutException for expired cache', () async {
      await cacheService.saveWeather('Cairo', cachedWeather);
      currentTime = currentTime.add(const Duration(minutes: 31));
      final repository = WeatherRepository(
        weatherService: FakeWeatherService(
          dioClient: dioClient,
          error: const TimeoutException(),
        ),
        cacheService: cacheService,
        connectionService: InternetConnectionService(
          internetCheck: () async => true,
        ),
      );

      await expectLater(
        repository.getCurrentWeather('Cairo'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test(
      'offline request preserves NetworkException for legacy cache',
      () async {
        await preferences.setString(
          'cached_weather_cairo_en',
          jsonEncode(cachedWeather.toJson()),
        );
        final repository = WeatherRepository(
          weatherService: FakeWeatherService(dioClient: dioClient),
          cacheService: cacheService,
          connectionService: InternetConnectionService(
            internetCheck: () async => false,
          ),
        );

        await expectLater(
          repository.getCurrentWeather('Cairo'),
          throwsA(isA<NetworkException>()),
        );
        expect(preferences.containsKey('cached_weather_cairo_en'), isFalse);
      },
    );

    test(
      'network failure preserves NetworkException for incompatible schema',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        final stored =
            jsonDecode(preferences.getString('cached_weather_cairo_en')!)
                as Map;
        stored['schemaVersion'] = 3;
        await preferences.setString(
          'cached_weather_cairo_en',
          jsonEncode(stored),
        );
        final repository = WeatherRepository(
          weatherService: FakeWeatherService(
            dioClient: dioClient,
            error: const NetworkException(),
          ),
          cacheService: cacheService,
          connectionService: InternetConnectionService(
            internetCheck: () async => true,
          ),
        );

        await expectLater(
          repository.getCurrentWeather('Cairo'),
          throwsA(isA<NetworkException>()),
        );
        expect(preferences.containsKey('cached_weather_cairo_en'), isFalse);
      },
    );

    test(
      'rethrows DataParsingException without falling back to or replacing cache',
      () async {
        await cacheService.saveWeather('Cairo', cachedWeather);
        final fakeService = FakeWeatherService(
          dioClient: dioClient,
          error: const DataParsingException('Invalid current.temp_c.'),
        );
        final repository = WeatherRepository(
          weatherService: fakeService,
          cacheService: cacheService,
          connectionService: InternetConnectionService(
            internetCheck: () async => true,
          ),
        );

        await expectLater(
          repository.getCurrentWeather('Cairo'),
          throwsA(isA<DataParsingException>()),
        );
        expect(await cacheService.getCachedWeather('Cairo'), cachedWeather);
        expect(fakeService.callCount, 1);
      },
    );

    final nonRecoverableErrors = <AppException>[
      const UnauthorizedException(),
      const NotFoundException(),
      const ServerException(),
    ];

    for (final error in nonRecoverableErrors) {
      test(
        'rethrows ${error.runtimeType} without using or replacing cache',
        () async {
          await cacheService.saveWeather('Cairo', cachedWeather);
          final fakeService = FakeWeatherService(
            dioClient: dioClient,
            error: error,
          );
          final repository = WeatherRepository(
            weatherService: fakeService,
            cacheService: cacheService,
            connectionService: InternetConnectionService(
              internetCheck: () async => true,
            ),
          );

          await expectLater(
            repository.getCurrentWeather('Cairo'),
            throwsA(same(error)),
          );
          expect(await cacheService.getCachedWeather('Cairo'), cachedWeather);
          expect(fakeService.callCount, 1);
        },
      );
    }
  });
}
