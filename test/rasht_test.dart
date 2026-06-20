import 'package:flutter_test/flutter_test.dart';
import 'package:rasht/rasht.dart';

void main() {
  group('RashtRedactor', () {
    test('redacts authorization headers', () {
      final result = RashtRedactor.redactHeaders({
        'Authorization': 'Bearer secret-token',
        'Content-Type': 'application/json',
      });

      expect(result!['Authorization'], '***REDACTED***');
      expect(result['Content-Type'], 'application/json');
    });

    test('redacts sensitive json fields', () {
      final result = RashtRedactor.redactMap({
        'email': 'user@example.com',
        'password': 'hunter2',
      });

      expect(result!['email'], 'user@example.com');
      expect(result['password'], '***REDACTED***');
    });
  });

  group('RashtStore', () {
    test('tracks requests and errors', () {
      final store = RashtStore.instance;
      store.clearAll();

      store.addEntry(
        RashtLogEntry(
          id: '1',
          startedAt: DateTime.now(),
          method: 'GET',
          url: 'https://api.example.com/users',
        ),
      );
      store.addError(
        RashtErrorEntry(
          id: 'e1',
          occurredAt: DateTime(2026, 1, 1),
          kind: RashtErrorKind.dart,
          message: 'test error',
          file: 'main.dart',
          line: 10,
        ),
      );

      expect(store.count, 1);
      expect(store.errorCount, 1);
      expect(store.totalCount, 2);

      store.clearAll();
      expect(store.totalCount, 0);
    });
  });

  group('RashtErrorEntry', () {
    test('parses file and line from stack trace', () {
      final location = RashtErrorEntry.parseLocation(
        StackTrace.fromString('''
#0      main (package:my_app/main.dart:42:5)
#1      _run (dart:async/zone.dart:100:3)
'''),
      );

      expect(location.file, 'main.dart');
      expect(location.line, 42);
    });
  });

  group('RashtLogEntry', () {
    test('builds a curl command', () {
      final entry = RashtLogEntry(
        id: '1',
        startedAt: DateTime.now(),
        method: 'GET',
        url: 'https://api.example.com/users',
        requestHeaders: {'Accept': 'application/json'},
      );

      expect(entry.toCurl, contains('curl'));
      expect(entry.toCurl, contains('api.example.com/users'));
    });
  });
}
