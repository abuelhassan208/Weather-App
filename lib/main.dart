import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/dio_client.dart';
import 'core/network/internet_connection_service.dart';
import 'features/weather/data/repositories/weather_repository.dart';
import 'features/weather/data/services/weather_cache_service.dart';
import 'features/weather/data/services/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before starting the application.
  await dotenv.load(fileName: '.env');

  // Create and connect the app dependencies in one composition root.
  final preferences = await SharedPreferences.getInstance();
  final dioClient = DioClient();

  final weatherRepository = WeatherRepository(
    weatherService: WeatherService(dioClient: dioClient),
    cacheService: WeatherCacheService(preferences: preferences),
    connectionService: InternetConnectionService(),
  );

  runApp(WeatherApp(weatherRepository: weatherRepository));
}
