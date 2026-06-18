import 'package:flutter/foundation.dart';

/// Global Rasht configuration.
abstract final class Rasht {
  /// Set to `true` to capture and show API traces in release/profile builds.
  ///
  /// Defaults to [kDebugMode]. Example for internal tester builds:
  ///
  /// ```dart
  /// void main() {
  ///   Rasht.enabled = true;
  ///   runApp(const MyApp());
  /// }
  /// ```
  static bool enabled = kDebugMode;

  static bool get isActive => enabled;
}
