import 'dart:ui';

import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/weather_model.dart';
import '../models/weather_card_data.dart';

final class WeatherCardFormatter {
  const WeatherCardFormatter();

  WeatherCardData format({
    required WeatherModel weather,
    required AppLocalizations localizations,
    required Locale locale,
  }) {
    final locationText = _formatLocation(weather.cityName, weather.country);
    final conditionText = _nonEmptyOrFallback(weather.conditionText);
    final temperatureText = localizations.temperatureValue(
      weather.temperatureC,
    );
    final feelsLikeText = localizations.temperatureValue(weather.feelsLikeC);
    final humidityText = localizations.humidityValue(weather.humidity);
    final windSpeedText = localizations.windSpeedValue(weather.windKph);
    final formattedTimestamp = DateFormat.yMMMd(
      locale.toLanguageTag(),
    ).add_jm().format(weather.lastUpdated.toLocal());
    final lastUpdatedText =
        '${localizations.lastUpdatedLabel}: $formattedTimestamp';

    return WeatherCardData(
      locationText: locationText,
      conditionText: conditionText,
      temperatureText: temperatureText,
      feelsLikeLabel: localizations.feelsLikeLabel,
      feelsLikeText: feelsLikeText,
      humidityLabel: localizations.humidityLabel,
      humidityText: humidityText,
      windSpeedLabel: localizations.windSpeedLabel,
      windSpeedText: windSpeedText,
      lastUpdatedText: lastUpdatedText,
      locationSemanticLabel: localizations.locationSemantics(locationText),
      conditionSemanticLabel: conditionText,
      temperatureSemanticLabel: localizations.temperatureSemantics(
        temperatureText,
      ),
      feelsLikeSemanticLabel: localizations.feelsLikeSemantics(feelsLikeText),
      humiditySemanticLabel: localizations.humiditySemantics(weather.humidity),
      windSemanticLabel: localizations.windSemantics(windSpeedText),
      lastUpdatedSemanticLabel: localizations.lastUpdatedSemantics(
        formattedTimestamp,
      ),
      iconUrl: _validIconUrlOrNull(weather.iconUrl),
    );
  }

  String _formatLocation(String city, String country) {
    final parts = [
      city.trim(),
      country.trim(),
    ].where((part) => part.isNotEmpty);
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  String _nonEmptyOrFallback(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String? _validIconUrlOrNull(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
