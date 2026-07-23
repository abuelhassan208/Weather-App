import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/localization/language_switcher.dart';
import 'package:weather_app/core/localization/locale_cubit.dart';
import 'package:weather_app/l10n/generated/app_localizations.dart';

void main() {
  group('LanguageSwitcher', () {
    late SharedPreferences preferences;
    late LocaleCubit localeCubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      localeCubit = LocaleCubit(preferences: preferences);
    });

    tearDown(() async {
      await localeCubit.close();
    });

    Future<void> pumpLanguageSwitcher(WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: localeCubit,
          child: BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              return MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(body: Center(child: LanguageSwitcher())),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('renders language switcher icon button', (tester) async {
      await pumpLanguageSwitcher(tester);

      expect(find.byKey(const Key('languageSwitcher')), findsOneWidget);
      final size = tester.getSize(find.byKey(const Key('languageSwitcher')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('displays English and Arabic options when tapped', (
      tester,
    ) async {
      await pumpLanguageSwitcher(tester);

      await tester.tap(find.byKey(const Key('languageSwitcher')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('englishLanguageOption')), findsOneWidget);
      expect(find.byKey(const Key('arabicLanguageOption')), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Arabic'), findsOneWidget);
    });

    testWidgets(
      'selecting Arabic option updates LocaleCubit state and preferences',
      (tester) async {
        await pumpLanguageSwitcher(tester);

        await tester.tap(find.byKey(const Key('languageSwitcher')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('arabicLanguageOption')));
        await tester.pumpAndSettle();

        expect(localeCubit.state, equals(const Locale('ar')));
        expect(
          preferences.getString(LocaleCubit.localePreferenceKey),
          equals('ar'),
        );
      },
    );

    testWidgets('displays localized option labels in Arabic when active', (
      tester,
    ) async {
      await localeCubit.setLocale(const Locale('ar'));
      await pumpLanguageSwitcher(tester);

      await tester.tap(find.byKey(const Key('languageSwitcher')));
      await tester.pumpAndSettle();

      expect(find.text('الإسبانية'), findsNothing);
      expect(find.text('الإنجليزية'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
    });

    testWidgets('selecting English option from Arabic UI updates to English', (
      tester,
    ) async {
      await localeCubit.setLocale(const Locale('ar'));
      await pumpLanguageSwitcher(tester);

      await tester.tap(find.byKey(const Key('languageSwitcher')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('englishLanguageOption')));
      await tester.pumpAndSettle();

      expect(localeCubit.state, equals(const Locale('en')));
    });

    testWidgets(
      'updates Directionality to RTL for Arabic and LTR for English',
      (tester) async {
        await pumpLanguageSwitcher(tester);

        expect(
          Directionality.of(
            tester.element(find.byKey(const Key('languageSwitcher'))),
          ),
          equals(TextDirection.ltr),
        );

        await tester.tap(find.byKey(const Key('languageSwitcher')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('arabicLanguageOption')));
        await tester.pumpAndSettle();

        expect(
          Directionality.of(
            tester.element(find.byKey(const Key('languageSwitcher'))),
          ),
          equals(TextDirection.rtl),
        );
      },
    );
  });
}
