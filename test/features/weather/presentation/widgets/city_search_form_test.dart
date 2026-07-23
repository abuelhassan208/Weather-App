import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_bloc.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_event.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_state.dart';
import 'package:weather_app/features/weather/presentation/widgets/city_search_form.dart';
import 'package:weather_app/l10n/generated/app_localizations.dart';

class MockWeatherBloc extends Mock implements WeatherBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const WeatherRequested(''));
  });

  group('CitySearchForm', () {
    late MockWeatherBloc bloc;

    setUp(() {
      bloc = MockWeatherBloc();
      when(() => bloc.state).thenReturn(const WeatherInitial());
      when(
        () => bloc.stream,
      ).thenAnswer((_) => const Stream<WeatherState>.empty());
    });

    Widget buildTestWidget({
      required WeatherBloc bloc,
      Locale locale = const Locale('en'),
    }) {
      return BlocProvider<WeatherBloc>.value(
        value: bloc,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const CitySearchForm()),
          ),
        ),
      );
    }

    testWidgets('displays text field and search button with localized text', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('citySearchTextField')), findsOneWidget);
      expect(find.byKey(const Key('citySearchButton')), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets(
      'dispatches WeatherRequested on search button tap with city name',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(bloc: bloc));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('citySearchTextField')),
          'Cairo',
        );
        await tester.tap(find.byKey(const Key('citySearchButton')));

        verify(() => bloc.add(const WeatherRequested('Cairo'))).called(1);
      },
    );

    testWidgets('trims whitespace from city name before dispatching event', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('citySearchTextField')),
        '  Cairo  ',
      );
      await tester.tap(find.byKey(const Key('citySearchButton')));

      verify(() => bloc.add(const WeatherRequested('Cairo'))).called(1);
    });

    testWidgets(
      'does not dispatch event when text field is empty or whitespace',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(bloc: bloc));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('citySearchTextField')),
          '   ',
        );
        await tester.tap(find.byKey(const Key('citySearchButton')));
        await tester.pump();

        verifyNever(() => bloc.add(any()));
        expect(find.text('Enter a city name.'), findsOneWidget);
      },
    );

    testWidgets('clears validation after entering a valid city', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(bloc: bloc));
      await tester.tap(find.byKey(const Key('citySearchButton')));
      await tester.pump();
      expect(find.text('Enter a city name.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('citySearchTextField')),
        'Cairo',
      );
      await tester.pump();

      expect(find.text('Enter a city name.'), findsNothing);
    });

    testWidgets('shows Arabic validation and dispatches Arabic request', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(bloc: bloc, locale: const Locale('ar')),
      );
      await tester.tap(find.byKey(const Key('citySearchButton')));
      await tester.pump();
      expect(find.text('أدخل اسم المدينة.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('citySearchTextField')),
        'القاهرة',
      );
      await tester.tap(find.byKey(const Key('citySearchButton')));

      verify(
        () => bloc.add(const WeatherRequested('القاهرة', languageCode: 'ar')),
      ).called(1);
    });

    testWidgets('search button has at least a 48px touch target', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(bloc: bloc));
      final size = tester.getSize(find.byKey(const Key('citySearchButton')));

      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets(
      'dispatches WeatherRequested on keyboard search action (Enter)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(bloc: bloc));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('citySearchTextField')),
          'Cairo',
        );
        await tester.testTextInput.receiveAction(TextInputAction.search);

        verify(() => bloc.add(const WeatherRequested('Cairo'))).called(1);
      },
    );

    testWidgets('disables text field and button when state is WeatherLoading', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(const WeatherLoading());

      await tester.pumpWidget(buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextFormField>(
        find.byKey(const Key('citySearchTextField')),
      );
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('citySearchButton')),
      );

      expect(textField.enabled, isFalse);
      expect(button.onPressed, isNull);
    });

    testWidgets('displays Arabic text when locale is Arabic', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(bloc: bloc, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      expect(find.text('المدينة'), findsOneWidget);
      expect(find.text('بحث'), findsOneWidget);
    });
  });
}
