import 'package:flutter/foundation.dart';
import 'package:rasht/src/rasht_log_entry.dart';

class RashtStore extends ChangeNotifier {
  RashtStore._();

  static final RashtStore instance = RashtStore._();

  static const int maxEntries = 200;

  final List<RashtLogEntry> _entries = [];

  List<RashtLogEntry> get entries => List.unmodifiable(_entries);

  int get count => _entries.length;

  void addEntry(RashtLogEntry entry) {
    _entries.insert(0, entry);
    _trim();
    notifyListeners();
  }

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

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  void _trim() {
    if (_entries.length <= maxEntries) return;
    _entries.removeRange(maxEntries, _entries.length);
  }
}
