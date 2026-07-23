import 'dart:ui';

import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../models/cached_weather_notice_data.dart';

final class CachedWeatherNoticeFormatter {
  const CachedWeatherNoticeFormatter();

  CachedWeatherNoticeData format({
    required String city,
    required DateTime cachedAt,
    required DateTime now,
    required AppLocalizations localizations,
    required Locale locale,
  }) {
    final age = now.toUtc().difference(cachedAt.toUtc());
    final safeMinutes = age.isNegative ? 0 : age.inMinutes;
    final ageText = switch (safeMinutes) {
      < 1 => localizations.cachedJustNow,
      1 => localizations.cachedOneMinuteAgo,
      _ => localizations.cachedMinutesAgo(
        NumberFormat.decimalPattern(locale.toLanguageTag()).format(safeMinutes),
      ),
    };

    return CachedWeatherNoticeData(
      message: localizations.cachedWeatherDetails(city, ageText),
    );
  }
}
