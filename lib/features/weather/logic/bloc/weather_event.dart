import 'package:equatable/equatable.dart';

sealed class WeatherEvent extends Equatable {
  const WeatherEvent();

  @override
  List<Object?> get props => [];
}

final class WeatherRequested extends WeatherEvent {
  const WeatherRequested(this.city, {this.languageCode = 'en'});

  final String city;
  final String languageCode;

  @override
  List<Object?> get props => [city, languageCode];
}

final class WeatherRetryRequested extends WeatherEvent {
  const WeatherRetryRequested();
}
