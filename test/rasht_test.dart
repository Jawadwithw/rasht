import 'package:flutter_test/flutter_test.dart';
import 'package:rasht/rasht.dart';

void main() {
  test('buildCurl includes method and url', () {
    final curl = RashtLogEntry.buildCurl(
      method: 'GET',
      url: 'https://example.com/api/users',
    );

    expect(curl, contains('curl --location'));
    expect(curl, contains('https://example.com/api/users'));
  });

  test('buildPostmanCollection produces valid collection name', () {
    final json = RashtLogEntry.buildPostmanCollection(
      name: 'GET /api/users',
      entries: [
        RashtLogEntry(
          id: '1',
          startedAt: DateTime(2026),
          method: 'GET',
          url: 'https://example.com/api/users',
        ),
      ],
    );

    expect(json, contains('"name": "GET /api/users"'));
    expect(json, contains('postman.com/json/collection/v2.1.0/collection.json'));
  });
}
