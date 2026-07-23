import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/weather_model.dart';

class WeatherService {
  // Allow injecting an API key so unit tests do not depend on the local .env file.
  WeatherService({required this.dioClient, String? apiKey})
    : _apiKey = apiKey ?? dotenv.env['WEATHER_API_KEY'] ?? '';

  final DioClient dioClient;
  final String _apiKey;

  Future<WeatherModel> fetchCurrentWeather(
    String city, {
    String languageCode = 'en',
  }) async {
    final normalizedCity = city.trim();

    if (normalizedCity.isEmpty) {
      throw const BadRequestException('City name cannot be empty.');
    }

    if (_apiKey.trim().isEmpty) {
      throw const ConfigurationException('WEATHER_API_KEY is missing.');
    }

    try {
      final response = await dioClient.dio.get<Object?>(
        ApiConstants.currentWeatherEndpoint,
        queryParameters: {
          'key': _apiKey,
          'q': normalizedCity,
          if (languageCode == 'ar') 'lang': 'ar',
        },
      );

      final data = response.data;

      if (data is! Map) {
        throw const DataParsingException(
          'Invalid weather API payload: response root must be an object.',
        );
      }

      try {
        return WeatherModel.fromApiJson(Map<String, dynamic>.from(data));
      } on DataParsingException {
        rethrow;
      } catch (_) {
        throw const DataParsingException(
          'Invalid weather API payload: response keys must be strings.',
        );
      }
    } on DioException catch (exception) {
      throw dioClient.mapDioException(exception);
    }
  }
}
