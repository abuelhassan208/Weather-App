final class WeatherCardData {
  const WeatherCardData({
    required this.locationText,
    required this.conditionText,
    required this.temperatureText,
    required this.feelsLikeLabel,
    required this.feelsLikeText,
    required this.humidityLabel,
    required this.humidityText,
    required this.windSpeedLabel,
    required this.windSpeedText,
    required this.lastUpdatedText,
    required this.locationSemanticLabel,
    required this.conditionSemanticLabel,
    required this.temperatureSemanticLabel,
    required this.feelsLikeSemanticLabel,
    required this.humiditySemanticLabel,
    required this.windSemanticLabel,
    required this.lastUpdatedSemanticLabel,
    this.iconUrl,
  });

  final String locationText;
  final String conditionText;
  final String temperatureText;
  final String feelsLikeLabel;
  final String feelsLikeText;
  final String humidityLabel;
  final String humidityText;
  final String windSpeedLabel;
  final String windSpeedText;
  final String lastUpdatedText;
  final String locationSemanticLabel;
  final String conditionSemanticLabel;
  final String temperatureSemanticLabel;
  final String feelsLikeSemanticLabel;
  final String humiditySemanticLabel;
  final String windSemanticLabel;
  final String lastUpdatedSemanticLabel;
  final String? iconUrl;
}
