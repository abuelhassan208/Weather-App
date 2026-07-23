import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_exception.dart';

class WeatherModel extends Equatable {
  const WeatherModel({
    required this.cityName,
    required this.country,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.conditionText,
    required this.iconUrl,
    required this.humidity,
    required this.windKph,
    required this.lastUpdated,
  });

  final String cityName;
  final String country;
  final double temperatureC;
  final double feelsLikeC;
  final String conditionText;
  final String iconUrl;
  final int humidity;
  final double windKph;
  final DateTime lastUpdated;

  factory WeatherModel.fromApiJson(Map<String, dynamic> json) {
    try {
      final location = _requireMap(json, 'location', 'location');
      final current = _requireMap(json, 'current', 'current');
      final condition = _requireMap(current, 'condition', 'current.condition');

      return WeatherModel(
        cityName: _requireString(location, 'name', 'location.name'),
        country: _optionalString(location, 'country', 'location.country'),
        temperatureC: _requireFiniteDouble(current, 'temp_c', 'current.temp_c'),
        feelsLikeC: _requireFiniteDouble(
          current,
          'feelslike_c',
          'current.feelslike_c',
        ),
        conditionText: _requireString(
          condition,
          'text',
          'current.condition.text',
        ),
        iconUrl: _normalizeIconUrl(
          _optionalString(condition, 'icon', 'current.condition.icon'),
        ),
        humidity: _requireHumidity(current, 'humidity', 'current.humidity'),
        windKph: _requireNonNegativeDouble(
          current,
          'wind_kph',
          'current.wind_kph',
        ),
        lastUpdated: _requireEpochDateTime(
          current,
          'last_updated_epoch',
          'current.last_updated_epoch',
        ),
      );
    } on DataParsingException {
      rethrow;
    } catch (_) {
      throw const DataParsingException('Invalid weather API payload.');
    }
  }

  factory WeatherModel.fromCacheJson(Map<String, dynamic> json) {
    try {
      return WeatherModel(
        cityName: _requireString(json, 'cityName', 'weather.cityName'),
        country: _optionalString(json, 'country', 'weather.country'),
        temperatureC: _requireFiniteDouble(
          json,
          'temperatureC',
          'weather.temperatureC',
        ),
        feelsLikeC: _requireFiniteDouble(
          json,
          'feelsLikeC',
          'weather.feelsLikeC',
        ),
        conditionText: _requireString(
          json,
          'conditionText',
          'weather.conditionText',
        ),
        iconUrl: _optionalString(json, 'iconUrl', 'weather.iconUrl'),
        humidity: _requireHumidity(json, 'humidity', 'weather.humidity'),
        windKph: _requireNonNegativeDouble(json, 'windKph', 'weather.windKph'),
        lastUpdated: _requireDateTime(
          json,
          'lastUpdated',
          'weather.lastUpdated',
        ),
      );
    } on DataParsingException {
      rethrow;
    } catch (_) {
      throw const DataParsingException('Invalid cached weather payload.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'country': country,
      'temperatureC': temperatureC,
      'feelsLikeC': feelsLikeC,
      'conditionText': conditionText,
      'iconUrl': iconUrl,
      'humidity': humidity,
      'windKph': windKph,
      'lastUpdated': lastUpdated.toUtc().toIso8601String(),
    };
  }

  // Prepend https: scheme if icon URL returned by WeatherAPI begins with //
  static String _normalizeIconUrl(String iconUrl) {
    if (iconUrl.startsWith('//')) {
      return 'https:$iconUrl';
    }

    return iconUrl;
  }

  static Map<String, dynamic> _requireMap(
    Map<String, dynamic> source,
    String key,
    String path,
  ) {
    final value = source[key];
    if (value is! Map) {
      throw DataParsingException(
        'Invalid weather payload: $path must be an object.',
      );
    }

    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      throw DataParsingException(
        'Invalid weather payload: $path must use string keys.',
      );
    }
  }

  static String _requireString(
    Map<String, dynamic> source,
    String key,
    String path,
  ) {
    final value = source[key];
    if (value is! String || value.trim().isEmpty) {
      throw DataParsingException(
        'Invalid weather payload: $path must be a non-empty string.',
      );
    }

    return value.trim();
  }

  static String _optionalString(
    Map<String, dynamic> source,
    String key,
    String path,
  ) {
    final value = source[key];
    if (value == null) {
      return '';
    }
    if (value is! String) {
      throw DataParsingException(
        'Invalid weather payload: $path must be a string when present.',
      );
    }

    return value.trim();
  }

  static double _requireFiniteDouble(
    Map<String, dynamic> source,
    String key,
    String path,
  ) {
    final value = source[key];
    if (value is! num || !value.isFinite) {
      throw DataParsingException(
        'Invalid weather payload: $path must be a finite number.',
      );
    }

    return value.toDouble();
  }

  static double _requireNonNegativeDouble(
    Map<String, dynamic> source,
    String key,
    String path,
  ) {
    final value = _requireFiniteDouble(source, key, path);
    if (value < 0) {
      throw DataParsingException(
        'Invalid weather payload: $path must not be negative.',
      );
    }

    return value;
  }

  static int _requireHumidity(
    Map<String, dynamic> source,
    String key,
    String path,
  ) {
    final value = source[key];
    if (value is! num ||
        !value.isFinite ||
        value != value.truncateToDouble() ||
        value < 0 ||
        value > 100) {
      throw DataParsingException(
        'Invalid weather payload: $path must be an integer from 0 to 100.',
      );
    }

    return value.toInt();
  }

  static DateTime _requireEpochDateTime(
    Map<String, dynamic> source,
    String key,
    String path,
  ) {
    final value = source[key];
    if (value is! num || !value.isFinite || value != value.truncateToDouble()) {
      throw DataParsingException(
        'Invalid weather payload: $path must be an integer epoch.',
      );
    }
    return DateTime.fromMillisecondsSinceEpoch(
      value.toInt() * Duration.millisecondsPerSecond,
      isUtc: true,
    );
  }

  static DateTime _requireDateTime(
    Map<String, dynamic> source,
    String key,
    String path,
  ) {
    final value = source[key];
    if (value is! String) {
      throw DataParsingException(
        'Invalid weather payload: $path must be an ISO-8601 string.',
      );
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw DataParsingException(
        'Invalid weather payload: $path must be an ISO-8601 string.',
      );
    }
    return parsed.toUtc();
  }

  @override
  List<Object?> get props => [
    cityName,
    country,
    temperatureC,
    feelsLikeC,
    conditionText,
    iconUrl,
    humidity,
    windKph,
    lastUpdated,
  ];
}
