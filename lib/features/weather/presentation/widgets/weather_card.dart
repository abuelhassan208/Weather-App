import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/weather_model.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({required this.weather, super.key});

  final WeatherModel weather;

  Widget _buildWeatherIcon() {
    if (weather.iconUrl.trim().isEmpty) {
      return const Icon(
        Icons.cloud_outlined,
        key: Key('weatherIconFallback'),
        size: 48,
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
        return const Icon(
          Icons.cloud_outlined,
          key: Key('weatherIconFallback'),
          size: 48,
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
    final lastUpdatedText = weather.lastUpdated.trim().isEmpty
        ? '—'
        : weather.lastUpdated;

    return Card(
      key: const Key('weatherCard'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 480;

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
                            Text(
                              location,
                              key: const Key('weatherLocation'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
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
                      Text(
                        localizations.temperatureValue(weather.temperatureC),
                        key: const Key('weatherTemperature'),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
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
                            child: Text(
                              location,
                              key: const Key('weatherLocation'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildWeatherIcon(),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              conditionText,
                              key: const Key('weatherCondition'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            localizations.temperatureValue(
                              weather.temperatureC,
                            ),
                            key: const Key('weatherTemperature'),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
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
                    ),
                    _WeatherMetric(
                      key: const Key('weatherHumidity'),
                      icon: Icons.water_drop_outlined,
                      label: localizations.humidityLabel,
                      value: localizations.humidityValue(weather.humidity),
                    ),
                    _WeatherMetric(
                      key: const Key('weatherWindSpeed'),
                      icon: Icons.air,
                      label: localizations.windSpeedLabel,
                      value: localizations.windSpeedValue(weather.windKph),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  '${localizations.lastUpdatedLabel}: $lastUpdatedText',
                  key: const Key('weatherLastUpdated'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
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
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20.w, color: theme.colorScheme.secondary),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
