import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/core/localization/locale_cubit.dart';
import 'package:weather_app/features/weather/data/repositories/weather_repository.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = MockWeatherRepository();

    await tester.pumpWidget(
      WeatherApp(weatherRepository: repository, preferences: preferences),
    );

    expect(find.byType(WeatherApp), findsOneWidget);
  });

  testWidgets('WeatherApp restores saved Arabic locale on launch', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LocaleCubit.localePreferenceKey: 'ar',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = MockWeatherRepository();

    await tester.pumpWidget(
      WeatherApp(weatherRepository: repository, preferences: preferences),
    );

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('تطبيق الطقس'), findsOneWidget);
    expect(find.text('المدينة'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('weatherPageTitle'))),
      ),
      equals(TextDirection.rtl),
    );
  });
}
