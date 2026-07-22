// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Weather App';

  @override
  String get foundationReady => 'Weather app foundation is ready';

  @override
  String get weatherInitialMessage =>
      'Search for a city to view its current weather.';

  @override
  String get cityInputLabel => 'City';

  @override
  String get cityInputHint => 'Enter a city name';

  @override
  String get searchButton => 'Search';

  @override
  String get loadingWeather => 'Fetching weather data...';

  @override
  String get cachedWeatherNotice => 'Showing the last saved weather data.';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get temperatureLabel => 'Temperature';

  @override
  String get feelsLikeLabel => 'Feels like';

  @override
  String get humidityLabel => 'Humidity';

  @override
  String get windSpeedLabel => 'Wind speed';

  @override
  String get lastUpdatedLabel => 'Last updated';

  @override
  String temperatureValue(num value) {
    return '$value°C';
  }

  @override
  String humidityValue(int value) {
    return '$value%';
  }

  @override
  String windSpeedValue(num value) {
    return '$value km/h';
  }

  @override
  String get invalidCityError => 'City not found. Please check the city name.';

  @override
  String get noInternetError =>
      'No internet connection. Please check your connection and try again.';

  @override
  String get timeoutError => 'The request took too long. Please try again.';

  @override
  String get unauthorizedError => 'Unable to access the weather service.';

  @override
  String get serverError =>
      'The weather service is currently unavailable. Please try again later.';

  @override
  String get cacheError => 'The saved weather data could not be loaded.';

  @override
  String get configurationError =>
      'The application is not configured correctly.';

  @override
  String get unknownError => 'Something went wrong. Please try again.';
}
