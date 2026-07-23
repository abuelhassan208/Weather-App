import 'package:equatable/equatable.dart';

import 'weather_model.dart';

class WeatherCacheEntry extends Equatable {
  const WeatherCacheEntry({
    required this.schemaVersion,
    required this.normalizedCity,
    required this.languageCode,
    required this.cachedAt,
    required this.weather,
  });

  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final String normalizedCity;
  final String languageCode;
  final DateTime cachedAt;
  final WeatherModel weather;

  factory WeatherCacheEntry.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    final normalizedCity = json['normalizedCity'];
    final languageCode = json['languageCode'];
    final cachedAtValue = json['cachedAt'];
    final weatherValue = json['weather'];

    if (schemaVersion is! int ||
        normalizedCity is! String ||
        normalizedCity.isEmpty ||
        languageCode is! String ||
        languageCode.isEmpty ||
        cachedAtValue is! String ||
        weatherValue is! Map) {
      throw const FormatException('Invalid weather cache metadata.');
    }

    final cachedAt = DateTime.tryParse(cachedAtValue);
    if (cachedAt == null) {
      throw const FormatException('Invalid weather cache timestamp.');
    }

    final weatherJson = Map<String, dynamic>.from(weatherValue);

    return WeatherCacheEntry(
      schemaVersion: schemaVersion,
      normalizedCity: normalizedCity,
      languageCode: languageCode,
      cachedAt: cachedAt.toUtc(),
      weather: WeatherModel.fromCacheJson(weatherJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'normalizedCity': normalizedCity,
      'languageCode': languageCode,
      'cachedAt': cachedAt.toUtc().toIso8601String(),
      'weather': weather.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    schemaVersion,
    normalizedCity,
    languageCode,
    cachedAt,
    weather,
  ];
}
