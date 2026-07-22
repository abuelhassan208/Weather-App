import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WeatherApp());

    // Verify that WeatherApp is built.
    expect(find.byType(WeatherApp), findsOneWidget);
  });
}
