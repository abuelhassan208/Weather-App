import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/localization/language_switcher.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../logic/bloc/weather_bloc.dart';
import '../../logic/bloc/weather_event.dart';
import '../../logic/bloc/weather_state.dart';
import '../formatters/cached_weather_notice_formatter.dart';
import '../formatters/weather_card_formatter.dart';
import '../formatters/weather_error_formatter.dart';
import '../widgets/cached_weather_notice.dart';
import '../widgets/city_search_form.dart';
import '../widgets/weather_card.dart';
import '../widgets/weather_error_view.dart';
import '../widgets/weather_initial_view.dart';
import '../widgets/weather_loading_view.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({
    this.cachedNoticeFormatter = const CachedWeatherNoticeFormatter(),
    this.weatherCardFormatter = const WeatherCardFormatter(),
    this.weatherErrorFormatter = const WeatherErrorFormatter(),
    this.now = DateTime.now,
    super.key,
  });

  final CachedWeatherNoticeFormatter cachedNoticeFormatter;
  final WeatherCardFormatter weatherCardFormatter;
  final WeatherErrorFormatter weatherErrorFormatter;
  final DateTime Function() now;

  void _retryLastSearch(BuildContext context) {
    context.read<WeatherBloc>().add(const WeatherRetryRequested());
  }

  Widget _buildWeatherState(BuildContext context, WeatherState state) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return switch (state) {
      WeatherInitial() => const WeatherInitialView(),
      WeatherLoading() => const WeatherLoadingView(),
      WeatherSuccess() => Column(
        key: const Key('weatherSuccessContent'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isFromCache) ...[
            CachedWeatherNotice(
              data: cachedNoticeFormatter.format(
                city: state.weather.cityName,
                cachedAt: state.cachedAt!,
                now: now(),
                localizations: localizations,
                locale: locale,
              ),
            ),
            SizedBox(height: 16.h),
          ],
          WeatherCard(
            data: weatherCardFormatter.format(
              weather: state.weather,
              localizations: localizations,
              locale: locale,
            ),
          ),
        ],
      ),
      WeatherFailure() => WeatherErrorView(
        data: weatherErrorFormatter.format(
          failureType: state.type,
          localizations: localizations,
        ),
        onRetry: () => _retryLastSearch(context),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: DecoratedBox(
        key: const Key('weatherPageBackground'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.45),
              Theme.of(context).colorScheme.surface,
            ],
            stops: const [0, 0.42],
          ),
        ),
        child: SafeArea(
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
                        Container(
                          key: const Key('weatherBrandIcon'),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.cloud_outlined,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            localizations.appTitle,
                            key: const Key('weatherPageTitle'),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        const LanguageSwitcher(),
                      ],
                    ),
                    SizedBox(height: 28.h),
                    const CitySearchForm(),
                    SizedBox(height: 32.h),
                    BlocBuilder<WeatherBloc, WeatherState>(
                      builder: (context, state) {
                        return KeyedSubtree(
                          key: const Key('weatherStateContent'),
                          child: _buildWeatherState(context, state),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
