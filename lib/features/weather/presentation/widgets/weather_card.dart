import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/weather_model.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({required this.weather, super.key});

  final WeatherModel weather;

  Widget _buildWeatherIcon() {
    if (weather.iconUrl.trim().isEmpty) {
      return const ExcludeSemantics(
        child: Icon(
          Icons.cloud_outlined,
          key: Key('weatherIconFallback'),
          size: 48,
        ),
      );
    }

    return Image.network(
      weather.iconUrl,
      key: const Key('weatherNetworkIcon'),
      width: 64.w,
      height: 64.w,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) {
        // Show fallback cloud icon if image fails to load.
        return const ExcludeSemantics(
          child: Icon(
            Icons.cloud_outlined,
            key: Key('weatherIconFallback'),
            size: 48,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final rawLocation = [
      weather.cityName,
      weather.country,
    ].where((value) => value.trim().isNotEmpty).join(', ');
    final location = rawLocation.isEmpty ? '—' : rawLocation;

    final conditionText = weather.conditionText.trim().isEmpty
        ? '—'
        : weather.conditionText;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final lastUpdatedText = DateFormat.yMMMd(
      locale,
    ).add_jm().format(weather.lastUpdated.toLocal());
    final temperatureText = localizations.temperatureValue(
      weather.temperatureC,
    );

    return Card(
      key: const Key('weatherCard'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildWeatherIcon(),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label: localizations.locationSemantics(location),
                              child: ExcludeSemantics(
                                child: Text(
                                  location,
                                  key: const Key('weatherLocation'),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              conditionText,
                              key: const Key('weatherCondition'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        label: localizations.temperatureSemantics(
                          temperatureText,
                        ),
                        child: ExcludeSemantics(
                          child: Text(
                            temperatureText,
                            key: const Key('weatherTemperature'),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Semantics(
                              label: localizations.locationSemantics(location),
                              child: ExcludeSemantics(
                                child: Text(
                                  location,
                                  key: const Key('weatherLocation'),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildWeatherIcon(),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            conditionText,
                            key: const Key('weatherCondition'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Semantics(
                            label: localizations.temperatureSemantics(
                              temperatureText,
                            ),
                            child: ExcludeSemantics(
                              child: Text(
                                temperatureText,
                                key: const Key('weatherTemperature'),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                SizedBox(height: 20.h),
                const Divider(),
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 16.w,
                  runSpacing: 12.h,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _WeatherMetric(
                      key: const Key('weatherFeelsLike'),
                      icon: Icons.thermostat_outlined,
                      label: localizations.feelsLikeLabel,
                      value: localizations.temperatureValue(weather.feelsLikeC),
                      semanticsLabel: localizations.feelsLikeSemantics(
                        localizations.temperatureValue(weather.feelsLikeC),
                      ),
                    ),
                    _WeatherMetric(
                      key: const Key('weatherHumidity'),
                      icon: Icons.water_drop_outlined,
                      label: localizations.humidityLabel,
                      value: localizations.humidityValue(weather.humidity),
                      semanticsLabel: localizations.humiditySemantics(
                        weather.humidity,
                      ),
                    ),
                    _WeatherMetric(
                      key: const Key('weatherWindSpeed'),
                      icon: Icons.air,
                      label: localizations.windSpeedLabel,
                      value: localizations.windSpeedValue(weather.windKph),
                      semanticsLabel: localizations.windSemantics(
                        localizations.windSpeedValue(weather.windKph),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Semantics(
                  label: localizations.lastUpdatedSemantics(lastUpdatedText),
                  child: ExcludeSemantics(
                    child: Text(
                      '${localizations.lastUpdatedLabel}: $lastUpdatedText',
                      key: const Key('weatherLastUpdated'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WeatherMetric extends StatelessWidget {
  const _WeatherMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.semanticsLabel,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20.w, color: theme.colorScheme.secondary),
            SizedBox(height: 4.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
