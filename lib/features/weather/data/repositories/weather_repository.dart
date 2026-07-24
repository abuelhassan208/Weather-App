import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
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
    this.logger = const NoopAppLogger(),
  });

  final WeatherService weatherService;
  final WeatherCacheService cacheService;
  final InternetConnectionService connectionService;
  final AppLogger logger;

  Future<WeatherResult> getCurrentWeather(
    String city, {
    String languageCode = 'en',
  }) async {
    logger.info(
      'Weather fetch started',
      context: {'languageCode': languageCode},
    );
    final hasInternet = await connectionService.hasInternetConnection;

    if (!hasInternet) {
      logger.info('Weather fetch using offline cache path');
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

      logger.info('Weather API result accepted');
      return WeatherResult(weather: weather, isFromCache: false);
    } on NetworkException catch (exception) {
      logger.warning(
        'Weather transport failed; trying cache',
        error: exception,
      );
      return await _getCachedWeatherOrThrow(city, languageCode, exception);
    } on TimeoutException catch (exception) {
      logger.warning(
        'Weather request timed out; trying cache',
        error: exception,
      );
      return await _getCachedWeatherOrThrow(city, languageCode, exception);
    } on AppException catch (exception, stackTrace) {
      logger.error(
        'Weather fetch failed',
        error: exception,
        stackTrace: stackTrace,
      );
      rethrow;
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
      logger.warning(
        'No valid weather cache available',
        error: fallbackException,
      );
      throw fallbackException;
    }

    logger.info('Weather cache fallback used');
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
      logger.debug('Weather cache save completed');
    } on CacheException catch (exception, stackTrace) {
      logger.warning(
        'Weather cache save failed without blocking API result',
        error: exception,
        stackTrace: stackTrace,
      );
      // Cache failure must not hide successfully fetched weather data.
    }
  }
}
