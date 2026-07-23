import 'package:equatable/equatable.dart';

import '../../data/models/weather_model.dart';

enum WeatherFailureType {
  invalidCity,
  noInternet,
  timeout,
  unauthorized,
  server,
  cache,
  configuration,
  unknown,
}

sealed class WeatherState extends Equatable {
  const WeatherState();

  @override
  List<Object?> get props => [];
}

final class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

final class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

final class WeatherSuccess extends WeatherState {
  const WeatherSuccess({
    required this.weather,
    required this.isFromCache,
    this.cachedAt,
  }) : assert(!isFromCache || cachedAt != null);

  final WeatherModel weather;
  final bool isFromCache;
  final DateTime? cachedAt;

  @override
  List<Object?> get props => [weather, isFromCache, cachedAt];
}

final class WeatherFailure extends WeatherState {
  const WeatherFailure({required this.type});

  final WeatherFailureType type;

  @override
  List<Object?> get props => [type];
}
