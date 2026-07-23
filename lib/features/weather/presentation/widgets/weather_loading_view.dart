import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/generated/app_localizations.dart';

class WeatherLoadingView extends StatelessWidget {
  const WeatherLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: localizations.loadingWeather,
      child: ExcludeSemantics(
        child: Padding(
          key: const Key('weatherLoadingView'),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                key: Key('weatherLoadingIndicator'),
              ),
              SizedBox(height: 16.h),
              Text(
                localizations.loadingWeather,
                key: const Key('weatherLoadingMessage'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
