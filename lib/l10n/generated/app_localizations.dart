import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather App'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Weather at a glance'**
  String get splashTagline;

  /// No description provided for @weatherInitialMessage.
  ///
  /// In en, this message translates to:
  /// **'Search for a city to view its current weather.'**
  String get weatherInitialMessage;

  /// No description provided for @cityInputLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityInputLabel;

  /// No description provided for @cityInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a city name'**
  String get cityInputHint;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButton;

  /// No description provided for @emptyCityValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a city name.'**
  String get emptyCityValidation;

  /// No description provided for @loadingWeather.
  ///
  /// In en, this message translates to:
  /// **'Fetching weather data...'**
  String get loadingWeather;

  /// No description provided for @cachedWeatherNotice.
  ///
  /// In en, this message translates to:
  /// **'Showing the last saved weather data.'**
  String get cachedWeatherNotice;

  /// No description provided for @cachedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Saved just now'**
  String get cachedJustNow;

  /// No description provided for @cachedOneMinuteAgo.
  ///
  /// In en, this message translates to:
  /// **'Saved 1 minute ago'**
  String get cachedOneMinuteAgo;

  /// No description provided for @cachedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Saved {minutes} minutes ago'**
  String cachedMinutesAgo(String minutes);

  /// No description provided for @cachedWeatherDetails.
  ///
  /// In en, this message translates to:
  /// **'Showing saved weather for {city}. {age}. It may not be current.'**
  String cachedWeatherDetails(String city, String age);

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @arabicLanguage.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabicLanguage;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// No description provided for @feelsLikeLabel.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get feelsLikeLabel;

  /// No description provided for @humidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityLabel;

  /// No description provided for @windSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Wind speed'**
  String get windSpeedLabel;

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdatedLabel;

  /// No description provided for @locationSemantics.
  ///
  /// In en, this message translates to:
  /// **'Location, {value}'**
  String locationSemantics(String value);

  /// No description provided for @temperatureSemantics.
  ///
  /// In en, this message translates to:
  /// **'Temperature, {value}'**
  String temperatureSemantics(String value);

  /// No description provided for @feelsLikeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Feels like, {value}'**
  String feelsLikeSemantics(String value);

  /// No description provided for @humiditySemantics.
  ///
  /// In en, this message translates to:
  /// **'Humidity, {value} percent'**
  String humiditySemantics(int value);

  /// No description provided for @windSemantics.
  ///
  /// In en, this message translates to:
  /// **'Wind speed, {value}'**
  String windSemantics(String value);

  /// No description provided for @lastUpdatedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Last updated, {value}'**
  String lastUpdatedSemantics(String value);

  /// Displays a temperature value in Celsius.
  ///
  /// In en, this message translates to:
  /// **'{value}°C'**
  String temperatureValue(num value);

  /// Displays the humidity percentage.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String humidityValue(int value);

  /// Displays wind speed in kilometers per hour.
  ///
  /// In en, this message translates to:
  /// **'{value} km/h'**
  String windSpeedValue(num value);

  /// No description provided for @invalidCityError.
  ///
  /// In en, this message translates to:
  /// **'City not found. Please check the city name.'**
  String get invalidCityError;

  /// No description provided for @noInternetError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection and try again.'**
  String get noInternetError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'The request took too long. Please try again.'**
  String get timeoutError;

  /// No description provided for @unauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'Unable to access the weather service.'**
  String get unauthorizedError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'The weather service is currently unavailable. Please try again later.'**
  String get serverError;

  /// No description provided for @cacheError.
  ///
  /// In en, this message translates to:
  /// **'The saved weather data could not be loaded.'**
  String get cacheError;

  /// No description provided for @configurationError.
  ///
  /// In en, this message translates to:
  /// **'The application is not configured correctly.'**
  String get configurationError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unknownError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
