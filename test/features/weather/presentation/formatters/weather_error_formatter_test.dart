import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/logic/bloc/weather_state.dart';
import 'package:weather_app/features/weather/presentation/formatters/weather_error_formatter.dart';
import 'package:weather_app/l10n/generated/app_localizations_ar.dart';
import 'package:weather_app/l10n/generated/app_localizations_en.dart';

void main() {
  const formatter = WeatherErrorFormatter();
  final english = AppLocalizationsEn();
  final arabic = AppLocalizationsAr();

  group('WeatherErrorFormatter', () {
    final englishMessages = <WeatherFailureType, String>{
      WeatherFailureType.invalidCity:
          'City not found. Please check the city name.',
      WeatherFailureType.noInternet:
          'No internet connection. Please check your connection and try again.',
      WeatherFailureType.timeout:
          'The request took too long. Please try again.',
      WeatherFailureType.unauthorized: 'Unable to access the weather service.',
      WeatherFailureType.server:
          'The weather service is currently unavailable. Please try again later.',
      WeatherFailureType.cache: 'The saved weather data could not be loaded.',
      WeatherFailureType.configuration:
          'The application is not configured correctly.',
      WeatherFailureType.unknown: 'Something went wrong. Please try again.',
    };

    for (final entry in englishMessages.entries) {
      test('formats ${entry.key.name} in English', () {
        final data = formatter.format(
          failureType: entry.key,
          localizations: english,
        );

        expect(data.message, entry.value);
        expect(data.retryLabel, 'Try again');
      });
    }

    final arabicMessages = <WeatherFailureType, String>{
      WeatherFailureType.invalidCity:
          'لم يتم العثور على المدينة. تحقق من اسم المدينة.',
      WeatherFailureType.noInternet:
          'لا يوجد اتصال بالإنترنت. تحقق من الاتصال ثم حاول مرة أخرى.',
      WeatherFailureType.timeout: 'استغرق الطلب وقتًا طويلًا. حاول مرة أخرى.',
      WeatherFailureType.unauthorized: 'تعذر الوصول إلى خدمة الطقس.',
      WeatherFailureType.server:
          'خدمة الطقس غير متاحة حاليًا. حاول مرة أخرى لاحقًا.',
      WeatherFailureType.cache: 'تعذر تحميل بيانات الطقس المحفوظة.',
      WeatherFailureType.configuration: 'لم يتم إعداد التطبيق بصورة صحيحة.',
      WeatherFailureType.unknown: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
    };

    for (final entry in arabicMessages.entries) {
      test('formats ${entry.key.name} in Arabic', () {
        final data = formatter.format(
          failureType: entry.key,
          localizations: arabic,
        );

        expect(data.message, entry.value);
        expect(data.retryLabel, 'إعادة المحاولة');
      });
    }
  });
}
