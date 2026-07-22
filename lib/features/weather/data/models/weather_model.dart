import 'package:equatable/equatable.dart';

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
  final String lastUpdated;

  factory WeatherModel.fromApiJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final condition = current['condition'] as Map<String, dynamic>? ?? {};

    return WeatherModel(
      cityName: location['name']?.toString() ?? '',
      country: location['country']?.toString() ?? '',
      temperatureC: (current['temp_c'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (current['feelslike_c'] as num?)?.toDouble() ?? 0,
      conditionText: condition['text']?.toString() ?? '',
      iconUrl: _normalizeIconUrl(condition['icon']?.toString() ?? ''),
      humidity: (current['humidity'] as num?)?.toInt() ?? 0,
      windKph: (current['wind_kph'] as num?)?.toDouble() ?? 0,
      lastUpdated: current['last_updated']?.toString() ?? '',
    );
  }

  factory WeatherModel.fromCacheJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['cityName']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      temperatureC: (json['temperatureC'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (json['feelsLikeC'] as num?)?.toDouble() ?? 0,
      conditionText: json['conditionText']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString() ?? '',
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      windKph: (json['windKph'] as num?)?.toDouble() ?? 0,
      lastUpdated: json['lastUpdated']?.toString() ?? '',
    );
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
      'lastUpdated': lastUpdated,
    };
  }

  // Prepend https: scheme if icon URL returned by WeatherAPI begins with //
  static String _normalizeIconUrl(String iconUrl) {
    if (iconUrl.startsWith('//')) {
      return 'https:$iconUrl';
    }

    return iconUrl;
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
