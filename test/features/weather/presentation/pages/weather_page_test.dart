import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/localization/locale_cubit.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_bloc.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_event.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_state.dart';
import 'package:weather_app/features/weather/presentation/pages/weather_page.dart';
import 'package:weather_app/l10n/generated/app_localizations.dart';

class MockWeatherBloc extends Mock implements WeatherBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const WeatherRequested(''));
  });

  group('WeatherPage', () {
    late MockWeatherBloc bloc;
    late StreamController<WeatherState> stateController;
    late SharedPreferences preferences;
    late LocaleCubit localeCubit;

    const testWeather = WeatherModel(
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

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      localeCubit = LocaleCubit(preferences: preferences);

      bloc = MockWeatherBloc();
      stateController = StreamController<WeatherState>.broadcast();

      when(() => bloc.state).thenReturn(const WeatherInitial());
      when(() => bloc.stream).thenAnswer((_) => stateController.stream);
    });

    tearDown(() async {
      await stateController.close();
      await localeCubit.close();
    });

    Future<void> pumpWeatherPage(
      WidgetTester tester, {
      required WeatherBloc bloc,
      Locale locale = const Locale('en'),
      Size surfaceSize = const Size(375, 812),
    }) async {
      if (locale.languageCode != localeCubit.state?.languageCode) {
        await localeCubit.setLocale(locale);
      }

      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<WeatherBloc>.value(value: bloc),
            BlocProvider<LocaleCubit>.value(value: localeCubit),
          ],
          child: BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, currentLocale) {
              return ScreenUtilInit(
                designSize: const Size(375, 812),
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, _) {
                  return MaterialApp(
                    locale: currentLocale,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: const WeatherPage(),
                  );
                },
              );
            },
          ),
        ),
      );

      await tester.pump();
    }

    testWidgets(
      'renders initial state with title, search form, and initial view',
      (tester) async {
        await pumpWeatherPage(tester, bloc: bloc);

        expect(find.byKey(const Key('weatherPageTitle')), findsOneWidget);
        expect(find.byKey(const Key('citySearchTextField')), findsOneWidget);
        expect(find.byKey(const Key('citySearchButton')), findsOneWidget);
        expect(find.byKey(const Key('weatherInitialView')), findsOneWidget);
        expect(find.byKey(const Key('weatherInitialMessage')), findsOneWidget);

        expect(find.byKey(const Key('weatherCard')), findsNothing);
        expect(find.byKey(const Key('weatherLoadingView')), findsNothing);
        expect(find.byKey(const Key('weatherErrorView')), findsNothing);
        expect(find.byKey(const Key('cachedWeatherNotice')), findsNothing);
      },
    );

    testWidgets(
      'renders loading view and disables search inputs on WeatherLoading',
      (tester) async {
        when(() => bloc.state).thenReturn(const WeatherLoading());

        await pumpWeatherPage(tester, bloc: bloc);

        expect(find.byKey(const Key('weatherLoadingView')), findsOneWidget);
        expect(
          find.byKey(const Key('weatherLoadingIndicator')),
          findsOneWidget,
        );

        final textField = tester.widget<TextField>(
          find.byKey(const Key('citySearchTextField')),
        );
        final button = tester.widget<FilledButton>(
          find.byKey(const Key('citySearchButton')),
        );

        expect(textField.enabled, isFalse);
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'renders weather card without notice on WeatherSuccess (isFromCache: false)',
      (tester) async {
        when(() => bloc.state).thenReturn(
          const WeatherSuccess(weather: testWeather, isFromCache: false),
        );

        await pumpWeatherPage(tester, bloc: bloc);

        expect(find.byKey(const Key('weatherSuccessContent')), findsOneWidget);
        expect(find.byKey(const Key('weatherCard')), findsOneWidget);
        expect(find.text('Cairo, Egypt'), findsOneWidget);
        expect(find.byKey(const Key('cachedWeatherNotice')), findsNothing);
      },
    );

    testWidgets(
      'renders cached notice and weather card on WeatherSuccess (isFromCache: true)',
      (tester) async {
        when(() => bloc.state).thenReturn(
          const WeatherSuccess(weather: testWeather, isFromCache: true),
        );

        await pumpWeatherPage(tester, bloc: bloc);

        expect(find.byKey(const Key('cachedWeatherNotice')), findsOneWidget);
        expect(find.byKey(const Key('cachedWeatherMessage')), findsOneWidget);
        expect(find.byKey(const Key('weatherCard')), findsOneWidget);
      },
    );

    testWidgets('renders error view on WeatherFailure', (tester) async {
      when(
        () => bloc.state,
      ).thenReturn(const WeatherFailure(type: WeatherFailureType.noInternet));

      await pumpWeatherPage(tester, bloc: bloc);

      expect(find.byKey(const Key('weatherErrorView')), findsOneWidget);
      expect(find.byKey(const Key('weatherErrorMessage')), findsOneWidget);
      expect(find.byKey(const Key('weatherRetryButton')), findsOneWidget);
      expect(
        find.text(
          'No internet connection. Please check your connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('submitting search form dispatches WeatherRequested event', (
      tester,
    ) async {
      await pumpWeatherPage(tester, bloc: bloc);

      await tester.enterText(
        find.byKey(const Key('citySearchTextField')),
        'Cairo',
      );
      await tester.tap(find.byKey(const Key('citySearchButton')));

      verify(() => bloc.add(const WeatherRequested('Cairo'))).called(1);
    });

    testWidgets(
      'retrying error view re-dispatches WeatherRequested with last trimmed city',
      (tester) async {
        await pumpWeatherPage(tester, bloc: bloc);

        // Search for city with whitespace.
        await tester.enterText(
          find.byKey(const Key('citySearchTextField')),
          '  Cairo  ',
        );
        await tester.tap(find.byKey(const Key('citySearchButton')));

        // State moves to WeatherFailure.
        when(
          () => bloc.state,
        ).thenReturn(const WeatherFailure(type: WeatherFailureType.timeout));
        stateController.add(
          const WeatherFailure(type: WeatherFailureType.timeout),
        );
        await tester.pump();

        // Tap retry button.
        await tester.tap(find.byKey(const Key('weatherRetryButton')));

        // Verify WeatherRequested('Cairo') was dispatched twice total (search + retry).
        verify(() => bloc.add(const WeatherRequested('Cairo'))).called(2);
      },
    );

    testWidgets(
      'tapping retry without prior search does not crash or dispatch event',
      (tester) async {
        when(
          () => bloc.state,
        ).thenReturn(const WeatherFailure(type: WeatherFailureType.noInternet));

        await pumpWeatherPage(tester, bloc: bloc);

        await tester.tap(find.byKey(const Key('weatherRetryButton')));
        await tester.pump();

        verifyNever(() => bloc.add(any()));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('displays Arabic localized texts when locale is Arabic', (
      tester,
    ) async {
      await pumpWeatherPage(tester, bloc: bloc, locale: const Locale('ar'));

      expect(find.text('تطبيق الطقس'), findsOneWidget);
      expect(find.text('المدينة'), findsOneWidget);
      expect(find.text('بحث'), findsOneWidget);
      expect(
        find.text('ابحث عن مدينة لعرض حالة الطقس الحالية.'),
        findsOneWidget,
      );
    });

    testWidgets('renders without overflow on small surface size', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        const WeatherSuccess(weather: testWeather, isFromCache: true),
      );

      await pumpWeatherPage(
        tester,
        bloc: bloc,
        surfaceSize: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on wide surface size', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        const WeatherSuccess(weather: testWeather, isFromCache: false),
      );

      await pumpWeatherPage(
        tester,
        bloc: bloc,
        surfaceSize: const Size(900, 900),
      );

      expect(find.byKey(const Key('weatherCard')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays LanguageSwitcher on top of WeatherPage', (
      tester,
    ) async {
      await pumpWeatherPage(tester, bloc: bloc);

      expect(find.byKey(const Key('languageSwitcher')), findsOneWidget);
    });

    testWidgets('changing language does not dispatch WeatherRequested event', (
      tester,
    ) async {
      await pumpWeatherPage(tester, bloc: bloc);

      await tester.tap(find.byKey(const Key('languageSwitcher')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('arabicLanguageOption')));
      await tester.pumpAndSettle();

      verifyNever(() => bloc.add(any()));
    });

    testWidgets('changing language preserves WeatherSuccess state and card', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        const WeatherSuccess(weather: testWeather, isFromCache: false),
      );

      await pumpWeatherPage(tester, bloc: bloc);

      expect(find.byKey(const Key('weatherCard')), findsOneWidget);

      await tester.tap(find.byKey(const Key('languageSwitcher')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('arabicLanguageOption')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weatherCard')), findsOneWidget);
      expect(find.byKey(const Key('weatherInitialView')), findsNothing);
    });

    testWidgets('changing language to Arabic updates Directionality to RTL', (
      tester,
    ) async {
      await pumpWeatherPage(tester, bloc: bloc);

      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('weatherPageTitle'))),
        ),
        equals(TextDirection.ltr),
      );

      await tester.tap(find.byKey(const Key('languageSwitcher')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('arabicLanguageOption')));
      await tester.pumpAndSettle();

      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('weatherPageTitle'))),
        ),
        equals(TextDirection.rtl),
      );
    });
  });
}
