import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/weather_card_data.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({required this.data, super.key});

  final WeatherCardData data;

  Widget _buildWeatherIcon() {
    if (data.iconUrl == null) {
      return const ExcludeSemantics(
        child: Icon(
          Icons.cloud_outlined,
          key: Key('weatherIconFallback'),
          size: 48,
        ),
      );
    }

    return Image.network(
      data.iconUrl!,
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
    final theme = Theme.of(context);

    return Card(
      key: const Key('weatherCard'),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide =
                constraints.maxWidth >= 560 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.5;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide)
                  Row(
                    key: const Key('weatherCardWideLayout'),
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildWeatherIcon(),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label: data.locationSemanticLabel,
                              child: ExcludeSemantics(
                                child: Text(
                                  data.locationText,
                                  key: const Key('weatherLocation'),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Semantics(
                              label: data.conditionSemanticLabel,
                              child: ExcludeSemantics(
                                child: Text(
                                  data.conditionText,
                                  key: const Key('weatherCondition'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        label: data.temperatureSemanticLabel,
                        child: ExcludeSemantics(
                          child: Text(
                            data.temperatureText,
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
                    key: const Key('weatherCardNarrowLayout'),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Semantics(
                              label: data.locationSemanticLabel,
                              child: ExcludeSemantics(
                                child: Text(
                                  data.locationText,
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
                          Semantics(
                            label: data.conditionSemanticLabel,
                            child: ExcludeSemantics(
                              child: Text(
                                data.conditionText,
                                key: const Key('weatherCondition'),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Semantics(
                            label: data.temperatureSemanticLabel,
                            child: ExcludeSemantics(
                              child: Text(
                                data.temperatureText,
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
                      label: data.feelsLikeLabel,
                      value: data.feelsLikeText,
                      semanticsLabel: data.feelsLikeSemanticLabel,
                    ),
                    _WeatherMetric(
                      key: const Key('weatherHumidity'),
                      icon: Icons.water_drop_outlined,
                      label: data.humidityLabel,
                      value: data.humidityText,
                      semanticsLabel: data.humiditySemanticLabel,
                    ),
                    _WeatherMetric(
                      key: const Key('weatherWindSpeed'),
                      icon: Icons.air,
                      label: data.windSpeedLabel,
                      value: data.windSpeedText,
                      semanticsLabel: data.windSemanticLabel,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Semantics(
                  label: data.lastUpdatedSemanticLabel,
                  child: ExcludeSemantics(
                    child: Text(
                      data.lastUpdatedText,
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
