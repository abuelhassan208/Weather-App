import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/splash/presentation/widgets/splash_content.dart';
import 'package:weather_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpContent(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size surfaceSize = const Size(375, 812),
    double textScaleFactor = 1,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: child!,
          );
        },
        home: const SplashContent(),
      ),
    );
  }

  testWidgets('shows the icon and localized English content', (tester) async {
    await pumpContent(tester);

    expect(find.byKey(const Key('splashIcon')), findsOneWidget);
    expect(find.text('Weather App'), findsOneWidget);
    expect(find.text('Weather at a glance'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('splashTitle')))),
      TextDirection.ltr,
    );
  });

  testWidgets('shows localized Arabic content in RTL', (tester) async {
    await pumpContent(tester, locale: const Locale('ar'));

    expect(find.text('تطبيق الطقس'), findsOneWidget);
    expect(find.text('الطقس في لمحة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('splashTitle')))),
      TextDirection.rtl,
    );
  });

  for (final size in [
    const Size(240, 320),
    const Size(430, 932),
    const Size(800, 1200),
    const Size(1400, 900),
  ]) {
    testWidgets('does not overflow at $size', (tester) async {
      await pumpContent(tester, surfaceSize: size);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('splashPage')), findsOneWidget);
    });
  }

  testWidgets('does not overflow with large text scale', (tester) async {
    await pumpContent(
      tester,
      surfaceSize: const Size(240, 320),
      textScaleFactor: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Weather at a glance'), findsOneWidget);
  });

  testWidgets('announces splash content once through semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpContent(tester);

    expect(
      tester.getSemantics(
        find.bySemanticsLabel('Weather App. Weather at a glance'),
      ),
      matchesSemantics(
        label: 'Weather App. Weather at a glance',
        textDirection: TextDirection.ltr,
      ),
    );

    semantics.dispose();
  });
}
