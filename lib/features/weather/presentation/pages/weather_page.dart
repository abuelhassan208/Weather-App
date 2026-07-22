import 'package:flutter/material.dart';
import 'package:weather_app/l10n/generated/app_localizations.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(AppLocalizations.of(context).foundationReady)),
    );
  }
}
