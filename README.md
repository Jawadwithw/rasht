# Rasht

**Rasht Rain City API tracing for Flutter.**

Rasht is named after Rasht, Iran — the Rain City. It gives you an in-app floating umbrella button that captures Dio REST requests in debug builds, with one-tap cURL and Postman collection export.

## Features

- Dio interceptor that logs every request/response
- Draggable umbrella FAB with request count badge
- Request list with status, path, and duration
- Detail view with URL, headers, body, and response
- Copy cURL (Postman-style)
- Copy Postman Collection v2.1 JSON

## Release / profile builds

By default Rasht is **off** in release mode. Enable it for internal tester builds:

```dart
void main() {
  Rasht.enabled = true;
  runApp(const MyApp());
}
```

Or pass `enabled` per widget/interceptor:

```dart
RashtOverlay(enabled: true, child: child)
RashtInterceptor(store, enabled: true)
```

## Setup

```yaml
dependencies:
  rasht: ^0.1.0
```

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rasht/rasht.dart';

final dio = Dio();
if (Rasht.enabled) {
  dio.interceptors.add(RashtInterceptor(RashtStore.instance));
}
```

Wrap your app in `MaterialApp.builder`:

```dart
MaterialApp(
  builder: (context, child) {
    return RashtOverlay(child: child ?? const SizedBox.shrink());
  },
);
```

## Postman import

Tap **Copy for Postman** on any request, then in Postman: **Import → Raw text → Paste**.

## License

MIT
