import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/localization/language_switcher.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../logic/bloc/weather_bloc.dart';
import '../../logic/bloc/weather_event.dart';
import '../../logic/bloc/weather_state.dart';
import '../widgets/cached_weather_notice.dart';
import '../widgets/city_search_form.dart';
import '../widgets/weather_card.dart';
import '../widgets/weather_error_view.dart';
import '../widgets/weather_initial_view.dart';
import '../widgets/weather_loading_view.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String? _lastSearchedCity;

  void _retryLastSearch() {
    final city = _lastSearchedCity;

    if (city == null || city.isEmpty) {
      return;
    }

    context.read<WeatherBloc>().add(WeatherRequested(city));
  }

  Widget _buildWeatherState(WeatherState state) {
    return switch (state) {
      WeatherInitial() => const WeatherInitialView(),
      WeatherLoading() => const WeatherLoadingView(),
      WeatherSuccess() => Column(
        key: const Key('weatherSuccessContent'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isFromCache) ...[
            const CachedWeatherNotice(),
            SizedBox(height: 16.h),
          ],
          WeatherCard(weather: state.weather),
        ],
      ),
      WeatherFailure() => WeatherErrorView(
        failureType: state.type,
        onRetry: _retryLastSearch,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.appTitle,
                          key: const Key('weatherPageTitle'),
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      const LanguageSwitcher(),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  CitySearchForm(
                    onSearchSubmitted: (city) {
                      _lastSearchedCity = city;
                    },
                  ),
                  SizedBox(height: 32.h),
                  BlocBuilder<WeatherBloc, WeatherState>(
                    builder: (context, state) {
                      return KeyedSubtree(
                        key: const Key('weatherStateContent'),
                        child: _buildWeatherState(state),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
