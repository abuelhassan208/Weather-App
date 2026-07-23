import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/errors/app_exception.dart';
import 'package:weather_app/features/weather/data/models/weather_cache_entry.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';
import 'package:weather_app/features/weather/data/services/weather_cache_service.dart';

void main() {
  group('WeatherCacheService', () {
    const cairoCacheKey = 'cached_weather_cairo_en';
    const legacyCacheKey = 'cached_weather';

    final weatherCairo = WeatherModel(
      cityName: 'Cairo',
      country: 'Egypt',
      temperatureC: 28.5,
      feelsLikeC: 30.0,
      conditionText: 'Partly cloudy',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/116.png',
      humidity: 45,
      windKph: 12.6,
      lastUpdated: DateTime.utc(2026, 7, 22, 18),
    );

    final weatherLondon = WeatherModel(
      cityName: 'London',
      country: 'United Kingdom',
      temperatureC: 18.0,
      feelsLikeC: 17.5,
      conditionText: 'Moderate rain',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/302.png',
      humidity: 80,
      windKph: 15.0,
      lastUpdated: DateTime.utc(2026, 7, 22, 16),
    );

    late SharedPreferences preferences;
    late WeatherCacheService cacheService;
    late DateTime currentTime;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      currentTime = DateTime.utc(2026, 7, 23, 10);
      cacheService = WeatherCacheService(
        preferences: preferences,
        now: () => currentTime,
      );
    });

    test(
      'saveWeather and getCachedWeather retrieve matching WeatherModel',
      () async {
        await cacheService.saveWeather('Cairo', weatherCairo);
        final cachedWeather = await cacheService.getCachedWeather('Cairo');

        expect(cachedWeather, weatherCairo);
      },
    );

    test('getCachedWeather returns null when cache is empty', () async {
      final cachedWeather = await cacheService.getCachedWeather('Cairo');

      expect(cachedWeather, isNull);
    });

    test(
      'clearWeather removes cached data and getCachedWeather returns null',
      () async {
        await cacheService.saveWeather('Cairo', weatherCairo);
        await cacheService.clearWeather('Cairo');

        final cachedWeather = await cacheService.getCachedWeather('Cairo');
        expect(cachedWeather, isNull);
      },
    );

    test('city lookup ignores case and surrounding whitespace', () async {
      await cacheService.saveWeather('Cairo', weatherCairo);

      for (final city in ['Cairo', 'cairo', 'CAIRO', '  Cairo  ']) {
        expect(await cacheService.getCachedWeather(city), weatherCairo);
      }
    });

    test('getCachedWeather returns null for a different city', () async {
      await cacheService.saveWeather('Cairo', weatherCairo);

      expect(await cacheService.getCachedWeather('London'), isNull);
    });

    test('stores caches for multiple cities independently', () async {
      await cacheService.saveWeather('Cairo', weatherCairo);
      await cacheService.saveWeather('London', weatherLondon);

      expect(await cacheService.getCachedWeather('Cairo'), weatherCairo);
      expect(await cacheService.getCachedWeather('London'), weatherLondon);
    });

    test('overwrites only the cache for the same city', () async {
      final updatedCairo = WeatherModel(
        cityName: 'Cairo',
        country: 'Egypt',
        temperatureC: 31.0,
        feelsLikeC: 33.0,
        conditionText: 'Sunny',
        iconUrl: '',
        humidity: 40,
        windKph: 10.0,
        lastUpdated: DateTime.utc(2026, 7, 23, 10),
      );
      await cacheService.saveWeather('Cairo', weatherCairo);
      await cacheService.saveWeather('London', weatherLondon);
      await cacheService.saveWeather('  CAIRO ', updatedCairo);

      expect(await cacheService.getCachedWeather('cairo'), updatedCairo);
      expect(await cacheService.getCachedWeather('London'), weatherLondon);
    });

    test('ignores legacy unscoped cache safely', () async {
      await preferences.setString(legacyCacheKey, 'invalid-json');

      expect(await cacheService.getCachedWeather('Cairo'), isNull);
    });

    test(
      'getCachedWeather throws CacheException when cached string is invalid JSON',
      () async {
        await preferences.setString(cairoCacheKey, 'invalid-json');

        await expectLater(
          cacheService.getCachedWeather('Cairo'),
          throwsA(isA<CacheException>()),
        );
      },
    );

    test(
      'getCachedWeather throws CacheException when cached JSON is a List not an Object',
      () async {
        await preferences.setString(cairoCacheKey, '[]');

        await expectLater(
          cacheService.getCachedWeather('Cairo'),
          throwsA(isA<CacheException>()),
        );
      },
    );

    test('rejects an empty city for cache operations', () async {
      await expectLater(
        cacheService.getCachedWeather('   '),
        throwsA(isA<CacheException>()),
      );
      await expectLater(
        () => cacheService.saveWeather('', weatherCairo),
        throwsA(isA<CacheException>()),
      );
      await expectLater(
        () => cacheService.clearWeather('  '),
        throwsA(isA<CacheException>()),
      );
    });

    test('saveWeather stores a current-version UTC envelope', () async {
      await cacheService.saveWeather('  CAIRO ', weatherCairo);

      final stored = jsonDecode(preferences.getString(cairoCacheKey)!) as Map;

      expect(stored['schemaVersion'], WeatherCacheEntry.currentSchemaVersion);
      expect(stored['normalizedCity'], 'cairo');
      expect(stored['languageCode'], 'en');
      expect(stored['cachedAt'], '2026-07-23T10:00:00.000Z');
      expect(stored['weather'], weatherCairo.toJson());
    });

    test('uses the centralized default TTL of 30 minutes', () {
      expect(WeatherCacheService.defaultTtl, const Duration(minutes: 30));
      expect(cacheService.ttl, WeatherCacheService.defaultTtl);
    });

    test('keeps English and Arabic cache entries isolated', () async {
      await cacheService.saveWeather('Cairo', weatherCairo, languageCode: 'en');
      await cacheService.saveWeather(
        'Cairo',
        weatherLondon,
        languageCode: 'ar',
      );

      expect(
        await cacheService.getCachedWeather('cairo', languageCode: 'en'),
        weatherCairo,
      );
      expect(
        await cacheService.getCachedWeather('CAIRO', languageCode: 'ar'),
        weatherLondon,
      );
      expect(preferences.containsKey('cached_weather_cairo_en'), isTrue);
      expect(preferences.containsKey('cached_weather_cairo_ar'), isTrue);
    });

    test('rejects a non-positive TTL', () {
      expect(
        () => WeatherCacheService(preferences: preferences, ttl: Duration.zero),
        throwsArgumentError,
      );
    });

    for (final testCase in <({Duration age, bool isFresh})>[
      (age: Duration.zero, isFresh: true),
      (age: const Duration(minutes: 29, seconds: 59), isFresh: true),
      (age: const Duration(minutes: 30), isFresh: false),
      (age: const Duration(minutes: 30, seconds: 1), isFresh: false),
      (age: const Duration(hours: 1), isFresh: false),
    ]) {
      test('TTL age ${testCase.age} fresh=${testCase.isFresh}', () async {
        await cacheService.saveWeather('Cairo', weatherCairo);
        currentTime = currentTime.add(testCase.age);

        final result = await cacheService.getCachedWeather('Cairo');

        expect(result, testCase.isFresh ? weatherCairo : isNull);
        expect(preferences.containsKey(cairoCacheKey), testCase.isFresh);
      });
    }

    for (final schemaVersion in [1, 3]) {
      test('rejects and removes schema version $schemaVersion', () async {
        await cacheService.saveWeather('Cairo', weatherCairo);
        final stored = jsonDecode(preferences.getString(cairoCacheKey)!) as Map;
        stored['schemaVersion'] = schemaVersion;
        await preferences.setString(cairoCacheKey, jsonEncode(stored));

        expect(await cacheService.getCachedWeather('Cairo'), isNull);
        expect(preferences.containsKey(cairoCacheKey), isFalse);
      });
    }

    test('rejects and removes missing schema as legacy format', () async {
      await preferences.setString(
        cairoCacheKey,
        jsonEncode(weatherCairo.toJson()),
      );

      expect(await cacheService.getCachedWeather('Cairo'), isNull);
      expect(preferences.containsKey(cairoCacheKey), isFalse);
    });

    test('rejects and removes incorrectly typed schema safely', () async {
      await cacheService.saveWeather('Cairo', weatherCairo);
      final stored = jsonDecode(preferences.getString(cairoCacheKey)!) as Map;
      stored['schemaVersion'] = '1';
      await preferences.setString(cairoCacheKey, jsonEncode(stored));

      expect(await cacheService.getCachedWeather('Cairo'), isNull);
      expect(preferences.containsKey(cairoCacheKey), isFalse);
    });

    test(
      'throws CacheException and removes mismatched city metadata',
      () async {
        await cacheService.saveWeather('Cairo', weatherCairo);
        final stored = jsonDecode(preferences.getString(cairoCacheKey)!) as Map;
        stored['normalizedCity'] = 'london';
        await preferences.setString(cairoCacheKey, jsonEncode(stored));

        await expectLater(
          cacheService.getCachedWeather('Cairo'),
          throwsA(isA<CacheException>()),
        );
        expect(preferences.containsKey(cairoCacheKey), isFalse);
      },
    );

    test('throws CacheException and removes a future timestamp', () async {
      await cacheService.saveWeather('Cairo', weatherCairo);
      final stored = jsonDecode(preferences.getString(cairoCacheKey)!) as Map;
      stored['cachedAt'] = currentTime
          .add(const Duration(seconds: 1))
          .toIso8601String();
      await preferences.setString(cairoCacheKey, jsonEncode(stored));

      await expectLater(
        cacheService.getCachedWeather('Cairo'),
        throwsA(isA<CacheException>()),
      );
      expect(preferences.containsKey(cairoCacheKey), isFalse);
    });

    test('converts corrupt current metadata to CacheException', () async {
      await cacheService.saveWeather('Cairo', weatherCairo);
      final stored = jsonDecode(preferences.getString(cairoCacheKey)!) as Map;
      stored['cachedAt'] = 123;
      await preferences.setString(cairoCacheKey, jsonEncode(stored));

      await expectLater(
        cacheService.getCachedWeather('Cairo'),
        throwsA(isA<CacheException>()),
      );
    });

    test(
      'converts corrupt current weather payload to CacheException',
      () async {
        await cacheService.saveWeather('Cairo', weatherCairo);
        final stored = jsonDecode(preferences.getString(cairoCacheKey)!) as Map;
        stored['weather'] = <Object>[];
        await preferences.setString(cairoCacheKey, jsonEncode(stored));

        await expectLater(
          cacheService.getCachedWeather('Cairo'),
          throwsA(isA<CacheException>()),
        );
      },
    );

    test(
      'converts strict weather validation failures to CacheException',
      () async {
        final corruptWeatherPayloads = <Map<String, Object?>>[
          {'remove': 'temperatureC'},
          {'humidity': 101},
          {'windKph': -1},
          {'conditionText': '   '},
        ];

        for (final corruption in corruptWeatherPayloads) {
          await cacheService.saveWeather('Cairo', weatherCairo);
          final stored =
              jsonDecode(preferences.getString(cairoCacheKey)!) as Map;
          final weather = Map<String, dynamic>.from(stored['weather'] as Map);
          final fieldToRemove = corruption['remove'];
          if (fieldToRemove is String) {
            weather.remove(fieldToRemove);
          } else {
            weather.addAll(corruption);
          }
          stored['weather'] = weather;
          await preferences.setString(cairoCacheKey, jsonEncode(stored));

          await expectLater(
            cacheService.getCachedWeather('Cairo'),
            throwsA(isA<CacheException>()),
          );
          expect(preferences.containsKey(cairoCacheKey), isFalse);
        }
      },
    );
  });
}
