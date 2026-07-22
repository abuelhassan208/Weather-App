import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/generated/app_localizations.dart';

class WeatherInitialView extends StatelessWidget {
  const WeatherInitialView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      child: Padding(
        key: const Key('weatherInitialView'),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore_outlined,
              key: const Key('weatherInitialIcon'),
              size: 56.r,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 16.h),
            Text(
              localizations.weatherInitialMessage,
              key: const Key('weatherInitialMessage'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
