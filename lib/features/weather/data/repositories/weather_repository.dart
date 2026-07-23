import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/internet_connection_service.dart';
import '../models/weather_model.dart';
import '../services/weather_cache_service.dart';
import '../services/weather_service.dart';

class WeatherResult extends Equatable {
  const WeatherResult({
    required this.weather,
    required this.isFromCache,
    this.cachedAt,
  }) : assert(!isFromCache || cachedAt != null);

  final WeatherModel weather;
  final bool isFromCache;
  final DateTime? cachedAt;

  @override
  List<Object?> get props => [weather, isFromCache, cachedAt];
}

class WeatherRepository {
  WeatherRepository({
    required this.weatherService,
    required this.cacheService,
    required this.connectionService,
  });

  final WeatherService weatherService;
  final WeatherCacheService cacheService;
  final InternetConnectionService connectionService;

  Future<WeatherResult> getCurrentWeather(
    String city, {
    String languageCode = 'en',
  }) async {
    final hasInternet = await connectionService.hasInternetConnection;

    if (!hasInternet) {
      return await _getCachedWeatherOrThrow(
        city,
        languageCode,
        const NetworkException(),
      );
    }

    try {
      final weather = await weatherService.fetchCurrentWeather(
        city,
        languageCode: languageCode,
      );

      await _saveWeatherWithoutBlockingResult(city, languageCode, weather);

      return WeatherResult(weather: weather, isFromCache: false);
    } on NetworkException catch (exception) {
      return await _getCachedWeatherOrThrow(city, languageCode, exception);
    } on TimeoutException catch (exception) {
      return await _getCachedWeatherOrThrow(city, languageCode, exception);
    }
  }

  Future<WeatherResult> _getCachedWeatherOrThrow(
    String requestedCity,
    String languageCode,
    AppException fallbackException,
  ) async {
    final entry = await cacheService.getCachedEntry(
      requestedCity,
      languageCode: languageCode,
    );

    if (entry == null) {
      throw fallbackException;
    }

    return WeatherResult(
      weather: entry.weather,
      isFromCache: true,
      cachedAt: entry.cachedAt,
    );
  }

  Future<void> _saveWeatherWithoutBlockingResult(
    String requestedCity,
    String languageCode,
    WeatherModel weather,
  ) async {
    try {
      await cacheService.saveWeather(
        requestedCity,
        weather,
        languageCode: languageCode,
      );
    } on CacheException {
      // Cache failure must not hide successfully fetched weather data.
    }
  }
}
