import 'dart:convert';

final class LogSanitizer {
  const LogSanitizer();

  static const String redacted = '[REDACTED]';

  static const Set<String> _sensitiveKeys = {
    'key',
    'api_key',
    'apikey',
    'authorization',
    'cookie',
    'set-cookie',
    'set_cookie',
    'token',
    'access_token',
    'refresh_token',
    'password',
    'secret',
    'client_secret',
  };

  Object? sanitize(Object? value) {
    if (value == null || value is num || value is bool) {
      return value;
    }
    if (value is Uri) {
      return sanitizeUrl(value.toString());
    }
    if (value is String) {
      return sanitizeText(value);
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _isSensitive(entry.key.toString())
              ? redacted
              : sanitize(entry.value),
      };
    }
    if (value is Iterable) {
      return value.map(sanitize).toList(growable: false);
    }

    try {
      return sanitizeText(value.toString());
    } catch (_) {
      return '<${value.runtimeType}>';
    }
  }

  Map<String, Object?> sanitizeMap(Map<Object?, Object?> source) {
    return Map<String, Object?>.unmodifiable(
      sanitize(source)! as Map<String, Object?>,
    );
  }

  String sanitizeUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.queryParametersAll.isEmpty) {
      return sanitizeText(rawUrl);
    }

    final sanitizedQuery = <String, List<String>>{
      for (final entry in uri.queryParametersAll.entries)
        entry.key: _isSensitive(entry.key)
            ? const [redacted]
            : entry.value.map(sanitizeText).toList(growable: false),
    };

    return uri.replace(queryParameters: sanitizedQuery).toString();
  }

  String sanitizeText(String value) {
    var sanitized = value.replaceAll(
      RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
      'Bearer $redacted',
    );

    for (final key in _sensitiveKeys) {
      sanitized = sanitized.replaceAllMapped(
        RegExp(
          '(^|[?&,{\\s])'
          '(${RegExp.escape(key)})'
          r'(\s*[:=]\s*)'
          r'([^&,\s}\]]+)',
          caseSensitive: false,
        ),
        (match) =>
            '${match.group(1)}${match.group(2)}${match.group(3)}$redacted',
      );
    }
    return sanitized;
  }

  String encode(Object? value, {int maxLength = 4096}) {
    final encoded = jsonEncode(sanitize(value));
    if (encoded.length <= maxLength) {
      return encoded;
    }
    return '${encoded.substring(0, maxLength)}…[TRUNCATED]';
  }

  bool _isSensitive(String key) {
    final normalized = key.trim().toLowerCase().replaceAll('-', '_');
    return _sensitiveKeys.contains(normalized);
  }
}
