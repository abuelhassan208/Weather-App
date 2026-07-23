import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/presentation/models/cached_weather_notice_data.dart';
import 'package:weather_app/features/weather/presentation/models/weather_error_data.dart';
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
      testWidgets('displays supplied English error data unchanged', (
        tester,
      ) async {
        const data = WeatherErrorData(
          message: 'DISPLAY::error message',
          retryLabel: 'DISPLAY::retry',
        );

        await pumpLocalizedWidget(
          tester,
          child: WeatherErrorView(data: data, onRetry: () {}),
        );

        expect(find.byKey(const Key('weatherErrorView')), findsOneWidget);
        expect(find.byKey(const Key('weatherErrorIcon')), findsOneWidget);
        expect(find.byKey(const Key('weatherErrorMessage')), findsOneWidget);
        expect(find.byKey(const Key('weatherRetryButton')), findsOneWidget);
        expect(find.text(data.message), findsOneWidget);
        expect(find.text(data.retryLabel), findsOneWidget);
      });

      testWidgets('displays supplied Arabic error data unchanged', (
        tester,
      ) async {
        const data = WeatherErrorData(
          message: 'حدث خطأ تجريبي',
          retryLabel: 'إعادة العرض',
        );

        await pumpLocalizedWidget(
          tester,
          child: WeatherErrorView(data: data, onRetry: () {}),
          locale: const Locale('ar'),
        );

        expect(find.text(data.message), findsOneWidget);
        expect(find.text(data.retryLabel), findsOneWidget);
      });

      testWidgets('invokes onRetry callback when retry button is tapped', (
        tester,
      ) async {
        var retryCount = 0;

        await pumpLocalizedWidget(
          tester,
          child: WeatherErrorView(
            data: const WeatherErrorData(
              message: 'Network error',
              retryLabel: 'Try again',
            ),
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
        await pumpLocalizedWidget(
          tester,
          child: const CachedWeatherNotice(
            data: CachedWeatherNoticeData(
              message:
                  'Showing saved weather for Cairo. Saved 5 minutes ago. It may not be current.',
            ),
          ),
        );

        expect(find.byKey(const Key('cachedWeatherNotice')), findsOneWidget);
        expect(find.byKey(const Key('cachedWeatherIcon')), findsOneWidget);
        expect(find.byKey(const Key('cachedWeatherMessage')), findsOneWidget);
        expect(find.textContaining('Saved 5 minutes ago'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            'Showing saved weather for Cairo. Saved 5 minutes ago. It may not be current.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('displays cached notice elements with Arabic text', (
        tester,
      ) async {
        await pumpLocalizedWidget(
          tester,
          child: const CachedWeatherNotice(
            data: CachedWeatherNoticeData(
              message:
                  'يتم عرض طقس محفوظ لمدينة القاهرة. تم الحفظ منذ 5 دقائق. قد لا تكون البيانات لحظية.',
            ),
          ),
          locale: const Locale('ar'),
        );

        expect(find.textContaining('تم الحفظ منذ 5 دقائق'), findsOneWidget);
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
                data: const WeatherErrorData(
                  message: 'Network error',
                  retryLabel: 'Try again',
                ),
                onRetry: () {},
              ),
              const CachedWeatherNotice(
                data: CachedWeatherNoticeData(message: 'Cached weather'),
              ),
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
                data: const WeatherErrorData(
                  message: 'Server error',
                  retryLabel: 'Try again',
                ),
                onRetry: () {},
              ),
              const CachedWeatherNotice(
                data: CachedWeatherNoticeData(message: 'Cached weather'),
              ),
            ],
          ),
          surfaceSize: const Size(900, 900),
        );

        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('error is a localized live region', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpLocalizedWidget(
        tester,
        child: WeatherErrorView(
          data: const WeatherErrorData(
            message:
                'No internet connection. Please check your connection and try again.',
            retryLabel: 'Try again',
          ),
          onRetry: () {},
        ),
      );
      expect(
        find.bySemanticsLabel(
          'No internet connection. Please check your connection and try again.',
        ),
        findsOneWidget,
      );
      final retrySize = tester.getSize(
        find.byKey(const Key('weatherRetryButton')),
      );
      expect(retrySize.height, greaterThanOrEqualTo(48));
      handle.dispose();
    });
  });
}
