import 'package:flutter/foundation.dart';
import 'package:rasht/src/rasht_log_entry.dart';

/// In-memory store for captured API log entries.
///
/// Listens via [ChangeNotifier] so [RashtOverlay] can rebuild when new requests
/// arrive. Use [instance] for the default singleton, or create your own for tests.
class RashtStore extends ChangeNotifier {
  RashtStore._();

  /// Shared store used by [RashtInterceptor] and [RashtOverlay] by default.
  static final RashtStore instance = RashtStore._();

  /// Maximum number of entries kept in memory (oldest are dropped).
  static const int maxEntries = 200;

  final List<RashtLogEntry> _entries = [];

  /// All captured entries, newest first.
  List<RashtLogEntry> get entries => List.unmodifiable(_entries);

  /// Number of captured entries.
  int get count => _entries.length;

  /// Records a new in-flight request.
  void addEntry(RashtLogEntry entry) {
    _entries.insert(0, entry);
    _trim();
    notifyListeners();
  }

  /// Marks a request as successfully completed.
  void completeEntry({
    required String id,
    required int? statusCode,
    dynamic responseBody,
  }) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index == -1) return;

    _entries[index] = _entries[index].copyWith(
      finishedAt: DateTime.now(),
      statusCode: statusCode,
      responseBody: responseBody,
      status: RashtLogStatus.success,
    );
    notifyListeners();
  }

  /// Marks a request as failed.
  void failEntry({
    required String id,
    required String errorMessage,
    int? statusCode,
    dynamic responseBody,
  }) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index == -1) return;

    _entries[index] = _entries[index].copyWith(
      finishedAt: DateTime.now(),
      statusCode: statusCode,
      responseBody: responseBody,
      errorMessage: errorMessage,
      status: RashtLogStatus.failure,
    );
    notifyListeners();
  }

  /// Removes all captured entries.
  void clear() {
    _entries.clear();
    notifyListeners();
  }

  void _trim() {
    if (_entries.length <= maxEntries) return;
    _entries.removeRange(maxEntries, _entries.length);
  }
}
