import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';
import 'package:weather_app/features/weather/presentation/formatters/weather_card_formatter.dart';
import 'package:weather_app/l10n/generated/app_localizations_ar.dart';
import 'package:weather_app/l10n/generated/app_localizations_en.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  const formatter = WeatherCardFormatter();
  final english = AppLocalizationsEn();
  final arabic = AppLocalizationsAr();

  WeatherModel weather({
    String city = 'Cairo',
    String country = 'Egypt',
    double temperature = 30,
    double feelsLike = 32,
    String condition = 'Sunny',
    String iconUrl = '',
    int humidity = 40,
    double wind = 10,
    DateTime? lastUpdated,
  }) {
    return WeatherModel(
      cityName: city,
      country: country,
      temperatureC: temperature,
      feelsLikeC: feelsLike,
      conditionText: condition,
      iconUrl: iconUrl,
      humidity: humidity,
      windKph: wind,
      lastUpdated: lastUpdated ?? DateTime(2026, 7, 22, 18),
    );
  }

  group('WeatherCardFormatter', () {
    test('joins trimmed city and country without stray separators', () {
      final both = formatter.format(
        weather: weather(city: ' Cairo ', country: ' Egypt '),
        localizations: english,
        locale: const Locale('en'),
      );
      final cityOnly = formatter.format(
        weather: weather(country: '  '),
        localizations: english,
        locale: const Locale('en'),
      );
      final countryOnly = formatter.format(
        weather: weather(city: '', country: ' Egypt '),
        localizations: english,
        locale: const Locale('en'),
      );

      expect(both.locationText, 'Cairo, Egypt');
      expect(cityOnly.locationText, 'Cairo');
      expect(countryOnly.locationText, 'Egypt');
      expect(cityOnly.locationText, isNot(endsWith(',')));
      expect(countryOnly.locationText, isNot(startsWith(',')));
    });

    test('uses a safe location fallback when both parts are blank', () {
      final data = formatter.format(
        weather: weather(city: ' ', country: ''),
        localizations: english,
        locale: const Locale('en'),
      );

      expect(data.locationText, '—');
      expect(data.locationSemanticLabel, 'Location, —');
    });

    test('trims conditions, preserves Arabic, and falls back when blank', () {
      final normal = formatter.format(
        weather: weather(condition: ' Sunny '),
        localizations: english,
        locale: const Locale('en'),
      );
      final empty = formatter.format(
        weather: weather(condition: '  '),
        localizations: english,
        locale: const Locale('en'),
      );
      final arabicCondition = formatter.format(
        weather: weather(condition: ' أمطار متفرقة '),
        localizations: arabic,
        locale: const Locale('ar'),
      );

      expect(normal.conditionText, 'Sunny');
      expect(empty.conditionText, '—');
      expect(arabicCondition.conditionText, 'أمطار متفرقة');
      expect(arabicCondition.conditionSemanticLabel, 'أمطار متفرقة');
    });

    test('formats positive, negative, zero, decimal and feels-like values', () {
      for (final value in <double>[30, -5, 0, 12.5]) {
        final data = formatter.format(
          weather: weather(temperature: value, feelsLike: value - 1),
          localizations: english,
          locale: const Locale('en'),
        );

        expect(data.temperatureText, english.temperatureValue(value));
        expect(data.feelsLikeText, english.temperatureValue(value - 1));
        expect(
          data.temperatureSemanticLabel,
          english.temperatureSemantics(data.temperatureText),
        );
        expect(
          data.feelsLikeSemanticLabel,
          english.feelsLikeSemantics(data.feelsLikeText),
        );
      }
    });

    test(
      'uses localized temperature and metric text in English and Arabic',
      () {
        final en = formatter.format(
          weather: weather(temperature: 12.5, humidity: 65, wind: 7.5),
          localizations: english,
          locale: const Locale('en'),
        );
        final ar = formatter.format(
          weather: weather(temperature: 12.5, humidity: 65, wind: 7.5),
          localizations: arabic,
          locale: const Locale('ar'),
        );

        expect(en.temperatureText, '12.5°C');
        expect(en.humidityText, '65%');
        expect(en.windSpeedText, '7.5 km/h');
        expect(ar.temperatureText, '12.5°م');
        expect(ar.humidityText, '65٪');
        expect(ar.windSpeedText, '7.5 كم/س');
      },
    );

    test('formats humidity boundaries and matching semantic labels', () {
      for (final value in <int>[0, 40, 100]) {
        final data = formatter.format(
          weather: weather(humidity: value),
          localizations: english,
          locale: const Locale('en'),
        );

        expect(data.humidityText, english.humidityValue(value));
        expect(data.humiditySemanticLabel, english.humiditySemantics(value));
      }
    });

    test('formats zero and decimal wind with the current localized unit', () {
      for (final value in <double>[0, 7.5]) {
        final data = formatter.format(
          weather: weather(wind: value),
          localizations: english,
          locale: const Locale('en'),
        );

        expect(data.windSpeedText, english.windSpeedValue(value));
        expect(
          data.windSemanticLabel,
          english.windSemantics(data.windSpeedText),
        );
      }
    });

    test('formats a local timestamp in English and Arabic', () {
      final timestamp = DateTime(2026, 7, 22, 18, 30);
      final en = formatter.format(
        weather: weather(lastUpdated: timestamp),
        localizations: english,
        locale: const Locale('en'),
      );
      final ar = formatter.format(
        weather: weather(lastUpdated: timestamp),
        localizations: arabic,
        locale: const Locale('ar'),
      );

      final expectedEn = DateFormat.yMMMd('en').add_jm().format(timestamp);
      final expectedAr = DateFormat.yMMMd('ar').add_jm().format(timestamp);
      expect(en.lastUpdatedText, 'Last updated: $expectedEn');
      expect(en.lastUpdatedSemanticLabel, 'Last updated, $expectedEn');
      expect(ar.lastUpdatedText, 'آخر تحديث: $expectedAr');
      expect(ar.lastUpdatedSemanticLabel, 'آخر تحديث، $expectedAr');
    });

    test('converts a UTC timestamp to local time before formatting', () {
      final timestamp = DateTime.utc(2026, 7, 22, 18, 30);
      final data = formatter.format(
        weather: weather(lastUpdated: timestamp),
        localizations: english,
        locale: const Locale('en'),
      );
      final expected = DateFormat.yMMMd(
        'en',
      ).add_jm().format(timestamp.toLocal());

      expect(data.lastUpdatedText, 'Last updated: $expected');
      expect(
        data.lastUpdatedText,
        isNot(contains(timestamp.toIso8601String())),
      );
    });

    test('builds all semantic labels from the final visible values', () {
      final data = formatter.format(
        weather: weather(),
        localizations: english,
        locale: const Locale('en'),
      );

      expect(data.locationSemanticLabel, contains(data.locationText));
      expect(data.conditionSemanticLabel, data.conditionText);
      expect(data.temperatureSemanticLabel, contains(data.temperatureText));
      expect(data.feelsLikeSemanticLabel, contains(data.feelsLikeText));
      expect(data.windSemanticLabel, contains(data.windSpeedText));
      expect(
        data.lastUpdatedSemanticLabel,
        contains(data.lastUpdatedText.replaceFirst('Last updated: ', '')),
      );
    });

    test('keeps only valid HTTP and HTTPS icon URLs', () {
      String? iconFor(String value) => formatter
          .format(
            weather: weather(iconUrl: value),
            localizations: english,
            locale: const Locale('en'),
          )
          .iconUrl;

      expect(iconFor(' https://example.com/icon.png '), contains('https://'));
      expect(iconFor('http://example.com/icon.png'), contains('http://'));
      expect(iconFor(''), isNull);
      expect(iconFor('not a URL'), isNull);
      expect(iconFor('ftp://example.com/icon.png'), isNull);
    });
  });
}
