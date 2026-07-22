import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/weather_model.dart';

class WeatherCacheService {
  WeatherCacheService({required this.preferences});

  static const String _cachedWeatherKey = 'cached_weather';

  final SharedPreferences preferences;

  Future<void> saveWeather(WeatherModel weather) async {
    final encodedWeather = jsonEncode(weather.toJson());

    final didSave = await preferences.setString(
      _cachedWeatherKey,
      encodedWeather,
    );

    if (!didSave) {
      throw const CacheException('Failed to save weather data.');
    }
  }

  WeatherModel? getCachedWeather() {
    final encodedWeather = preferences.getString(_cachedWeatherKey);

    if (encodedWeather == null || encodedWeather.isEmpty) {
      return null;
    }

    try {
      final decodedWeather = jsonDecode(encodedWeather);

      if (decodedWeather is! Map) {
        throw const FormatException('Invalid cached weather format.');
      }

      return WeatherModel.fromCacheJson(
        Map<String, dynamic>.from(decodedWeather),
      );
    } catch (_) {
      throw const CacheException('Cached weather data is invalid.');
    }
  }

  Future<void> clearWeather() async {
    final didRemove = await preferences.remove(_cachedWeatherKey);

    if (!didRemove && preferences.containsKey(_cachedWeatherKey)) {
      throw const CacheException('Failed to clear weather data.');
    }
  }
}
