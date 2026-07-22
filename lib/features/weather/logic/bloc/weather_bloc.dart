import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/weather_repository.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  // Expose an error type so the UI can select the correct localized message.
  WeatherBloc({required this.repository}) : super(const WeatherInitial()) {
    on<WeatherRequested>(_onWeatherRequested);
  }

  final WeatherRepository repository;

  Future<void> _onWeatherRequested(
    WeatherRequested event,
    Emitter<WeatherState> emit,
  ) async {
    emit(const WeatherLoading());

    try {
      final result = await repository.getCurrentWeather(event.city);

      emit(
        WeatherSuccess(
          weather: result.weather,
          isFromCache: result.isFromCache,
        ),
      );
    } on BadRequestException {
      emit(const WeatherFailure(type: WeatherFailureType.invalidCity));
    } on NotFoundException {
      emit(const WeatherFailure(type: WeatherFailureType.invalidCity));
    } on NetworkException {
      emit(const WeatherFailure(type: WeatherFailureType.noInternet));
    } on TimeoutException {
      emit(const WeatherFailure(type: WeatherFailureType.timeout));
    } on UnauthorizedException {
      emit(const WeatherFailure(type: WeatherFailureType.unauthorized));
    } on ServerException {
      emit(const WeatherFailure(type: WeatherFailureType.server));
    } on CacheException {
      emit(const WeatherFailure(type: WeatherFailureType.cache));
    } on ConfigurationException {
      emit(const WeatherFailure(type: WeatherFailureType.configuration));
    } on AppException {
      emit(const WeatherFailure(type: WeatherFailureType.unknown));
    } catch (_) {
      emit(const WeatherFailure(type: WeatherFailureType.unknown));
    }
  }
}
