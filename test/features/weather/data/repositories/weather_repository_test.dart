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
  Future<WeatherModel> fetchCurrentWeather(String city) async {
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
  Future<void> saveWeather(WeatherModel weather) async {
    throw const CacheException('Failed to save weather data.');
  }
}

void main() {
  group('WeatherRepository', () {
    const remoteWeather = WeatherModel(
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

    const cachedWeather = WeatherModel(
      cityName: 'Alexandria',
      country: 'Egypt',
      temperatureC: 27.0,
      feelsLikeC: 29.0,
      conditionText: 'Partly cloudy',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/116.png',
      humidity: 60,
      windKph: 15.0,
      lastUpdated: '2026-07-22 17:00',
    );

    late SharedPreferences preferences;
    late WeatherCacheService cacheService;
    late DioClient dioClient;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      cacheService = WeatherCacheService(preferences: preferences);
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
          const WeatherResult(weather: remoteWeather, isFromCache: false),
        );
        expect(fakeService.callCount, 1);
        expect(fakeService.receivedCity, 'Cairo');
        expect(cacheService.getCachedWeather(), remoteWeather);
      },
    );

    test(
      'returns cached weather data when internet is unavailable and cache exists',
      () async {
        await cacheService.saveWeather(cachedWeather);
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
          const WeatherResult(weather: cachedWeather, isFromCache: true),
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
        await cacheService.saveWeather(cachedWeather);
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
          const WeatherResult(weather: cachedWeather, isFromCache: true),
        );
      },
    );

    test(
      'returns cached weather data when request times out and cache exists',
      () async {
        await cacheService.saveWeather(cachedWeather);
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
          const WeatherResult(weather: cachedWeather, isFromCache: true),
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
        await cacheService.saveWeather(cachedWeather);
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
          const WeatherResult(weather: remoteWeather, isFromCache: false),
        );
      },
    );

    test('rethrows CacheException when cached data is corrupted', () async {
      await preferences.setString('cached_weather', 'invalid-json');
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
  });
}
