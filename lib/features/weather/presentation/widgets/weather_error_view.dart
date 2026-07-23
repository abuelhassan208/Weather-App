import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/weather_error_data.dart';

class WeatherErrorView extends StatelessWidget {
  const WeatherErrorView({
    required this.data,
    required this.onRetry,
    super.key,
  });

  final WeatherErrorData data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: data.message,
      child: Padding(
        key: const Key('weatherErrorView'),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              key: const Key('weatherErrorIcon'),
              size: 56.r,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 16.h),
            ExcludeSemantics(
              child: Text(
                data.message,
                key: const Key('weatherErrorMessage'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              key: const Key('weatherRetryButton'),
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.refresh),
              label: Text(data.retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
