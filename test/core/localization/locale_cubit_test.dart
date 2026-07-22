import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/localization/locale_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleCubit', () {
    test('initial state is null when no locale is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: preferences);

      expect(cubit.state, isNull);

      await cubit.close();
    });

    test('initial state is Locale("en") when "en" is saved', () async {
      SharedPreferences.setMockInitialValues({
        LocaleCubit.localePreferenceKey: 'en',
      });
      final preferences = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: preferences);

      expect(cubit.state, equals(const Locale('en')));

      await cubit.close();
    });

    test('initial state is Locale("ar") when "ar" is saved', () async {
      SharedPreferences.setMockInitialValues({
        LocaleCubit.localePreferenceKey: 'ar',
      });
      final preferences = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: preferences);

      expect(cubit.state, equals(const Locale('ar')));

      await cubit.close();
    });

    test(
      'initial state is null when saved language code is unsupported',
      () async {
        SharedPreferences.setMockInitialValues({
          LocaleCubit.localePreferenceKey: 'fr',
        });
        final preferences = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: preferences);

        expect(cubit.state, isNull);

        await cubit.close();
      },
    );

    test(
      'setLocale("ar") saves to preferences and emits Locale("ar")',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: preferences);

        await cubit.setLocale(const Locale('ar'));

        expect(cubit.state, equals(const Locale('ar')));
        expect(
          preferences.getString(LocaleCubit.localePreferenceKey),
          equals('ar'),
        );

        await cubit.close();
      },
    );

    test(
      'setLocale("en") saves to preferences and emits Locale("en")',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final cubit = LocaleCubit(preferences: preferences);

        await cubit.setLocale(const Locale('en'));

        expect(cubit.state, equals(const Locale('en')));
        expect(
          preferences.getString(LocaleCubit.localePreferenceKey),
          equals('en'),
        );

        await cubit.close();
      },
    );

    test('setLocale with current locale does not emit new state', () async {
      SharedPreferences.setMockInitialValues({
        LocaleCubit.localePreferenceKey: 'ar',
      });
      final preferences = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: preferences);

      var emitCount = 0;
      final subscription = cubit.stream.listen((_) => emitCount++);

      await cubit.setLocale(const Locale('ar'));

      expect(emitCount, equals(0));

      await subscription.cancel();
      await cubit.close();
    });

    test('setLocale with unsupported locale throws ArgumentError', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: preferences);

      expect(
        () => cubit.setLocale(const Locale('fr')),
        throwsA(isA<ArgumentError>()),
      );
      expect(preferences.getString(LocaleCubit.localePreferenceKey), isNull);

      await cubit.close();
    });
  });
}
