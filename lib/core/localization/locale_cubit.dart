import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit({required SharedPreferences preferences})
    : _preferences = preferences,
      super(_readSavedLocale(preferences));

  static const localePreferenceKey = 'selected_locale';

  static const supportedLanguageCodes = <String>{'en', 'ar'};

  final SharedPreferences _preferences;

  static Locale? _readSavedLocale(SharedPreferences preferences) {
    final languageCode = preferences.getString(localePreferenceKey);

    if (languageCode == null ||
        !supportedLanguageCodes.contains(languageCode)) {
      return null;
    }

    return Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    final languageCode = locale.languageCode;

    if (!supportedLanguageCodes.contains(languageCode)) {
      throw ArgumentError.value(
        languageCode,
        'languageCode',
        'Unsupported language code',
      );
    }

    if (state?.languageCode == languageCode) {
      return;
    }

    final saved = await _preferences.setString(
      localePreferenceKey,
      languageCode,
    );

    if (!saved) {
      return;
    }

    emit(Locale(languageCode));
  }
}
