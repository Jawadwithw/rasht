import 'dart:convert';

import 'package:rasht/src/rasht_error_entry.dart';
import 'package:rasht/src/rasht_log_entry.dart';
import 'package:rasht/src/rasht_redactor.dart';
import 'package:rasht/src/rasht_session_metadata.dart';
import 'package:rasht/src/rasht_store.dart';

enum RashtReportFormat {
  /// JSON report.
  json,

  /// Plain-text report for Jira or Slack.
  text,

  /// HTML report file.
  html,
}

/// Builds redacted session reports from a [RashtStore].
class RashtSessionReport {
  const RashtSessionReport._();

/// Builds a redacted session report from [store].
  static Future<String> build({
    required RashtStore store,
    required RashtReportFormat format,
    String? locale,
    Map<String, String>? extras,
  }) async {
    final metadata = await RashtSessionMetadata.collect(
      locale: locale,
      extras: extras,
    );
    final exportedAt = DateTime.now().toUtc();
    final payload = _buildPayload(
      store: store,
      metadata: metadata,
      exportedAt: exportedAt,
    );

    switch (format) {
      case RashtReportFormat.json:
        return const JsonEncoder.withIndent('  ').convert(payload);
      case RashtReportFormat.text:
        return _toText(payload);
      case RashtReportFormat.html:
        return _toHtml(payload);
    }
  }

  static Map<String, dynamic> _buildPayload({
    required RashtStore store,
    required RashtSessionMetadata metadata,
    required DateTime exportedAt,
  }) {
    return {
      'rashtVersion': '0.3.1',
      'exportedAt': exportedAt.toIso8601String(),
      'metadata': metadata.toJson(),
      'summary': {
        'requestCount': store.count,
        'errorCount': store.errorCount,
      },
      'requests': store.entries.map(_requestToJson).toList(),
      'errors': store.errors.map(_errorToJson).toList(),
    };
  }

  static Map<String, dynamic> _requestToJson(RashtLogEntry entry) {
    return {
      'id': entry.id,
      'startedAt': entry.startedAt.toIso8601String(),
      if (entry.finishedAt != null)
        'finishedAt': entry.finishedAt!.toIso8601String(),
      if (entry.duration != null)
        'durationMs': entry.duration!.inMilliseconds,
      'method': entry.method,
      'url': RashtRedactor.redactUrl(entry.url),
      if (entry.queryParameters != null)
        'queryParameters':
            RashtRedactor.redactMap(Map<String, dynamic>.from(entry.queryParameters!)),
      if (entry.requestHeaders != null)
        'requestHeaders': RashtRedactor.redactHeaders(
          Map<String, dynamic>.from(entry.requestHeaders!),
        ),
      'requestBody': RashtRedactor.redactValue(entry.requestBody),
      'statusCode': entry.statusCode,
      'status': entry.status.name,
      if (entry.errorMessage != null)
        'errorMessage': RashtRedactor.redactString(entry.errorMessage!),
      'responseBody': RashtRedactor.redactValue(entry.responseBody),
    };
  }

  static Map<String, dynamic> _errorToJson(RashtErrorEntry entry) {
    return {
      'id': entry.id,
      'occurredAt': entry.occurredAt.toIso8601String(),
      'kind': entry.kind.name,
      'message': RashtRedactor.redactString(entry.message),
      'file': entry.file,
      'line': entry.line,
      if (entry.stackTrace != null)
        'stackTrace': RashtRedactor.redactString(entry.stackTrace!),
    };
  }

  static String _toText(Map<String, dynamic> payload) {
    final buffer = StringBuffer();
    final metadata = payload['metadata'] as Map<String, dynamic>;
    final summary = payload['summary'] as Map<String, dynamic>;
    final requests = payload['requests'] as List<dynamic>;
    final errors = payload['errors'] as List<dynamic>;

    buffer.writeln('RASHT SESSION REPORT');
    buffer.writeln('=====================');
    buffer.writeln('Exported: ${payload['exportedAt']}');
    buffer.writeln();
    buffer.writeln('APP');
    buffer.writeln('---');
    buffer.writeln('Name: ${metadata['appName']}');
    buffer.writeln('Package: ${metadata['packageName']}');
    buffer.writeln('Version: ${metadata['version']} (${metadata['buildNumber']})');
    buffer.writeln('Platform: ${metadata['platform']}');
    buffer.writeln('OS: ${metadata['osVersion']}');
    buffer.writeln('Device: ${metadata['deviceModel']}');
    buffer.writeln('Locale: ${metadata['locale']}');
    final extras = metadata['extras'] as Map<String, dynamic>?;
    if (extras != null && extras.isNotEmpty) {
      buffer.writeln('Extras:');
      for (final entry in extras.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }
    buffer.writeln();
    buffer.writeln(
      'SUMMARY: ${summary['requestCount']} requests, ${summary['errorCount']} errors',
    );
    buffer.writeln();

    if (errors.isNotEmpty) {
      buffer.writeln('ERRORS');
      buffer.writeln('------');
      for (final error in errors) {
        final map = error as Map<String, dynamic>;
        buffer.writeln('[${map['occurredAt']}] ${map['kind']}');
        buffer.writeln('  ${map['message']}');
        buffer.writeln('  at ${map['file'] ?? '?'}:${map['line'] ?? '?'}');
        buffer.writeln();
      }
    }

    if (requests.isNotEmpty) {
      buffer.writeln('REQUESTS');
      buffer.writeln('--------');
      for (final request in requests) {
        final map = request as Map<String, dynamic>;
        buffer.writeln(
          '[${map['startedAt']}] ${map['method']} ${map['statusCode'] ?? '...'} ${map['url']}',
        );
        if (map['durationMs'] != null) {
          buffer.writeln('  duration: ${map['durationMs']}ms');
        }
        if (map['errorMessage'] != null) {
          buffer.writeln('  error: ${map['errorMessage']}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('Sensitive values were redacted before export.');
    return buffer.toString();
  }

  static String _toHtml(Map<String, dynamic> payload) {
    final text = _escapeHtml(_toText(payload));
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Rasht Session Report</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 24px; color: #1f2937; }
    pre { background: #f3f7fa; padding: 16px; border-radius: 12px; overflow-x: auto; white-space: pre-wrap; line-height: 1.5; }
  </style>
</head>
<body>
  <pre>$text</pre>
</body>
</html>
''';
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
