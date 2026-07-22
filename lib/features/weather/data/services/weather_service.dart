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

  Future<WeatherModel> fetchCurrentWeather(String city) async {
    final normalizedCity = city.trim();

    if (normalizedCity.isEmpty) {
      throw const BadRequestException('City name cannot be empty.');
    }

    if (_apiKey.trim().isEmpty) {
      throw const ConfigurationException('WEATHER_API_KEY is missing.');
    }

    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        ApiConstants.currentWeatherEndpoint,
        queryParameters: {'key': _apiKey, 'q': normalizedCity},
      );

      final data = response.data;

      if (data == null) {
        throw const UnknownException(
          'The weather service returned an empty response.',
        );
      }

      return WeatherModel.fromApiJson(data);
    } on DioException catch (exception) {
      throw dioClient.mapDioException(exception);
    }
  }
}
