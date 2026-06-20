/// Masks sensitive values in headers, bodies, and URLs before export.
class RashtRedactor {
  /// Utility class — do not instantiate.
  const RashtRedactor._();

  static const _masked = '***REDACTED***';

  static const _sensitiveHeaderNames = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-auth-token',
    'x-access-token',
    'x-csrf-token',
    'proxy-authorization',
  };

  static const _sensitiveFieldNames = {
    'password',
    'passwd',
    'pwd',
    'token',
    'access_token',
    'refresh_token',
    'id_token',
    'secret',
    'api_key',
    'apikey',
    'client_secret',
    'authorization',
    'auth',
    'otp',
    'pin',
    'ssn',
    'credit_card',
    'creditcard',
    'card_number',
    'cvv',
  };

  static final _bearerPattern = RegExp(
    r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  static final _jwtPattern = RegExp(
    r'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
  );

  static String redactString(String value) {
    var result = value.replaceAll(_bearerPattern, 'Bearer $_masked');
    result = result.replaceAll(_jwtPattern, _masked);
    return result;
  }

  static Map<String, dynamic>? redactHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return null;
    return headers.map((key, value) {
      if (_isSensitiveName(key)) {
        return MapEntry(key, _masked);
      }
      return MapEntry(key, redactString(value.toString()));
    });
  }

  static Map<String, dynamic>? redactMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return map.map((key, value) {
      if (_isSensitiveName(key)) {
        return MapEntry(key, _masked);
      }
      return MapEntry(key, redactValue(value));
    });
  }

  static dynamic redactValue(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((key, nested) {
        if (_isSensitiveName(key.toString())) {
          return MapEntry(key, _masked);
        }
        return MapEntry(key, redactValue(nested));
      });
    }
    if (value is List) {
      return value.map(redactValue).toList();
    }
    if (value is String) return redactString(value);
    return value;
  }

  static String redactUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return redactString(url);

    final query = uri.queryParameters.map((key, value) {
      if (_isSensitiveName(key)) return MapEntry(key, _masked);
      return MapEntry(key, redactString(value));
    });

    return uri.replace(queryParameters: query).toString();
  }

  static bool _isSensitiveName(String name) {
    final normalized = name.toLowerCase().replaceAll('-', '_');
    if (_sensitiveHeaderNames.contains(normalized)) return true;
    if (_sensitiveFieldNames.contains(normalized)) return true;
    return _sensitiveFieldNames.any(
      (field) => normalized.contains(field),
    );
  }
}
