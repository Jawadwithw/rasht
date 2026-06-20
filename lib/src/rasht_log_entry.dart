import 'dart:convert';

import 'package:dio/dio.dart';

/// Request completion status.
enum RashtLogStatus {
  /// Request is still in flight.
  pending,

  /// Request completed with a response.
  success,

  /// Request failed.
  failure,
}

/// A captured Dio REST request and its response.
class RashtLogEntry {
  final String id;
  final DateTime startedAt;
  final String method;
  final String url;
  final Map<String, dynamic>? queryParameters;
  final dynamic requestBody;
  final Map<String, dynamic>? requestHeaders;

  DateTime? finishedAt;
  int? statusCode;
  dynamic responseBody;
  String? errorMessage;
  RashtLogStatus status;

  RashtLogEntry({
    required this.id,
    required this.startedAt,
    required this.method,
    required this.url,
    this.queryParameters,
    this.requestBody,
    this.requestHeaders,
    this.finishedAt,
    this.statusCode,
    this.responseBody,
    this.errorMessage,
    this.status = RashtLogStatus.pending,
  });

  Duration? get duration {
    if (finishedAt == null) return null;
    return finishedAt!.difference(startedAt);
  }

  String get pathLabel {
    final uri = Uri.tryParse(url);
    return uri?.path ?? url;
  }

  /// Whether the request finished successfully.
  bool get isSuccess => status == RashtLogStatus.success;

  /// Whether the request failed.
  bool get isFailure => status == RashtLogStatus.failure;

  /// Whether the request is still pending.
  bool get isPending => status == RashtLogStatus.pending;

  RashtLogEntry copyWith({
    DateTime? finishedAt,
    int? statusCode,
    dynamic responseBody,
    String? errorMessage,
    RashtLogStatus? status,
  }) {
    return RashtLogEntry(
      id: id,
      startedAt: startedAt,
      method: method,
      url: url,
      queryParameters: queryParameters,
      requestBody: requestBody,
      requestHeaders: requestHeaders,
      finishedAt: finishedAt ?? this.finishedAt,
      statusCode: statusCode ?? this.statusCode,
      responseBody: responseBody ?? this.responseBody,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
    );
  }

  static String sanitizeBody(dynamic body) {
    if (body == null) return '';
    if (body is FormData) {
      final fields = body.fields.map((e) => '${e.key}=${e.value}').join(', ');
      final files = body.files.map((e) => e.key).join(', ');
      return 'FormData(fields: [$fields], files: [$files])';
    }
    if (body is Map || body is List) {
      return body.toString();
    }
    return body.toString();
  }

  static String formatMap(dynamic value) {
    if (value == null) return '(empty)';
    if (value is Map) {
      if (value.isEmpty) return '(empty)';
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    }
    return value.toString();
  }

  static String formatBody(dynamic body) {
    final sanitized = sanitizeBody(body);
    return sanitized.isEmpty ? '(empty)' : sanitized;
  }

  /// Postman-style cURL command for this request.
  String get toCurl => buildCurl(
        method: method,
        url: url,
        requestHeaders: requestHeaders,
        requestBody: requestBody,
      );

  /// Postman Collection v2.1 JSON for this request.
  String get toPostmanCollection => buildPostmanCollection(
        name: '$method $pathLabel',
        entries: [this],
      );

  static String buildPostmanCollection({
    required String name,
    required List<RashtLogEntry> entries,
  }) {
    final collection = <String, dynamic>{
      'info': {
        'name': name,
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
      },
      'item': entries.map(_toPostmanItem).toList(),
    };
    return const JsonEncoder.withIndent('    ').convert(collection);
  }

  static Map<String, dynamic> _toPostmanItem(RashtLogEntry entry) {
    final uri = Uri.tryParse(entry.url);
    final request = <String, dynamic>{
      'method': entry.method.toUpperCase(),
      'header': _postmanHeaders(entry.requestHeaders),
      'url': _postmanUrl(entry.url, uri),
    };

    final body = _postmanBody(entry.requestBody);
    if (body != null) {
      request['body'] = body;
    }

    return {
      'name': '${entry.method} ${entry.pathLabel}',
      'request': request,
    };
  }

  static List<Map<String, String>> _postmanHeaders(
    Map<String, dynamic>? headers,
  ) {
    if (headers == null) return [];
    return headers.entries
        .where((entry) => !_curlSkipHeaders.contains(entry.key.toLowerCase()))
        .map(
          (entry) => {
            'key': entry.key,
            'value': entry.value.toString(),
            'type': 'text',
          },
        )
        .toList();
  }

  static dynamic _postmanUrl(String url, Uri? uri) {
    if (uri == null || uri.host.isEmpty) return url;

    final query = uri.queryParameters.entries
        .map((entry) => {'key': entry.key, 'value': entry.value})
        .toList();

    return {
      'raw': url,
      'protocol': uri.scheme,
      'host': uri.host.split('.'),
      if (uri.hasPort) 'port': uri.port.toString(),
      if (uri.pathSegments.isNotEmpty) 'path': uri.pathSegments,
      if (query.isNotEmpty) 'query': query,
    };
  }

  static Map<String, dynamic>? _postmanBody(dynamic body) {
    if (body == null) return null;

    if (body is FormData) {
      final formdata = <Map<String, dynamic>>[];
      for (final field in body.fields) {
        formdata.add({
          'key': field.key,
          'value': field.value,
          'type': 'text',
        });
      }
      for (final file in body.files) {
        formdata.add({
          'key': file.key,
          'type': 'file',
          'src': file.value.filename ?? file.key,
          'description':
              'Captured from app — re-select the file in Postman before sending.',
        });
      }
      if (formdata.isEmpty) return null;
      return {'mode': 'formdata', 'formdata': formdata};
    }

    if (body is Map || body is List) {
      return {
        'mode': 'raw',
        'raw': const JsonEncoder.withIndent('    ').convert(body),
        'options': {
          'raw': {'language': 'json'},
        },
      };
    }

    if (body is String) {
      if (body.isEmpty) return null;
      final pretty = _prettyJsonIfPossible(body);
      if (pretty != null) {
        return {
          'mode': 'raw',
          'raw': pretty,
          'options': {
            'raw': {'language': 'json'},
          },
        };
      }
      return {'mode': 'raw', 'raw': body};
    }

    final text = body.toString();
    if (text.isEmpty) return null;
    return {'mode': 'raw', 'raw': text};
  }

  static String buildCurl({
    required String method,
    required String url,
    Map<String, dynamic>? requestHeaders,
    dynamic requestBody,
  }) {
    final upperMethod = method.toUpperCase();
    final buffer = StringBuffer('curl --location');

    if (upperMethod != 'GET' && upperMethod != 'POST') {
      buffer.write(' --request $upperMethod');
    } else if (upperMethod == 'POST' && !_hasCurlBody(requestBody)) {
      buffer.write(' --request POST');
    }

    buffer.write(' \\\n${_shellEscape(url)}');

    if (requestHeaders != null) {
      for (final entry in requestHeaders.entries) {
        final headerName = entry.key.toLowerCase();
        if (_curlSkipHeaders.contains(headerName)) continue;
        buffer.write(
          ' \\\n--header ${_shellEscape('${entry.key}: ${entry.value}')}',
        );
      }
    }

    if (requestBody is FormData) {
      for (final field in requestBody.fields) {
        buffer.write(
          ' \\\n--form ${_shellEscape('${field.key}=${field.value}')}',
        );
      }
      for (final file in requestBody.files) {
        final filename = file.value.filename ?? file.key;
        buffer.write(
          ' \\\n--form ${_shellEscape('${file.key}=@$filename')}',
        );
      }
    } else {
      final body = _encodeCurlBody(requestBody);
      if (body != null) {
        buffer.write(' \\\n--data ${_shellEscape(body)}');
      }
    }

    return buffer.toString();
  }

  static bool _hasCurlBody(dynamic body) {
    if (body == null) return false;
    if (body is FormData) {
      return body.fields.isNotEmpty || body.files.isNotEmpty;
    }
    if (body is String) return body.isNotEmpty;
    return true;
  }

  static const _curlSkipHeaders = {
    'content-length',
    'host',
    'connection',
  };

  static String? _encodeCurlBody(dynamic body) {
    if (body == null) return null;
    if (body is String) {
      if (body.isEmpty) return null;
      return _prettyJsonIfPossible(body) ?? body;
    }
    if (body is Map || body is List) {
      return const JsonEncoder.withIndent('    ').convert(body);
    }
    final text = body.toString();
    return text.isEmpty ? null : text;
  }

  static String? _prettyJsonIfPossible(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map || decoded is List) {
        return const JsonEncoder.withIndent('    ').convert(decoded);
      }
    } catch (_) {}
    return null;
  }

  static String _shellEscape(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }
}
