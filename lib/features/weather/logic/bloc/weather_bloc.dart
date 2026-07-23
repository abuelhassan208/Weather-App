import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/weather_repository.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  // Expose an error type so the UI can select the correct localized message.
  WeatherBloc({required this.repository}) : super(const WeatherInitial()) {
    on<WeatherEvent>(_onWeatherEvent, transformer: restartable());
  }

  final WeatherRepository repository;
  WeatherRequested? _lastRequest;

  Future<void> _onWeatherEvent(
    WeatherEvent event,
    Emitter<WeatherState> emit,
  ) async {
    final request = switch (event) {
      WeatherRequested() => event,
      WeatherRetryRequested() => _lastRequest,
    };

    if (request == null) {
      return;
    }

    if (event is WeatherRequested) {
      _lastRequest = request;
    }

    await _executeRequest(request, emit);
  }

  Future<void> _executeRequest(
    WeatherRequested request,
    Emitter<WeatherState> emit,
  ) async {
    emit(const WeatherLoading());

    try {
      final result = request.languageCode == 'ar'
          ? await repository.getCurrentWeather(request.city, languageCode: 'ar')
          : await repository.getCurrentWeather(request.city);

      emit(
        WeatherSuccess(
          weather: result.weather,
          isFromCache: result.isFromCache,
          cachedAt: result.cachedAt,
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
    } on DataParsingException {
      emit(const WeatherFailure(type: WeatherFailureType.unknown));
    } on AppException {
      emit(const WeatherFailure(type: WeatherFailureType.unknown));
    } catch (_) {
      emit(const WeatherFailure(type: WeatherFailureType.unknown));
    }
  }
}
