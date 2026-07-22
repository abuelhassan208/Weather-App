import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/generated/app_localizations.dart';

class CachedWeatherNotice extends StatelessWidget {
  const CachedWeatherNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
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
                localizations.cachedWeatherNotice,
                key: const Key('cachedWeatherMessage'),
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
