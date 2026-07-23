import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/presentation/formatters/cached_weather_notice_formatter.dart';
import 'package:weather_app/l10n/generated/app_localizations_ar.dart';
import 'package:weather_app/l10n/generated/app_localizations_en.dart';

void main() {
  group('CachedWeatherNoticeFormatter', () {
    const formatter = CachedWeatherNoticeFormatter();
    final now = DateTime.utc(2026, 7, 23, 12);
    final english = AppLocalizationsEn();
    final arabic = AppLocalizationsAr();

    test('formats current, sub-minute, and future timestamps as just now', () {
      for (final cachedAt in [
        now,
        now.subtract(const Duration(seconds: 59)),
        now.add(const Duration(minutes: 5)),
      ]) {
        final data = formatter.format(
          city: 'Cairo',
          cachedAt: cachedAt,
          now: now,
          localizations: english,
          locale: const Locale('en'),
        );

        expect(data.message, contains('Cairo'));
        expect(data.message, contains('Saved just now'));
      }
    });

    test('uses the singular message for exactly one minute', () {
      final data = formatter.format(
        city: 'Cairo',
        cachedAt: now.subtract(const Duration(minutes: 1)),
        now: now,
        localizations: english,
        locale: const Locale('en'),
      );

      expect(data.message, contains('Saved 1 minute ago'));
    });

    test('formats two and several minutes using the plural message', () {
      for (final minutes in [2, 17]) {
        final data = formatter.format(
          city: 'Cairo',
          cachedAt: now.subtract(Duration(minutes: minutes)),
          now: now,
          localizations: english,
          locale: const Locale('en'),
        );

        expect(data.message, contains('Saved $minutes minutes ago'));
      }
    });

    test('does not cap ages older than thirty minutes', () {
      final data = formatter.format(
        city: 'Cairo',
        cachedAt: now.subtract(const Duration(minutes: 75)),
        now: now,
        localizations: english,
        locale: const Locale('en'),
      );

      expect(data.message, contains('Saved 75 minutes ago'));
      expect(data.message, isNot(contains('Saved 30 minutes ago')));
    });

    test('formats an Arabic city and age with Arabic localization', () {
      final data = formatter.format(
        city: 'القاهرة',
        cachedAt: now.subtract(const Duration(minutes: 12)),
        now: now,
        localizations: arabic,
        locale: const Locale('ar'),
      );

      expect(data.message, contains('القاهرة'));
      expect(data.message, contains('تم الحفظ منذ 12 دقائق'));
    });

    test('uses the Arabic singular message for one minute', () {
      final data = formatter.format(
        city: 'القاهرة',
        cachedAt: now.subtract(const Duration(minutes: 1)),
        now: now,
        localizations: arabic,
        locale: const Locale('ar'),
      );

      expect(data.message, contains('تم الحفظ منذ دقيقة واحدة'));
    });
  });
}
