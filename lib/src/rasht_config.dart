import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rasht/src/rasht_error_handler.dart';
import 'package:rasht/src/rasht_store.dart';
/// Global Rasht configuration.
abstract final class Rasht {
  /// Set to `true` to capture and show API traces in release/profile builds.
  ///
  /// Defaults to [kDebugMode]. Example for internal tester builds:
  ///
  /// ```dart
  /// void main() {
  ///   Rasht.enabled = true;
  ///   Rasht.initialize();
  ///   runApp(const MyApp());
  /// }
  /// ```
  static bool enabled = kDebugMode;

  /// Whether Rasht is currently active ([enabled]).
  static bool get isActive => enabled;

  /// Optional key/value pairs included in exported session reports
  /// (e.g. user id, environment, flavor).
  static Map<String, String> sessionExtras = {};

  /// Optional navigator key for modals/share sheets when [RashtOverlay] is used
  /// inside [MaterialApp.builder] (above the navigator subtree).
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Installs global error capture and optionally wraps [appRunner] in a guarded zone.
  ///
  /// Call once near the start of `main()`, after
  /// `WidgetsFlutterBinding.ensureInitialized()`.
  static void initialize({
    RashtStore? store,
    bool? enabled,
    bool captureErrors = true,
    bool guardZone = true,
    void Function()? appRunner,
  }) {
    final isEnabled = enabled ?? Rasht.enabled;
    if (!isEnabled) {
      appRunner?.call();
      return;
    }

    if (captureErrors) {
      RashtErrorHandler.install(store: store, enabled: isEnabled);
    }

    if (appRunner != null) {
      if (guardZone) {
        RashtErrorHandler.runGuarded(appRunner, store: store);
      } else {
        appRunner();
      }
    }
  }
}
