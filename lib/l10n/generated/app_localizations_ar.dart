// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق الطقس';

  @override
  String get foundationReady => 'تم تجهيز الأساس المبدئي لتطبيق الطقس';

  @override
  String get weatherInitialMessage => 'ابحث عن مدينة لعرض حالة الطقس الحالية.';

  @override
  String get cityInputLabel => 'المدينة';

  @override
  String get cityInputHint => 'أدخل اسم المدينة';

  @override
  String get searchButton => 'بحث';

  @override
  String get loadingWeather => 'جارٍ تحميل بيانات الطقس...';

  @override
  String get cachedWeatherNotice => 'يتم عرض آخر بيانات طقس محفوظة.';

  @override
  String get tryAgainButton => 'إعادة المحاولة';

  @override
  String get temperatureLabel => 'درجة الحرارة';

  @override
  String get feelsLikeLabel => 'المحسوسة';

  @override
  String get humidityLabel => 'الرطوبة';

  @override
  String get windSpeedLabel => 'سرعة الرياح';

  @override
  String get lastUpdatedLabel => 'آخر تحديث';

  @override
  String temperatureValue(num value) {
    return '$value°م';
  }

  @override
  String humidityValue(int value) {
    return '$value٪';
  }

  @override
  String windSpeedValue(num value) {
    return '$value كم/س';
  }

  @override
  String get invalidCityError =>
      'لم يتم العثور على المدينة. تحقق من اسم المدينة.';

  @override
  String get noInternetError =>
      'لا يوجد اتصال بالإنترنت. تحقق من الاتصال ثم حاول مرة أخرى.';

  @override
  String get timeoutError => 'استغرق الطلب وقتًا طويلًا. حاول مرة أخرى.';

  @override
  String get unauthorizedError => 'تعذر الوصول إلى خدمة الطقس.';

  @override
  String get serverError =>
      'خدمة الطقس غير متاحة حاليًا. حاول مرة أخرى لاحقًا.';

  @override
  String get cacheError => 'تعذر تحميل بيانات الطقس المحفوظة.';

  @override
  String get configurationError => 'لم يتم إعداد التطبيق بصورة صحيحة.';

  @override
  String get unknownError => 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
