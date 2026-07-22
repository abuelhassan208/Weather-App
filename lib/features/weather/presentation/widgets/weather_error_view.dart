import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../logic/bloc/weather_state.dart';

class WeatherErrorView extends StatelessWidget {
  const WeatherErrorView({
    required this.failureType,
    required this.onRetry,
    super.key,
  });

  final WeatherFailureType failureType;
  final VoidCallback onRetry;

  String _messageForFailure(
    AppLocalizations localizations,
    WeatherFailureType failureType,
  ) {
    return switch (failureType) {
      WeatherFailureType.invalidCity => localizations.invalidCityError,
      WeatherFailureType.noInternet => localizations.noInternetError,
      WeatherFailureType.timeout => localizations.timeoutError,
      WeatherFailureType.unauthorized => localizations.unauthorizedError,
      WeatherFailureType.server => localizations.serverError,
      WeatherFailureType.cache => localizations.cacheError,
      WeatherFailureType.configuration => localizations.configurationError,
      WeatherFailureType.unknown => localizations.unknownError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      container: true,
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
            Text(
              _messageForFailure(localizations, failureType),
              key: const Key('weatherErrorMessage'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              key: const Key('weatherRetryButton'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(localizations.tryAgainButton),
            ),
          ],
        ),
      ),
    );
  }
}
