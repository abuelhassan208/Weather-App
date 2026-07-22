import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/features/weather/data/repositories/weather_repository.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    final repository = MockWeatherRepository();

    await tester.pumpWidget(WeatherApp(weatherRepository: repository));

    expect(find.byType(WeatherApp), findsOneWidget);
  });
}
