import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/errors/app_exception.dart';
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
        'last_updated_epoch': 1784743200,
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
      expect(
        weather.lastUpdated,
        DateTime.fromMillisecondsSinceEpoch(1784743200000, isUtc: true),
      );
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

    test('accepts int and double numbers and trims required text', () {
      final weather = WeatherModel.fromApiJson({
        'location': {'name': '  Cairo  ', 'country': '  Egypt  '},
        'current': {
          'temp_c': 30,
          'feelslike_c': 31.5,
          'humidity': 40.0,
          'wind_kph': 10,
          'last_updated_epoch': 1784800800,
          'condition': {'text': '  Sunny  ', 'icon': ''},
        },
      });

      expect(weather.cityName, 'Cairo');
      expect(weather.country, 'Egypt');
      expect(weather.temperatureC, 30.0);
      expect(weather.feelsLikeC, 31.5);
      expect(weather.humidity, 40);
      expect(weather.windKph, 10.0);
      expect(weather.conditionText, 'Sunny');
      expect(
        weather.lastUpdated,
        DateTime.fromMillisecondsSinceEpoch(1784800800000, isUtc: true),
      );
    });

    for (final structure in ['location', 'current']) {
      test('rejects missing $structure object', () {
        final json = Map<String, dynamic>.from(apiJson)..remove(structure);

        expect(
          () => WeatherModel.fromApiJson(json),
          throwsA(isA<DataParsingException>()),
        );
      });

      test('rejects non-object $structure', () {
        final json = Map<String, dynamic>.from(apiJson)
          ..[structure] = <Object>[];

        expect(
          () => WeatherModel.fromApiJson(json),
          throwsA(isA<DataParsingException>()),
        );
      });
    }

    test('rejects missing or non-object condition', () {
      for (final value in <Object?>[null, <Object>[]]) {
        final json = _apiPayloadWithCurrent({'condition': value});

        expect(
          () => WeatherModel.fromApiJson(json),
          throwsA(isA<DataParsingException>()),
        );
      }
    });

    test('rejects every missing required API field', () {
      final cases = <Map<String, dynamic>>[
        {
          'location': {'country': 'Egypt'},
        },
        {'current': _currentWithout('temp_c')},
        {'current': _currentWithout('feelslike_c')},
        {'current': _currentWithout('humidity')},
        {'current': _currentWithout('wind_kph')},
        {'current': _currentWithout('last_updated_epoch')},
        {
          'current': {
            ..._validCurrent(),
            'condition': {'icon': ''},
          },
        },
      ];

      for (final changes in cases) {
        final json = _validApiJson()..addAll(changes);
        expect(
          () => WeatherModel.fromApiJson(json),
          throwsA(isA<DataParsingException>()),
        );
      }
    });

    test('rejects null required API fields', () {
      for (final key in [
        'temp_c',
        'feelslike_c',
        'humidity',
        'wind_kph',
        'last_updated_epoch',
      ]) {
        expect(
          () => WeatherModel.fromApiJson(_apiPayloadWithCurrent({key: null})),
          throwsA(isA<DataParsingException>()),
        );
      }
    });

    test('rejects wrong API field types', () {
      final invalidPayloads = [
        {
          'location': {'name': 123, 'country': 'Egypt'},
        },
        {'current': _validCurrent()..['temp_c'] = '30'},
        {'current': _validCurrent()..['humidity'] = 40.5},
        {'current': _validCurrent()..['wind_kph'] = '10'},
        {'current': _validCurrent()..['last_updated_epoch'] = 'invalid'},
        {
          'current': _validCurrent()
            ..['condition'] = {'text': 'Sunny', 'icon': <String, Object>{}},
        },
      ];

      for (final changes in invalidPayloads) {
        final json = _validApiJson()..addAll(changes);
        expect(
          () => WeatherModel.fromApiJson(json),
          throwsA(isA<DataParsingException>()),
        );
      }
    });

    test('rejects invalid required text and numeric values', () {
      final invalidPayloads = [
        {
          'location': {'name': '   ', 'country': 'Egypt'},
        },
        {
          'current': _validCurrent()..['condition'] = {'text': ' ', 'icon': ''},
        },
        {'current': _validCurrent()..['humidity'] = -1},
        {'current': _validCurrent()..['humidity'] = 101},
        {'current': _validCurrent()..['wind_kph'] = -5},
        {'current': _validCurrent()..['temp_c'] = double.nan},
        {'current': _validCurrent()..['feelslike_c'] = double.infinity},
        {'current': _validCurrent()..['wind_kph'] = double.negativeInfinity},
      ];

      for (final changes in invalidPayloads) {
        final json = _validApiJson()..addAll(changes);
        expect(
          () => WeatherModel.fromApiJson(json),
          throwsA(isA<DataParsingException>()),
        );
      }
    });

    test('allows missing, null, or empty optional country and icon', () {
      for (final optionalValue in <String?>[null, '']) {
        final json = _validApiJson();
        final location = Map<String, dynamic>.from(json['location'] as Map);
        final current = Map<String, dynamic>.from(json['current'] as Map);
        final condition = Map<String, dynamic>.from(
          current['condition'] as Map,
        );
        location['country'] = optionalValue;
        condition['icon'] = optionalValue;
        current['condition'] = condition;
        json['location'] = location;
        json['current'] = current;

        final weather = WeatherModel.fromApiJson(json);
        expect(weather.country, '');
        expect(weather.iconUrl, '');
      }
    });

    test('strict cache parsing rejects missing, wrong, and invalid fields', () {
      final valid = WeatherModel.fromApiJson(apiJson).toJson();
      final invalidPayloads = [
        Map<String, dynamic>.from(valid)..remove('temperatureC'),
        Map<String, dynamic>.from(valid)..['cityName'] = null,
        Map<String, dynamic>.from(valid)..['temperatureC'] = '28.5',
        Map<String, dynamic>.from(valid)..['humidity'] = 40.5,
        Map<String, dynamic>.from(valid)..['humidity'] = 101,
        Map<String, dynamic>.from(valid)..['windKph'] = -1,
        Map<String, dynamic>.from(valid)..['temperatureC'] = double.nan,
        Map<String, dynamic>.from(valid)..['conditionText'] = ' ',
      ];

      for (final json in invalidPayloads) {
        expect(
          () => WeatherModel.fromCacheJson(json),
          throwsA(isA<DataParsingException>()),
        );
      }
    });

    test(
      'cache parsing allows optional fields but rejects their wrong types',
      () {
        final valid = WeatherModel.fromApiJson(apiJson).toJson();
        valid.remove('country');
        valid.remove('iconUrl');

        final weather = WeatherModel.fromCacheJson(valid);
        expect(weather.country, '');
        expect(weather.iconUrl, '');

        expect(
          () => WeatherModel.fromCacheJson({...valid, 'iconUrl': 123}),
          throwsA(isA<DataParsingException>()),
        );
      },
    );
  });
}

Map<String, dynamic> _validApiJson() => {
  'location': {'name': 'Cairo', 'country': 'Egypt'},
  'current': _validCurrent(),
};

Map<String, dynamic> _validCurrent() => {
  'temp_c': 28.5,
  'feelslike_c': 30.0,
  'humidity': 45,
  'wind_kph': 12.6,
  'last_updated': '2026-07-22 18:00',
  'last_updated_epoch': 1784743200,
  'condition': {'text': 'Partly cloudy', 'icon': ''},
};

Map<String, dynamic> _currentWithout(String key) =>
    _validCurrent()..remove(key);

Map<String, dynamic> _apiPayloadWithCurrent(Map<String, dynamic> changes) => {
  'location': {'name': 'Cairo', 'country': 'Egypt'},
  'current': _validCurrent()..addAll(changes),
};
