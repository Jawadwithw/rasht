/// Kind of captured runtime error.
enum RashtErrorKind {
  /// Flutter framework error (`FlutterError.onError`).
  flutter,

  /// Uncaught async error ([PlatformDispatcher.onError]).
  dart,

  /// Error thrown inside a guarded zone.
  zone,
}

/// A captured app error with location and stack trace.
class RashtErrorEntry {
  /// Creates an error entry.
  const RashtErrorEntry({
    required this.id,
    required this.occurredAt,
    required this.kind,
    required this.message,
    this.file,
    this.line,
    this.stackTrace,
  });

  /// Unique identifier for this error entry.
  final String id;

  /// When the error occurred.
  final DateTime occurredAt;

  /// Error category.
  final RashtErrorKind kind;

  /// Human-readable error message.
  final String message;

  /// Source file, when available.
  final String? file;

  /// Source line number, when available.
  final int? line;

  /// Full stack trace text, when available.
  final String? stackTrace;

  /// Display label for [kind].
  String get kindLabel {
    switch (kind) {
      case RashtErrorKind.flutter:
        return 'Flutter';
      case RashtErrorKind.dart:
        return 'Dart';
      case RashtErrorKind.zone:
        return 'Zone';
    }
  }

  /// `file:line` label for list tiles.
  String get locationLabel {
    if (file == null && line == null) return 'Unknown location';
    if (line == null) return file!;
    return '$file:$line';
  }

  /// One-line summary for compact display.
  String get summary => [
        message,
        if (file != null || line != null) 'at $locationLabel',
      ].join(' ');

  /// Multi-line text suitable for clipboard export.
  String get detailText => [
        'Kind: $kindLabel',
        'Reason: $message',
        'File: ${file ?? '(unknown)'}',
        'Line: ${line?.toString() ?? '(unknown)'}',
        if (stackTrace != null && stackTrace!.isNotEmpty) ...[
          '',
          'Stack trace:',
          stackTrace!,
        ],
      ].join('\n');

  /// Extracts the first app frame from a [StackTrace].
  static ({String? file, int? line}) parseLocation(StackTrace? stack) {
    if (stack == null) return (file: null, line: null);

    final framePattern = RegExp(
      r'\((?:package:[^/]+/)?([^:)]+):(\d+)(?::\d+)?\)',
    );
    final skippedPackages = {'flutter', 'dart', 'rasht'};

    for (final line in stack.toString().split('\n')) {
      final match = framePattern.firstMatch(line);
      if (match == null) continue;

      final file = match.group(1);
      final lineNumber = int.tryParse(match.group(2) ?? '');
      if (file == null || lineNumber == null) continue;

      final packageMatch = RegExp(r'package:([^/]+)/').firstMatch(line);
      final package = packageMatch?.group(1);
      if (package != null && skippedPackages.contains(package)) continue;

      return (file: file, line: lineNumber);
    }

    return (file: null, line: null);
  }
}
