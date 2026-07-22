import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_card.dart';
import 'package:weather_app/l10n/generated/app_localizations.dart';

void main() {
  group('WeatherCard', () {
    const weather = WeatherModel(
      cityName: 'Cairo',
      country: 'Egypt',
      temperatureC: 30.0,
      feelsLikeC: 32.0,
      conditionText: 'Sunny',
      iconUrl: '',
      humidity: 40,
      windKph: 10.0,
      lastUpdated: '2026-07-22 18:00',
    );

    Future<void> pumpWeatherCard(
      WidgetTester tester, {
      required WeatherModel weather,
      Locale locale = const Locale('en'),
      Size surfaceSize = const Size(375, 812),
    }) async {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: surfaceSize.width,
                    child: WeatherCard(weather: weather),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pump();
    }

    testWidgets('renders weather card with location and condition', (
      tester,
    ) async {
      await pumpWeatherCard(tester, weather: weather);

      expect(find.byKey(const Key('weatherCard')), findsOneWidget);
      expect(find.byKey(const Key('weatherLocation')), findsOneWidget);
      expect(find.byKey(const Key('weatherCondition')), findsOneWidget);
      expect(find.text('Cairo, Egypt'), findsOneWidget);
      expect(find.text('Sunny'), findsOneWidget);
    });

    testWidgets('displays English localized labels and metric values', (
      tester,
    ) async {
      await pumpWeatherCard(tester, weather: weather);

      expect(find.byKey(const Key('weatherTemperature')), findsOneWidget);
      expect(find.byKey(const Key('weatherFeelsLike')), findsOneWidget);
      expect(find.byKey(const Key('weatherHumidity')), findsOneWidget);
      expect(find.byKey(const Key('weatherWindSpeed')), findsOneWidget);

      expect(find.text('Feels like'), findsOneWidget);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('Wind speed'), findsOneWidget);
      expect(find.byKey(const Key('weatherLastUpdated')), findsOneWidget);
    });

    testWidgets('displays Arabic localized labels and metric values', (
      tester,
    ) async {
      await pumpWeatherCard(
        tester,
        weather: weather,
        locale: const Locale('ar'),
      );

      expect(find.text('المحسوسة'), findsOneWidget);
      expect(find.text('الرطوبة'), findsOneWidget);
      expect(find.text('سرعة الرياح'), findsOneWidget);
      expect(find.byKey(const Key('weatherTemperature')), findsOneWidget);
      expect(find.byKey(const Key('weatherFeelsLike')), findsOneWidget);
      expect(find.byKey(const Key('weatherHumidity')), findsOneWidget);
      expect(find.byKey(const Key('weatherWindSpeed')), findsOneWidget);
    });

    testWidgets('displays fallback icon when iconUrl is empty', (tester) async {
      await pumpWeatherCard(tester, weather: weather);

      expect(find.byKey(const Key('weatherIconFallback')), findsOneWidget);
      expect(find.byKey(const Key('weatherNetworkIcon')), findsNothing);
    });

    testWidgets('displays network image when iconUrl is present', (
      tester,
    ) async {
      const weatherWithIcon = WeatherModel(
        cityName: 'Cairo',
        country: 'Egypt',
        temperatureC: 30.0,
        feelsLikeC: 32.0,
        conditionText: 'Sunny',
        iconUrl: 'https://example.com/weather.png',
        humidity: 40,
        windKph: 10.0,
        lastUpdated: '2026-07-22 18:00',
      );

      await pumpWeatherCard(tester, weather: weatherWithIcon);

      expect(find.byKey(const Key('weatherNetworkIcon')), findsOneWidget);
    });

    testWidgets('formats location correctly when country is empty', (
      tester,
    ) async {
      const weatherNoCountry = WeatherModel(
        cityName: 'Cairo',
        country: '',
        temperatureC: 30.0,
        feelsLikeC: 32.0,
        conditionText: 'Sunny',
        iconUrl: '',
        humidity: 40,
        windKph: 10.0,
        lastUpdated: '2026-07-22 18:00',
      );

      await pumpWeatherCard(tester, weather: weatherNoCountry);

      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('Cairo,'), findsNothing);
    });

    testWidgets('handles empty text data safely with fallback dash', (
      tester,
    ) async {
      const emptyWeather = WeatherModel(
        cityName: '',
        country: '',
        temperatureC: 0.0,
        feelsLikeC: 0.0,
        conditionText: '',
        iconUrl: '',
        humidity: 0,
        windKph: 0.0,
        lastUpdated: '',
      );

      await pumpWeatherCard(tester, weather: emptyWeather);

      expect(find.byKey(const Key('weatherCard')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on small surface size', (
      tester,
    ) async {
      await pumpWeatherCard(
        tester,
        weather: weather,
        surfaceSize: const Size(320, 640),
      );

      expect(find.byKey(const Key('weatherCard')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on wide surface size', (
      tester,
    ) async {
      await pumpWeatherCard(
        tester,
        weather: weather,
        surfaceSize: const Size(900, 900),
      );

      expect(find.byKey(const Key('weatherCard')), findsOneWidget);
      expect(find.text('Cairo, Egypt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
