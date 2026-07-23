import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/errors/app_exception.dart';
import 'package:weather_app/features/weather/data/models/weather_cache_entry.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';

void main() {
  group('WeatherCacheEntry', () {
    final weather = WeatherModel(
      cityName: 'Cairo',
      country: 'Egypt',
      temperatureC: 30,
      feelsLikeC: 32,
      conditionText: 'Sunny',
      iconUrl: '',
      humidity: 40,
      windKph: 10,
      lastUpdated: DateTime.utc(2026, 7, 23, 10),
    );
    final cachedAt = DateTime.utc(2026, 7, 23, 10);

    test('serializes all metadata and weather using UTC', () {
      final entry = WeatherCacheEntry(
        schemaVersion: WeatherCacheEntry.currentSchemaVersion,
        normalizedCity: 'cairo',
        languageCode: 'en',
        cachedAt: cachedAt.toLocal(),
        weather: weather,
      );

      expect(entry.toJson(), {
        'schemaVersion': WeatherCacheEntry.currentSchemaVersion,
        'normalizedCity': 'cairo',
        'languageCode': 'en',
        'cachedAt': '2026-07-23T10:00:00.000Z',
        'weather': weather.toJson(),
      });
    });

    test('deserializes a valid entry and preserves value equality', () {
      final original = WeatherCacheEntry(
        schemaVersion: WeatherCacheEntry.currentSchemaVersion,
        normalizedCity: 'cairo',
        languageCode: 'en',
        cachedAt: cachedAt,
        weather: weather,
      );

      final restored = WeatherCacheEntry.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.cachedAt.isUtc, isTrue);
    });

    test('rejects missing required metadata fields', () {
      expect(
        () => WeatherCacheEntry.fromJson({'weather': weather.toJson()}),
        throwsFormatException,
      );
    });

    test('rejects metadata fields with incorrect types', () {
      expect(
        () => WeatherCacheEntry.fromJson({
          'schemaVersion': '1',
          'normalizedCity': 12,
          'languageCode': 'en',
          'cachedAt': true,
          'weather': weather.toJson(),
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid timestamp', () {
      expect(
        () => WeatherCacheEntry.fromJson({
          'schemaVersion': WeatherCacheEntry.currentSchemaVersion,
          'normalizedCity': 'cairo',
          'languageCode': 'en',
          'cachedAt': 'not-a-date',
          'weather': weather.toJson(),
        }),
        throwsFormatException,
      );
    });

    test('rejects weather that is not an object', () {
      expect(
        () => WeatherCacheEntry.fromJson({
          'schemaVersion': WeatherCacheEntry.currentSchemaVersion,
          'normalizedCity': 'cairo',
          'languageCode': 'en',
          'cachedAt': cachedAt.toIso8601String(),
          'weather': <Object>[],
        }),
        throwsFormatException,
      );
    });

    test('rejects incomplete or incorrectly typed weather payload', () {
      expect(
        () => WeatherCacheEntry.fromJson({
          'schemaVersion': WeatherCacheEntry.currentSchemaVersion,
          'normalizedCity': 'cairo',
          'languageCode': 'en',
          'cachedAt': cachedAt.toIso8601String(),
          'weather': {'cityName': 'Cairo', 'temperatureC': '30'},
        }),
        throwsA(isA<DataParsingException>()),
      );
    });
  });
}
