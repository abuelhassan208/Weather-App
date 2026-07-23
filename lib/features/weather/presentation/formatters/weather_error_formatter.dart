import '../../../../l10n/generated/app_localizations.dart';
import '../../logic/bloc/weather_state.dart';
import '../models/weather_error_data.dart';

final class WeatherErrorFormatter {
  const WeatherErrorFormatter();

  WeatherErrorData format({
    required WeatherFailureType failureType,
    required AppLocalizations localizations,
  }) {
    final message = switch (failureType) {
      WeatherFailureType.invalidCity => localizations.invalidCityError,
      WeatherFailureType.noInternet => localizations.noInternetError,
      WeatherFailureType.timeout => localizations.timeoutError,
      WeatherFailureType.unauthorized => localizations.unauthorizedError,
      WeatherFailureType.server => localizations.serverError,
      WeatherFailureType.cache => localizations.cacheError,
      WeatherFailureType.configuration => localizations.configurationError,
      WeatherFailureType.unknown => localizations.unknownError,
    };

    return WeatherErrorData(
      message: message,
      retryLabel: localizations.tryAgainButton,
    );
  }
}
