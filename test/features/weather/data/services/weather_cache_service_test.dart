import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/errors/app_exception.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';
import 'package:weather_app/features/weather/data/services/weather_cache_service.dart';

void main() {
  group('WeatherCacheService', () {
    const cachedWeatherKey = 'cached_weather';

    const weatherCairo = WeatherModel(
      cityName: 'Cairo',
      country: 'Egypt',
      temperatureC: 28.5,
      feelsLikeC: 30.0,
      conditionText: 'Partly cloudy',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/116.png',
      humidity: 45,
      windKph: 12.6,
      lastUpdated: '2026-07-22 18:00',
    );

    const weatherLondon = WeatherModel(
      cityName: 'London',
      country: 'United Kingdom',
      temperatureC: 18.0,
      feelsLikeC: 17.5,
      conditionText: 'Moderate rain',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/302.png',
      humidity: 80,
      windKph: 15.0,
      lastUpdated: '2026-07-22 16:00',
    );

    late SharedPreferences preferences;
    late WeatherCacheService cacheService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      cacheService = WeatherCacheService(preferences: preferences);
    });

    test(
      'saveWeather and getCachedWeather retrieve matching WeatherModel',
      () async {
        await cacheService.saveWeather(weatherCairo);
        final cachedWeather = cacheService.getCachedWeather();

        expect(cachedWeather, weatherCairo);
      },
    );

    test('getCachedWeather returns null when cache is empty', () {
      final cachedWeather = cacheService.getCachedWeather();

      expect(cachedWeather, isNull);
    });

    test(
      'clearWeather removes cached data and getCachedWeather returns null',
      () async {
        await cacheService.saveWeather(weatherCairo);
        await cacheService.clearWeather();

        final cachedWeather = cacheService.getCachedWeather();
        expect(cachedWeather, isNull);
      },
    );

    test('saveWeather overwrites previously cached weather data', () async {
      await cacheService.saveWeather(weatherCairo);
      await cacheService.saveWeather(weatherLondon);

      final cachedWeather = cacheService.getCachedWeather();
      expect(cachedWeather, weatherLondon);
    });

    test(
      'getCachedWeather throws CacheException when cached string is invalid JSON',
      () async {
        await preferences.setString(cachedWeatherKey, 'invalid-json');

        expect(
          () => cacheService.getCachedWeather(),
          throwsA(isA<CacheException>()),
        );
      },
    );

    test(
      'getCachedWeather throws CacheException when cached JSON is a List not an Object',
      () async {
        await preferences.setString(cachedWeatherKey, '[]');

        expect(
          () => cacheService.getCachedWeather(),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });
}
