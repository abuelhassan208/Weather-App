import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/presentation/models/weather_card_data.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_card.dart';
import 'package:weather_app/l10n/generated/app_localizations.dart';

void main() {
  group('WeatherCard', () {
    const data = WeatherCardData(
      locationText: 'Cairo, Egypt',
      conditionText: 'Sunny',
      temperatureText: '30.0°C',
      feelsLikeLabel: 'Feels like',
      feelsLikeText: '32.0°C',
      humidityLabel: 'Humidity',
      humidityText: '40%',
      windSpeedLabel: 'Wind speed',
      windSpeedText: '10.0 km/h',
      lastUpdatedText: 'Last updated: Jul 22, 2026 8:00 PM',
      locationSemanticLabel: 'Location, Cairo, Egypt',
      conditionSemanticLabel: 'Sunny',
      temperatureSemanticLabel: 'Temperature, 30.0°C',
      feelsLikeSemanticLabel: 'Feels like, 32.0°C',
      humiditySemanticLabel: 'Humidity, 40 percent',
      windSemanticLabel: 'Wind speed, 10.0 km/h',
      lastUpdatedSemanticLabel: 'Last updated, Jul 22, 2026 8:00 PM',
    );

    Future<void> pumpWeatherCard(
      WidgetTester tester, {
      WeatherCardData cardData = data,
      Locale locale = const Locale('en'),
      Size surfaceSize = const Size(375, 812),
      double textScale = 1,
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
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: surfaceSize.width,
                      child: WeatherCard(data: cardData),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pump();
    }

    testWidgets('renders every supplied display value unchanged', (
      tester,
    ) async {
      const unusualData = WeatherCardData(
        locationText: 'LOCATION::ready',
        conditionText: 'CONDITION::ready',
        temperatureText: 'TEMP::ready',
        feelsLikeLabel: 'FEELS_LABEL::ready',
        feelsLikeText: 'FEELS_VALUE::ready',
        humidityLabel: 'HUMIDITY_LABEL::ready',
        humidityText: 'HUMIDITY_VALUE::ready',
        windSpeedLabel: 'WIND_LABEL::ready',
        windSpeedText: 'WIND_VALUE::ready',
        lastUpdatedText: 'UPDATED::ready',
        locationSemanticLabel: 'location semantic ready',
        conditionSemanticLabel: 'condition semantic ready',
        temperatureSemanticLabel: 'temperature semantic ready',
        feelsLikeSemanticLabel: 'feels semantic ready',
        humiditySemanticLabel: 'humidity semantic ready',
        windSemanticLabel: 'wind semantic ready',
        lastUpdatedSemanticLabel: 'updated semantic ready',
      );

      await pumpWeatherCard(tester, cardData: unusualData);

      for (final text in [
        unusualData.locationText,
        unusualData.conditionText,
        unusualData.temperatureText,
        unusualData.feelsLikeLabel,
        unusualData.feelsLikeText,
        unusualData.humidityLabel,
        unusualData.humidityText,
        unusualData.windSpeedLabel,
        unusualData.windSpeedText,
        unusualData.lastUpdatedText,
      ]) {
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('uses supplied accessible semantic labels', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWeatherCard(tester);

      expect(
        tester.getSemantics(find.byKey(const Key('weatherLocation'))).label,
        contains(data.locationSemanticLabel),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('weatherCondition'))).label,
        contains(data.conditionSemanticLabel),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('weatherTemperature'))).label,
        contains(data.temperatureSemanticLabel),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('weatherHumidity'))).label,
        contains(data.humiditySemanticLabel),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('weatherWindSpeed'))).label,
        contains(data.windSemanticLabel),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('weatherLastUpdated'))).label,
        contains(data.lastUpdatedSemanticLabel),
      );
      handle.dispose();
    });

    testWidgets('displays fallback icon when icon URL is absent', (
      tester,
    ) async {
      await pumpWeatherCard(tester);

      expect(find.byKey(const Key('weatherIconFallback')), findsOneWidget);
      expect(find.byKey(const Key('weatherNetworkIcon')), findsNothing);
    });

    testWidgets('displays network image when icon URL is supplied', (
      tester,
    ) async {
      await pumpWeatherCard(
        tester,
        cardData: const WeatherCardData(
          locationText: 'Cairo',
          conditionText: 'Sunny',
          temperatureText: '30°C',
          feelsLikeLabel: 'Feels like',
          feelsLikeText: '32°C',
          humidityLabel: 'Humidity',
          humidityText: '40%',
          windSpeedLabel: 'Wind speed',
          windSpeedText: '10 km/h',
          lastUpdatedText: 'Last updated: now',
          locationSemanticLabel: 'Location, Cairo',
          conditionSemanticLabel: 'Sunny',
          temperatureSemanticLabel: 'Temperature, 30°C',
          feelsLikeSemanticLabel: 'Feels like, 32°C',
          humiditySemanticLabel: 'Humidity, 40 percent',
          windSemanticLabel: 'Wind speed, 10 km/h',
          lastUpdatedSemanticLabel: 'Last updated, now',
          iconUrl: 'https://example.com/weather.png',
        ),
      );

      expect(find.byKey(const Key('weatherNetworkIcon')), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weatherIconFallback')), findsOneWidget);
    });

    for (final testCase in <({Size size, double scale, Locale locale})>[
      (size: Size(320, 640), scale: 2, locale: Locale('en')),
      (size: Size(640, 320), scale: 2, locale: Locale('en')),
      (size: Size(812, 375), scale: 1.5, locale: Locale('ar')),
      (size: Size(600, 900), scale: 2, locale: Locale('ar')),
      (size: Size(900, 600), scale: 1.5, locale: Locale('en')),
      (size: Size(900, 900), scale: 2, locale: Locale('en')),
    ]) {
      testWidgets(
        'renders supplied long content at ${testCase.size} scale ${testCase.scale}',
        (tester) async {
          final longData = WeatherCardData(
            locationText: 'San Fernando del Valle de Catamarca, Argentina',
            conditionText: testCase.locale.languageCode == 'ar'
                ? 'عواصف رعدية مصحوبة بأمطار غزيرة ورياح شديدة'
                : 'Thunderstorms with heavy rain and strong winds',
            temperatureText: data.temperatureText,
            feelsLikeLabel: data.feelsLikeLabel,
            feelsLikeText: data.feelsLikeText,
            humidityLabel: data.humidityLabel,
            humidityText: data.humidityText,
            windSpeedLabel: data.windSpeedLabel,
            windSpeedText: data.windSpeedText,
            lastUpdatedText: data.lastUpdatedText,
            locationSemanticLabel: data.locationSemanticLabel,
            conditionSemanticLabel: data.conditionSemanticLabel,
            temperatureSemanticLabel: data.temperatureSemanticLabel,
            feelsLikeSemanticLabel: data.feelsLikeSemanticLabel,
            humiditySemanticLabel: data.humiditySemanticLabel,
            windSemanticLabel: data.windSemanticLabel,
            lastUpdatedSemanticLabel: data.lastUpdatedSemanticLabel,
          );

          await pumpWeatherCard(
            tester,
            cardData: longData,
            locale: testCase.locale,
            surfaceSize: testCase.size,
            textScale: testCase.scale,
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('weatherCard')), findsOneWidget);
        },
      );
    }
  });
}
