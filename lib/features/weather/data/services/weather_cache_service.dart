import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/weather_cache_entry.dart';
import '../models/weather_model.dart';

typedef Clock = DateTime Function();

class WeatherCacheService {
  WeatherCacheService({
    required this.preferences,
    this.ttl = defaultTtl,
    Clock? now,
  }) : _now = now ?? _currentUtcTime {
    if (ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'TTL must be greater than zero.');
    }
  }

  static const String _cachedWeatherKeyPrefix = 'cached_weather_';
  static const Duration defaultTtl = Duration(minutes: 30);

  final SharedPreferences preferences;
  final Duration ttl;
  final Clock _now;

  Future<void> saveWeather(
    String requestedCity,
    WeatherModel weather, {
    String languageCode = 'en',
  }) async {
    final normalizedCity = _normalizeCity(requestedCity);
    final normalizedLanguage = _normalizeLanguage(languageCode);
    final entry = WeatherCacheEntry(
      schemaVersion: WeatherCacheEntry.currentSchemaVersion,
      normalizedCity: normalizedCity,
      languageCode: normalizedLanguage,
      cachedAt: _now().toUtc(),
      weather: weather,
    );
    final encodedWeather = jsonEncode(entry.toJson());

    final didSave = await preferences.setString(
      _cacheKey(normalizedCity, normalizedLanguage),
      encodedWeather,
    );

    if (!didSave) {
      throw const CacheException('Failed to save weather data.');
    }
  }

  Future<WeatherCacheEntry?> getCachedEntry(
    String requestedCity, {
    String languageCode = 'en',
  }) async {
    final normalizedCity = _normalizeCity(requestedCity);
    final normalizedLanguage = _normalizeLanguage(languageCode);
    final cacheKey = _cacheKey(normalizedCity, normalizedLanguage);
    final encodedWeather = preferences.getString(cacheKey);

    if (encodedWeather == null || encodedWeather.isEmpty) {
      return null;
    }

    try {
      final decodedEntry = jsonDecode(encodedWeather);

      if (decodedEntry is! Map) {
        throw const FormatException('Invalid cached weather format.');
      }

      final entryJson = Map<String, dynamic>.from(decodedEntry);
      final storedSchemaVersion = entryJson['schemaVersion'];

      if (storedSchemaVersion is! int ||
          storedSchemaVersion != WeatherCacheEntry.currentSchemaVersion) {
        await _removeInvalidEntry(cacheKey);
        return null;
      }

      final entry = WeatherCacheEntry.fromJson(entryJson);
      final now = _now().toUtc();

      if (entry.normalizedCity != normalizedCity ||
          entry.languageCode != normalizedLanguage ||
          entry.cachedAt.isAfter(now)) {
        await _removeInvalidEntry(cacheKey);
        throw const CacheException('Cached weather metadata is invalid.');
      }

      final cacheAge = now.difference(entry.cachedAt);
      if (cacheAge >= ttl) {
        await _removeInvalidEntry(cacheKey);
        return null;
      }

      return entry;
    } on CacheException {
      rethrow;
    } catch (_) {
      await _removeInvalidEntry(cacheKey);
      throw const CacheException('Cached weather data is invalid.');
    }
  }

  Future<WeatherModel?> getCachedWeather(
    String requestedCity, {
    String languageCode = 'en',
  }) async {
    return (await getCachedEntry(
      requestedCity,
      languageCode: languageCode,
    ))?.weather;
  }

  Future<void> clearWeather(
    String requestedCity, {
    String languageCode = 'en',
  }) async {
    final cacheKey = _cacheKey(
      _normalizeCity(requestedCity),
      _normalizeLanguage(languageCode),
    );
    final didRemove = await preferences.remove(cacheKey);

    if (!didRemove && preferences.containsKey(cacheKey)) {
      throw const CacheException('Failed to clear weather data.');
    }
  }

  Future<void> _removeInvalidEntry(String cacheKey) async {
    final didRemove = await preferences.remove(cacheKey);

    if (!didRemove && preferences.containsKey(cacheKey)) {
      throw const CacheException('Failed to remove invalid weather cache.');
    }
  }

  static String _normalizeCity(String city) {
    final normalizedCity = city.trim().toLowerCase();

    if (normalizedCity.isEmpty) {
      throw const CacheException(
        'City name cannot be empty for weather cache.',
      );
    }

    return normalizedCity;
  }

  static String _normalizeLanguage(String languageCode) =>
      languageCode == 'ar' ? 'ar' : 'en';

  static String _cacheKey(String normalizedCity, String languageCode) =>
      '$_cachedWeatherKeyPrefix${Uri.encodeComponent(normalizedCity)}_$languageCode';
}

DateTime _currentUtcTime() => DateTime.now().toUtc();
