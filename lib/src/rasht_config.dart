import 'package:flutter/foundation.dart';

/// Global configuration for the Rasht API tracer.
///
/// Use [enabled] to turn tracing on in release/profile builds for internal
/// testers. By default Rasht follows [kDebugMode].
abstract final class Rasht {
  /// Whether Rasht captures requests and shows the overlay.
  ///
  /// Defaults to [kDebugMode]. Set to `true` before `runApp` for tester builds:
  ///
  /// ```dart
  /// void main() {
  ///   Rasht.enabled = true;
  ///   runApp(const MyApp());
  /// }
  /// ```
  static bool enabled = kDebugMode;

  /// Same as [enabled]. Convenience getter for conditional wiring.
  static bool get isActive => enabled;
}
