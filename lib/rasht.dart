/// Rain City API tracing for Flutter.
///
/// Rasht captures [Dio](https://pub.dev/packages/dio) REST requests in-app and
/// lets you inspect, copy as cURL, or export as a Postman collection.
///
/// ## Quick start
///
/// ```dart
/// import 'package:dio/dio.dart';
/// import 'package:rasht/rasht.dart';
///
/// final dio = Dio();
/// if (Rasht.enabled) {
///   dio.interceptors.add(RashtInterceptor(RashtStore.instance));
/// }
///
/// MaterialApp(
///   builder: (context, child) {
///     return RashtOverlay(child: child ?? const SizedBox.shrink());
///   },
/// );
/// ```
library;

export 'src/rasht_config.dart';
export 'src/rasht_interceptor.dart';
export 'src/rasht_log_entry.dart';
export 'src/rasht_overlay.dart';
export 'src/rasht_store.dart';
