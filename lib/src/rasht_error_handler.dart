import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rasht/src/rasht_config.dart';
import 'package:rasht/src/rasht_error_entry.dart';
import 'package:rasht/src/rasht_store.dart';

/// Captures Flutter framework errors, uncaught async errors, and zone errors.
class RashtErrorHandler {
  /// Utility class — do not instantiate.
  RashtErrorHandler._();

  static bool _installed = false;
  static int _counter = 0;
  static String? _lastErrorSignature;
  static DateTime? _lastErrorAt;

  /// Hooks global error handlers. Safe to call multiple times.
  static void install({
    RashtStore? store,
    bool? enabled,
  }) {
    if (_installed) return;
    if (!(enabled ?? Rasht.enabled)) return;

    final targetStore = store ?? RashtStore.instance;
    _installed = true;

    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      _recordFlutterError(targetStore, details);
      previousFlutterError?.call(details);
    };

    final previousPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _recordDartError(targetStore, error, stack, RashtErrorKind.dart);
      return previousPlatformError?.call(error, stack) ?? false;
    };
  }

  /// Runs [callback] inside [runZonedGuarded] so synchronous zone errors are captured.
  static void runGuarded(void Function() callback, {RashtStore? store}) {
    final targetStore = store ?? RashtStore.instance;
    runZonedGuarded(
      callback,
      (error, stack) => _recordDartError(
        targetStore,
        error,
        stack,
        RashtErrorKind.zone,
      ),
    );
  }

  static void _recordFlutterError(
    RashtStore store,
    FlutterErrorDetails details,
  ) {
    if (_shouldSkipError(details.exception, details.stack)) return;

    final location = RashtErrorEntry.parseLocation(details.stack);
    store.addError(
      RashtErrorEntry(
        id: _nextId(),
        occurredAt: DateTime.now(),
        kind: RashtErrorKind.flutter,
        message: _messageFrom(details.exception),
        file: location.file,
        line: location.line,
        stackTrace: details.stack?.toString(),
      ),
    );
  }

  static void _recordDartError(
    RashtStore store,
    Object error,
    StackTrace stack,
    RashtErrorKind kind,
  ) {
    if (_shouldSkipError(error, stack)) return;

    final location = RashtErrorEntry.parseLocation(stack);
    store.addError(
      RashtErrorEntry(
        id: _nextId(),
        occurredAt: DateTime.now(),
        kind: kind,
        message: _messageFrom(error),
        file: location.file,
        line: location.line,
        stackTrace: stack.toString(),
      ),
    );
  }

  static String _messageFrom(Object error) {
    if (error is Error) return error.toString();
    return error.toString();
  }

  static String _nextId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  static bool _shouldSkipError(Object error, StackTrace? stack) {
    final signature = '${error.runtimeType}:$error';
    final now = DateTime.now();
    if (_lastErrorSignature == signature &&
        _lastErrorAt != null &&
        now.difference(_lastErrorAt!) < const Duration(milliseconds: 500)) {
      return true;
    }
    _lastErrorSignature = signature;
    _lastErrorAt = now;
    return false;
  }
}
