import 'package:flutter/foundation.dart';
import 'package:rasht/src/rasht_error_entry.dart';
import 'package:rasht/src/rasht_log_entry.dart';

/// In-memory store for captured API requests and app errors.
class RashtStore extends ChangeNotifier {
  RashtStore._();

  /// Default singleton used by [RashtOverlay] and [RashtInterceptor].
  static final RashtStore instance = RashtStore._();

  /// Maximum number of request entries kept in memory.
  static const int maxEntries = 200;

  /// Maximum number of error entries kept in memory.
  static const int maxErrors = 100;

  final List<RashtLogEntry> _entries = [];
  final List<RashtErrorEntry> _errors = [];

  /// Captured API requests, newest first.
  List<RashtLogEntry> get entries => List.unmodifiable(_entries);

  /// Captured app errors, newest first.
  List<RashtErrorEntry> get errors => List.unmodifiable(_errors);

  /// Number of captured requests.
  int get count => _entries.length;

  /// Number of captured errors.
  int get errorCount => _errors.length;

  /// Combined request and error count (used for the FAB badge).
  int get totalCount => _entries.length + _errors.length;

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

  /// Records a captured app error.
  void addError(RashtErrorEntry entry) {
    _errors.insert(0, entry);
    _trimErrors();
    notifyListeners();
  }

  /// Clears all captured requests.
  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Clears all captured errors.
  void clearErrors() {
    _errors.clear();
    notifyListeners();
  }

  /// Clears all captured requests and errors.
  void clearAll() {
    _entries.clear();
    _errors.clear();
    notifyListeners();
  }

  void _trim() {
    if (_entries.length <= maxEntries) return;
    _entries.removeRange(maxEntries, _entries.length);
  }

  void _trimErrors() {
    if (_errors.length <= maxErrors) return;
    _errors.removeRange(maxErrors, _errors.length);
  }
}
