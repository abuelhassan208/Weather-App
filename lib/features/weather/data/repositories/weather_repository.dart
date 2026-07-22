import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/internet_connection_service.dart';
import '../models/weather_model.dart';
import '../services/weather_cache_service.dart';
import '../services/weather_service.dart';

class WeatherResult extends Equatable {
  const WeatherResult({required this.weather, required this.isFromCache});

  final WeatherModel weather;
  final bool isFromCache;

  @override
  List<Object?> get props => [weather, isFromCache];
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

  Future<WeatherResult> getCurrentWeather(String city) async {
    final hasInternet = await connectionService.hasInternetConnection;

    if (!hasInternet) {
      return _getCachedWeatherOrThrowNetworkException();
    }

    try {
      final weather = await weatherService.fetchCurrentWeather(city);

      await _saveWeatherWithoutBlockingResult(weather);

      return WeatherResult(weather: weather, isFromCache: false);
    } on NetworkException catch (exception) {
      return _getCachedWeatherOrThrow(exception);
    } on TimeoutException catch (exception) {
      return _getCachedWeatherOrThrow(exception);
    }
  }

  WeatherResult _getCachedWeatherOrThrowNetworkException() {
    return _getCachedWeatherOrThrow(const NetworkException());
  }

  WeatherResult _getCachedWeatherOrThrow(AppException fallbackException) {
    final cachedWeather = cacheService.getCachedWeather();

    if (cachedWeather == null) {
      throw fallbackException;
    }

    return WeatherResult(weather: cachedWeather, isFromCache: true);
  }

  Future<void> _saveWeatherWithoutBlockingResult(WeatherModel weather) async {
    try {
      await cacheService.saveWeather(weather);
    } on CacheException {
      // Cache failure must not hide successfully fetched weather data.
    }
  }
}
