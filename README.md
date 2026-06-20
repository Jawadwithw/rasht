# Rasht

**Rain City API tracing for Flutter.**

Rasht is named after Rasht, Iran — the Rain City. It gives testers and developers an in-app umbrella button that captures Dio REST requests, app errors, and exportable session reports — with cURL, Postman, and redacted share output.

## Features

- Dio interceptor that logs every request/response
- Draggable umbrella FAB with combined request + error badge
- Full-screen inspector with Requests and Errors tabs
- Error capture (Flutter, Dart, zone) with file, line, and stack trace
- Request detail view with URL, headers, body, and response
- Copy cURL and Postman Collection v2.1 JSON per request
- Export full session as text, JSON, or HTML (auto-redacted)
- Device and app metadata in every exported report

## Quick start

Add the dependency:

```yaml
dependencies:
  rasht: ^0.4.0
```

Wire Dio, overlay, and error capture:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasht/rasht.dart';

final dio = Dio();
final router = GoRouter(routes: [...]);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Rasht.enabled) {
    dio.interceptors.add(RashtInterceptor(RashtStore.instance));
  }

  Rasht.initialize(appRunner: () => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      builder: (context, child) {
        return RashtOverlay(
          navigatorKey: router.routerDelegate.navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
```

Tap the umbrella FAB to open the full-screen inspector.

## Release / tester builds

By default Rasht is **off** in release mode. Enable it for internal QA builds:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Rasht.enabled = true;
  Rasht.sessionExtras = {
    'environment': 'staging',
    'testerId': 'qa-42',
  };
  Rasht.initialize(appRunner: () => runApp(const MyApp()));
}
```

Or pass `enabled` per widget/interceptor:

```dart
RashtOverlay(enabled: true, child: child)
RashtInterceptor(store, enabled: true)
```

## Session export

Open Rasht → tap the share icon → copy or share a redacted report. Sensitive headers and fields (tokens, passwords, API keys) are masked automatically.

## Postman import

Tap **Copy for Postman** on any request, then in Postman: **Import → Raw text → Paste**.

## Additional resources

* [API documentation](https://pub.dev/documentation/rasht/latest/)
* [Issue tracker](https://github.com/Jawadwithw/rasht/issues)
* [Source repository](https://github.com/Jawadwithw/rasht)

## License

MIT — see [LICENSE](LICENSE).
