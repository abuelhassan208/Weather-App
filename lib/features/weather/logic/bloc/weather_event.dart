import 'package:equatable/equatable.dart';

sealed class WeatherEvent extends Equatable {
  const WeatherEvent();

  @override
  List<Object?> get props => [];
}

final class WeatherRequested extends WeatherEvent {
  const WeatherRequested(this.city);

  final String city;

  @override
  List<Object?> get props => [city];
}
