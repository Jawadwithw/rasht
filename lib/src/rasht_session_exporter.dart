import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rasht/src/rasht_session_report.dart';
import 'package:rasht/src/rasht_store.dart';
import 'package:share_plus/share_plus.dart';

/// Copies or shares redacted session reports.
class RashtSessionExporter {
  const RashtSessionExporter._();

  /// Copies a report to the clipboard.
  static Future<void> copy({
    required RashtStore store,
    required RashtReportFormat format,
    String? locale,
    Map<String, String>? extras,
  }) async {
    final report = await RashtSessionReport.build(
      store: store,
      format: format,
      locale: locale,
      extras: extras,
    );
    await Clipboard.setData(ClipboardData(text: report));
  }

  /// Shares a report via the platform share sheet.
  static Future<void> share({
    required RashtStore store,
    required RashtReportFormat format,
    String? locale,
    Map<String, String>? extras,
    Rect? sharePositionOrigin,
  }) async {
    final report = await RashtSessionReport.build(
      store: store,
      format: format,
      locale: locale,
      extras: extras,
    );

    if (format == RashtReportFormat.html) {
      final file = await _writeTempFile(report, 'rasht-session-report.html');
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/html')],
        subject: 'Rasht session report',
        sharePositionOrigin: sharePositionOrigin,
      );
      return;
    }

    await Share.share(
      report,
      subject: 'Rasht session report',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<File> _writeTempFile(String contents, String name) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$name');
    await file.writeAsString(contents);
    return file;
  }
}
