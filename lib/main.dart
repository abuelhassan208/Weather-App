import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/logging/app_logger_impl.dart';
import 'core/network/dio_client.dart';
import 'core/network/internet_connection_service.dart';
import 'core/observers/app_bloc_observer.dart';
import 'features/weather/data/repositories/weather_repository.dart';
import 'features/weather/data/services/weather_cache_service.dart';
import 'features/weather/data/services/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before starting the application.
  await dotenv.load(fileName: '.env');

  // Create and connect the app dependencies in one composition root.
  final appLogger = AppLoggerImpl();
  Bloc.observer = AppBlocObserver(logger: appLogger);
  appLogger.info('Application dependencies initializing');
  final preferences = await SharedPreferences.getInstance();
  final dioClient = DioClient(logger: appLogger);

  final weatherRepository = WeatherRepository(
    weatherService: WeatherService(dioClient: dioClient),
    cacheService: WeatherCacheService(
      preferences: preferences,
      logger: appLogger,
    ),
    connectionService: InternetConnectionService(),
    logger: appLogger,
  );

  appLogger.info('Application UI starting');
  runApp(
    WeatherApp(weatherRepository: weatherRepository, preferences: preferences),
  );
}
