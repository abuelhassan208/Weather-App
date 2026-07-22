import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_state.dart';
import 'package:weather_app/features/weather/presentation/widgets/cached_weather_notice.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_error_view.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_initial_view.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_loading_view.dart';
import 'package:weather_app/l10n/generated/app_localizations.dart';

void main() {
  group('Weather State Views', () {
    Future<void> pumpLocalizedWidget(
      WidgetTester tester, {
      required Widget child,
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
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Center(child: SingleChildScrollView(child: child)),
              ),
            );
          },
        ),
      );

      await tester.pump();
    }

    group('WeatherInitialView', () {
      testWidgets('displays initial view elements with English text', (
        tester,
      ) async {
        await pumpLocalizedWidget(tester, child: const WeatherInitialView());

        expect(find.byKey(const Key('weatherInitialView')), findsOneWidget);
        expect(find.byKey(const Key('weatherInitialIcon')), findsOneWidget);
        expect(find.byKey(const Key('weatherInitialMessage')), findsOneWidget);
        expect(
          find.text('Search for a city to view its current weather.'),
          findsOneWidget,
        );
      });

      testWidgets('displays initial view elements with Arabic text', (
        tester,
      ) async {
        await pumpLocalizedWidget(
          tester,
          child: const WeatherInitialView(),
          locale: const Locale('ar'),
        );

        expect(
          find.text('ابحث عن مدينة لعرض حالة الطقس الحالية.'),
          findsOneWidget,
        );
      });
    });

    group('WeatherLoadingView', () {
      testWidgets('displays loading view elements with English text', (
        tester,
      ) async {
        await pumpLocalizedWidget(tester, child: const WeatherLoadingView());

        expect(find.byKey(const Key('weatherLoadingView')), findsOneWidget);
        expect(
          find.byKey(const Key('weatherLoadingIndicator')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('weatherLoadingMessage')), findsOneWidget);
        expect(find.text('Fetching weather data...'), findsOneWidget);
      });

      testWidgets('displays loading view elements with Arabic text', (
        tester,
      ) async {
        await pumpLocalizedWidget(
          tester,
          child: const WeatherLoadingView(),
          locale: const Locale('ar'),
        );

        expect(find.text('جارٍ تحميل بيانات الطقس...'), findsOneWidget);
      });
    });

    group('WeatherErrorView', () {
      testWidgets('displays correct English message for all failure types', (
        tester,
      ) async {
        final expectedMessages = {
          WeatherFailureType.invalidCity:
              'City not found. Please check the city name.',
          WeatherFailureType.noInternet:
              'No internet connection. Please check your connection and try again.',
          WeatherFailureType.timeout:
              'The request took too long. Please try again.',
          WeatherFailureType.unauthorized:
              'Unable to access the weather service.',
          WeatherFailureType.server:
              'The weather service is currently unavailable. Please try again later.',
          WeatherFailureType.cache:
              'The saved weather data could not be loaded.',
          WeatherFailureType.configuration:
              'The application is not configured correctly.',
          WeatherFailureType.unknown: 'Something went wrong. Please try again.',
        };

        for (final entry in expectedMessages.entries) {
          await pumpLocalizedWidget(
            tester,
            child: WeatherErrorView(failureType: entry.key, onRetry: () {}),
          );

          expect(find.byKey(const Key('weatherErrorView')), findsOneWidget);
          expect(find.byKey(const Key('weatherErrorIcon')), findsOneWidget);
          expect(find.byKey(const Key('weatherErrorMessage')), findsOneWidget);
          expect(find.byKey(const Key('weatherRetryButton')), findsOneWidget);
          expect(find.text(entry.value), findsOneWidget);
        }
      });

      testWidgets('displays correct Arabic messages for failure types', (
        tester,
      ) async {
        final expectedMessages = {
          WeatherFailureType.invalidCity:
              'لم يتم العثور على المدينة. تحقق من اسم المدينة.',
          WeatherFailureType.noInternet:
              'لا يوجد اتصال بالإنترنت. تحقق من الاتصال ثم حاول مرة أخرى.',
          WeatherFailureType.server:
              'خدمة الطقس غير متاحة حاليًا. حاول مرة أخرى لاحقًا.',
          WeatherFailureType.unknown: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
        };

        for (final entry in expectedMessages.entries) {
          await pumpLocalizedWidget(
            tester,
            child: WeatherErrorView(failureType: entry.key, onRetry: () {}),
            locale: const Locale('ar'),
          );

          expect(find.text(entry.value), findsOneWidget);
        }
      });

      testWidgets('invokes onRetry callback when retry button is tapped', (
        tester,
      ) async {
        var retryCount = 0;

        await pumpLocalizedWidget(
          tester,
          child: WeatherErrorView(
            failureType: WeatherFailureType.noInternet,
            onRetry: () {
              retryCount++;
            },
          ),
        );

        await tester.tap(find.byKey(const Key('weatherRetryButton')));
        await tester.pump();

        expect(retryCount, equals(1));
      });
    });

    group('CachedWeatherNotice', () {
      testWidgets('displays cached notice elements with English text', (
        tester,
      ) async {
        await pumpLocalizedWidget(tester, child: const CachedWeatherNotice());

        expect(find.byKey(const Key('cachedWeatherNotice')), findsOneWidget);
        expect(find.byKey(const Key('cachedWeatherIcon')), findsOneWidget);
        expect(find.byKey(const Key('cachedWeatherMessage')), findsOneWidget);
        expect(
          find.text('Showing the last saved weather data.'),
          findsOneWidget,
        );
      });

      testWidgets('displays cached notice elements with Arabic text', (
        tester,
      ) async {
        await pumpLocalizedWidget(
          tester,
          child: const CachedWeatherNotice(),
          locale: const Locale('ar'),
        );

        expect(find.text('يتم عرض آخر بيانات طقس محفوظة.'), findsOneWidget);
      });
    });

    group('Responsive surface sizes', () {
      testWidgets('renders all state views without overflow on small screen', (
        tester,
      ) async {
        await pumpLocalizedWidget(
          tester,
          child: Column(
            children: [
              const WeatherInitialView(),
              const WeatherLoadingView(),
              WeatherErrorView(
                failureType: WeatherFailureType.noInternet,
                onRetry: () {},
              ),
              const CachedWeatherNotice(),
            ],
          ),
          surfaceSize: const Size(320, 640),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders all state views without overflow on wide screen', (
        tester,
      ) async {
        await pumpLocalizedWidget(
          tester,
          child: Column(
            children: [
              const WeatherInitialView(),
              const WeatherLoadingView(),
              WeatherErrorView(
                failureType: WeatherFailureType.server,
                onRetry: () {},
              ),
              const CachedWeatherNotice(),
            ],
          ),
          surfaceSize: const Size(900, 900),
        );

        expect(tester.takeException(), isNull);
      });
    });
  });
}
