abstract final class ApiConstants {
  static const String baseUrl = 'https://api.weatherapi.com/v1/';
  static const String currentWeatherEndpoint = 'current.json';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);
}
