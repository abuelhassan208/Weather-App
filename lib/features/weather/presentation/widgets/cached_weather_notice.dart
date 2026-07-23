import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';

typedef DisplayClock = DateTime Function();

class CachedWeatherNotice extends StatelessWidget {
  const CachedWeatherNotice({
    required this.cityName,
    required this.cachedAt,
    this.now,
    super.key,
  });

  final String cityName;
  final DateTime cachedAt;
  final DisplayClock? now;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final age = (now ?? DateTime.now)().toUtc().difference(cachedAt.toUtc());
    final safeMinutes = age.isNegative ? 0 : age.inMinutes;
    final ageText = safeMinutes < 1
        ? localizations.cachedJustNow
        : safeMinutes == 1
        ? localizations.cachedOneMinuteAgo
        : localizations.cachedMinutesAgo(
            NumberFormat.decimalPattern(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(safeMinutes.clamp(2, 30)),
          );
    final message = localizations.cachedWeatherDetails(cityName, ageText);

    return Semantics(
      container: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          key: const Key('cachedWeatherNotice'),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.offline_bolt_outlined,
                key: const Key('cachedWeatherIcon'),
                color: colorScheme.onSecondaryContainer,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  message,
                  key: const Key('cachedWeatherMessage'),
                  style: TextStyle(color: colorScheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
