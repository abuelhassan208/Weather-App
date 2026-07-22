import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';

void main() {
  group('WeatherModel', () {
    final apiJson = <String, dynamic>{
      'location': {'name': 'Cairo', 'country': 'Egypt'},
      'current': {
        'temp_c': 28.5,
        'feelslike_c': 30.0,
        'humidity': 45,
        'wind_kph': 12.6,
        'last_updated': '2026-07-22 18:00',
        'condition': {
          'text': 'Partly cloudy',
          'icon': '//cdn.weatherapi.com/weather/64x64/day/116.png',
        },
      },
    };

    test('fromApiJson converts WeatherAPI response correctly', () {
      final weather = WeatherModel.fromApiJson(apiJson);

      expect(weather.cityName, 'Cairo');
      expect(weather.country, 'Egypt');
      expect(weather.temperatureC, 28.5);
      expect(weather.feelsLikeC, 30.0);
      expect(weather.humidity, 45);
      expect(weather.windKph, 12.6);
      expect(weather.lastUpdated, '2026-07-22 18:00');
      expect(weather.conditionText, 'Partly cloudy');
      expect(
        weather.iconUrl,
        'https://cdn.weatherapi.com/weather/64x64/day/116.png',
      );
    });

    test('normalizes icon URL starting with // to https://', () {
      final weather = WeatherModel.fromApiJson(apiJson);

      expect(weather.iconUrl.startsWith('https://'), isTrue);
    });

    test('toJson and fromCacheJson maintain object equality', () {
      final originalWeather = WeatherModel.fromApiJson(apiJson);
      final jsonMap = originalWeather.toJson();
      final restoredWeather = WeatherModel.fromCacheJson(jsonMap);

      expect(restoredWeather, originalWeather);
    });

    test('handles missing or null json fields with safe defaults', () {
      final emptyWeather = WeatherModel.fromApiJson(const {});

      expect(emptyWeather.cityName, '');
      expect(emptyWeather.country, '');
      expect(emptyWeather.temperatureC, 0.0);
      expect(emptyWeather.feelsLikeC, 0.0);
      expect(emptyWeather.conditionText, '');
      expect(emptyWeather.iconUrl, '');
      expect(emptyWeather.humidity, 0);
      expect(emptyWeather.windKph, 0.0);
      expect(emptyWeather.lastUpdated, '');
    });
  });
}
