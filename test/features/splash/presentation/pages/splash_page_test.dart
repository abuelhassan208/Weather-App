import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/splash/logic/bloc/splash_bloc.dart';
import 'package:weather_app/features/splash/presentation/pages/splash_page.dart';
import 'package:weather_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpSplash(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Widget destination = const _Destination(),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashPage(destination: destination),
      ),
    );
  }

  testWidgets('shows splash first and stays until the duration completes', (
    tester,
  ) async {
    await pumpSplash(tester);

    expect(find.byKey(const Key('splashPage')), findsOneWidget);
    expect(find.byKey(const Key('destination')), findsNothing);

    await tester.pump(
      SplashBloc.splashDuration - const Duration(milliseconds: 1),
    );

    expect(find.byKey(const Key('splashPage')), findsOneWidget);
    expect(find.byKey(const Key('destination')), findsNothing);
  });

  testWidgets('replaces splash after the duration and cannot navigate back', (
    tester,
  ) async {
    await pumpSplash(tester);

    await tester.pump(SplashBloc.splashDuration);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('splashPage')), findsNothing);
    expect(find.byKey(const Key('destination')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('splashPage')), findsNothing);
    expect(find.byKey(const Key('destination')), findsOneWidget);
  });

  testWidgets('opens the destination only once', (tester) async {
    var buildCount = 0;
    await pumpSplash(
      tester,
      destination: Builder(
        builder: (context) {
          buildCount++;
          return const _Destination();
        },
      ),
    );

    await tester.pump(SplashBloc.splashDuration);
    await tester.pumpAndSettle();
    await tester.pump(SplashBloc.splashDuration);

    expect(buildCount, 1);
    expect(find.byKey(const Key('destination')), findsOneWidget);
  });

  testWidgets('closes the bloc safely when removed', (tester) async {
    await pumpSplash(tester);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(SplashBloc.splashDuration);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('destination')), findsNothing);
  });

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('transitions successfully for ${locale.languageCode}', (
      tester,
    ) async {
      await pumpSplash(tester, locale: locale);

      await tester.pump(SplashBloc.splashDuration);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('destination')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Destination extends StatelessWidget {
  const _Destination();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Destination', key: Key('destination')));
  }
}
