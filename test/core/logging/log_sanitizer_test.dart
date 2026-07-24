import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/logging/log_sanitizer.dart';

void main() {
  const sanitizer = LogSanitizer();

  test(
    'redacts sensitive map keys case-insensitively without mutating input',
    () {
      final source = <String, Object?>{
        'API_KEY': 'api-secret',
        'Authorization': 'Bearer auth-secret',
        'Cookie': 'session-secret',
        'safe': 'visible',
        'nested': {
          'password': 'password-secret',
          'items': [
            {'CLIENT-SECRET': 'client-secret'},
            'ordinary',
          ],
        },
      };

      final result = sanitizer.sanitizeMap(source);

      expect(result['API_KEY'], LogSanitizer.redacted);
      expect(result['Authorization'], LogSanitizer.redacted);
      expect(result['Cookie'], LogSanitizer.redacted);
      expect(result['safe'], 'visible');
      expect(((result['nested']! as Map)['items']! as List).first, {
        'CLIENT-SECRET': LogSanitizer.redacted,
      });
      expect(source['API_KEY'], 'api-secret');
    },
  );

  test('redacts sensitive URL query parameters and preserves safe values', () {
    final result = sanitizer.sanitizeUrl(
      'https://example.test/weather?key=api-secret&q=Cairo&token=t',
    );

    expect(result, contains('key=%5BREDACTED%5D'));
    expect(result, contains('token=%5BREDACTED%5D'));
    expect(result, contains('q=Cairo'));
    expect(result, isNot(contains('api-secret')));
  });

  test('redacts bearer tokens and key-value secrets in arbitrary text', () {
    final result = sanitizer.sanitizeText(
      'Authorization: Bearer abc123 password=hidden safe=value',
    );

    expect(result, isNot(contains('abc123')));
    expect(result, isNot(contains('hidden')));
    expect(result, contains('safe=value'));
  });

  test('handles null and truncates encoded nested values', () {
    expect(sanitizer.sanitize(null), isNull);
    expect(
      sanitizer.encode({'secret': 'hidden', 'safe': '123456'}, maxLength: 12),
      contains('[TRUNCATED]'),
    );
  });
}
