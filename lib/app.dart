import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/locale_cubit.dart';
import 'features/weather/data/repositories/weather_repository.dart';
import 'features/weather/logic/bloc/weather_bloc.dart';
import 'features/weather/presentation/pages/weather_page.dart';
import 'l10n/generated/app_localizations.dart';

class WeatherApp extends StatelessWidget {
  const WeatherApp({
    required this.weatherRepository,
    required this.preferences,
    super.key,
  });

  final WeatherRepository weatherRepository;
  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WeatherBloc>(
          create: (_) => WeatherBloc(repository: weatherRepository),
        ),
        BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit(preferences: preferences),
        ),
      ],
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp(
                locale: locale,
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (context) {
                  return AppLocalizations.of(context).appTitle;
                },
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: ThemeData(useMaterial3: true),
                home: child,
              );
            },
            child: const WeatherPage(),
          );
        },
      ),
    );
  }
}
