import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/constants/api_constants.dart';
import 'package:weather_app/core/errors/app_exception.dart';
import 'package:weather_app/core/network/dio_client.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';
import 'package:weather_app/features/weather/data/services/weather_service.dart';

void main() {
  group('WeatherService', () {
    const testApiKey = 'test-api-key';

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

    late DioClient dioClient;
    late WeatherService weatherService;

    setUp(() {
      dioClient = DioClient();
      weatherService = WeatherService(dioClient: dioClient, apiKey: testApiKey);
    });

    test(
      'fetchCurrentWeather returns WeatherModel on successful request',
      () async {
        dioClient.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.path, ApiConstants.currentWeatherEndpoint);
              expect(options.queryParameters['key'], testApiKey);
              expect(options.queryParameters['q'], 'Cairo');

              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: apiJson,
                ),
              );
            },
          ),
        );

        final result = await weatherService.fetchCurrentWeather('Cairo');

        expect(result, WeatherModel.fromApiJson(apiJson));
      },
    );

    test('trims whitespace from city name before making request', () async {
      String? sentCity;

      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sentCity = options.queryParameters['q'] as String?;

            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: apiJson,
              ),
            );
          },
        ),
      );

      await weatherService.fetchCurrentWeather('  Cairo  ');

      expect(sentCity, 'Cairo');
    });

    test('adds lang=ar only for Arabic requests', () async {
      Object? sentLanguage;
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sentLanguage = options.queryParameters['lang'];
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: apiJson,
              ),
            );
          },
        ),
      );

      await weatherService.fetchCurrentWeather('Cairo', languageCode: 'ar');
      expect(sentLanguage, 'ar');

      dioClient.dio.interceptors.clear();
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sentLanguage = options.queryParameters['lang'];
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: apiJson,
              ),
            );
          },
        ),
      );
      await weatherService.fetchCurrentWeather('Cairo', languageCode: 'fr');
      expect(sentLanguage, isNull);
    });

    test(
      'throws BadRequestException when city name is empty after trim',
      () async {
        var requestMade = false;

        dioClient.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestMade = true;
              handler.next(options);
            },
          ),
        );

        expectLater(
          () => weatherService.fetchCurrentWeather('   '),
          throwsA(isA<BadRequestException>()),
        );

        expect(requestMade, isFalse);
      },
    );

    test(
      'throws ConfigurationException when API key is missing or empty',
      () async {
        var requestMade = false;
        final emptyKeyService = WeatherService(
          dioClient: dioClient,
          apiKey: '',
        );

        dioClient.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestMade = true;
              handler.next(options);
            },
          ),
        );

        expectLater(
          () => emptyKeyService.fetchCurrentWeather('Cairo'),
          throwsA(isA<ConfigurationException>()),
        );

        expect(requestMade, isFalse);
      },
    );

    test('maps DioException to AppException correctly on API error', () async {
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(requestOptions: options, statusCode: 400),
              ),
            );
          },
        ),
      );

      expectLater(
        () => weatherService.fetchCurrentWeather('UnknownCity'),
        throwsA(isA<BadRequestException>()),
      );
    });

    final transportCases = <DioExceptionType, Type>{
      DioExceptionType.connectionTimeout: TimeoutException,
      DioExceptionType.connectionError: NetworkException,
      DioExceptionType.cancel: UnknownException,
      DioExceptionType.unknown: UnknownException,
    };

    for (final entry in transportCases.entries) {
      test('does not leak ${entry.key} from WeatherService', () async {
        dioClient.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(requestOptions: options, type: entry.key),
            ),
          ),
        );

        await expectLater(
          weatherService.fetchCurrentWeather('Cairo'),
          throwsA(
            predicate<Object>(
              (error) =>
                  error.runtimeType == entry.value && error is! DioException,
            ),
          ),
        );
      });
    }

    final responseCases = <int, Type>{
      401: UnauthorizedException,
      404: NotFoundException,
      500: ServerException,
    };

    for (final entry in responseCases.entries) {
      test('maps HTTP ${entry.key} without leaking DioException', () async {
        dioClient.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Object?>(
                  requestOptions: options,
                  statusCode: entry.key,
                ),
              ),
            ),
          ),
        );

        await expectLater(
          weatherService.fetchCurrentWeather('Cairo'),
          throwsA(
            predicate<Object>(
              (error) =>
                  error.runtimeType == entry.value && error is! DioException,
            ),
          ),
        );
      });
    }

    test(
      'throws DataParsingException when response root is not an object',
      () async {
        dioClient.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <Object>[],
                ),
              );
            },
          ),
        );

        await expectLater(
          weatherService.fetchCurrentWeather('Cairo'),
          throwsA(isA<DataParsingException>()),
        );
      },
    );

    test(
      'throws DataParsingException for malformed successful payloads',
      () async {
        final malformedPayloads = <Map<String, dynamic>>[
          {'current': apiJson['current']},
          {'location': apiJson['location']},
          {
            'location': apiJson['location'],
            'current': {
              ...apiJson['current'] as Map<String, dynamic>,
              'temp_c': '30',
            },
          },
          {
            'location': {'name': 123, 'country': 'Egypt'},
            'current': apiJson['current'],
          },
        ];

        for (final payload in malformedPayloads) {
          dioClient.dio.interceptors.clear();
          dioClient.dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: payload,
                  ),
                );
              },
            ),
          );

          await expectLater(
            weatherService.fetchCurrentWeather('Cairo'),
            throwsA(isA<DataParsingException>()),
          );
        }
      },
    );
  });
}
