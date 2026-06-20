import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rasht/src/rasht_locale.dart';
import 'package:rasht/src/rasht_error_entry.dart';
import 'package:rasht/src/rasht_log_entry.dart';
import 'package:rasht/src/rasht_session_exporter.dart';
import 'package:rasht/src/rasht_session_report.dart';
import 'package:rasht/src/rasht_store.dart';

/// Full-screen Rasht inspector (requests, errors, export).
class RashtScreen extends StatefulWidget {
  /// Creates the inspector screen.
  const RashtScreen({super.key, this.store});

  /// Optional custom store. Defaults to [RashtStore.instance].
  final RashtStore? store;

  @override
  State<RashtScreen> createState() => _RashtScreenState();
}

class _RashtScreenState extends State<RashtScreen> {
  late final RashtStore _store = widget.store ?? RashtStore.instance;
  RashtLogEntry? _selectedEntry;
  RashtErrorEntry? _selectedError;
  _RashtPanelTab _activeTab = _RashtPanelTab.requests;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _selectEntry(RashtLogEntry entry) {
    setState(() {
      _selectedEntry = entry;
      _selectedError = null;
    });
  }

  void _selectError(RashtErrorEntry entry) {
    setState(() {
      _selectedError = entry;
      _selectedEntry = null;
    });
  }

  void _clearSelectedEntry() {
    setState(() {
      _selectedEntry = null;
      _selectedError = null;
    });
  }

  void _setActiveTab(_RashtPanelTab tab) {
    setState(() {
      _activeTab = tab;
      _selectedEntry = null;
      _selectedError = null;
    });
  }

  Future<void> _showExportSheet() async {
    final locale = RashtLocale.resolve(context);
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Export session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18537C),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sensitive values are redacted automatically.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6A7288)),
                ),
                const SizedBox(height: 16),
                _ExportActionTile(
                  icon: Icons.article_outlined,
                  title: 'Copy text report',
                  subtitle: 'Best for Jira, Slack, or email',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await RashtSessionExporter.copy(
                      store: _store,
                      format: RashtReportFormat.text,
                      locale: locale,
                    );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Session report copied')),
                    );
                  },
                ),
                _ExportActionTile(
                  icon: Icons.data_object,
                  title: 'Copy JSON report',
                  subtitle: 'Structured data for developers',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await RashtSessionExporter.copy(
                      store: _store,
                      format: RashtReportFormat.json,
                      locale: locale,
                    );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('JSON report copied')),
                    );
                  },
                ),
                _ExportActionTile(
                  icon: Icons.ios_share,
                  title: 'Share text report',
                  subtitle: 'Opens the system share sheet',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final box = context.findRenderObject() as RenderBox?;
                    await RashtSessionExporter.share(
                      store: _store,
                      format: RashtReportFormat.text,
                      locale: locale,
                      sharePositionOrigin: box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null,
                    );
                  },
                ),
                _ExportActionTile(
                  icon: Icons.html,
                  title: 'Share HTML report',
                  subtitle: 'Readable report file',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final box = context.findRenderObject() as RenderBox?;
                    await RashtSessionExporter.share(
                      store: _store,
                      format: RashtReportFormat.html,
                      locale: locale,
                      sharePositionOrigin: box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _store.entries;
    final errors = _store.errors;
    final showingDetail = _selectedEntry != null || _selectedError != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF18537C),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: showingDetail
            ? IconButton(
                onPressed: _clearSelectedEntry,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(
          showingDetail
              ? _selectedEntry != null
                  ? '${_selectedEntry!.method} ${_selectedEntry!.pathLabel}'
                  : 'Error'
              : 'Rasht',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!showingDetail) ...[
            IconButton(
              onPressed: _store.totalCount == 0 ? null : _showExportSheet,
              icon: const Icon(Icons.ios_share),
              tooltip: 'Export session',
            ),
            TextButton(
              onPressed: _activeTab == _RashtPanelTab.errors
                  ? _store.clearErrors
                  : _store.clear,
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (!showingDetail)
            Container(
              width: double.infinity,
              color: const Color(0xFFF3F7FA),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  _PanelTabButton(
                    label: 'Requests',
                    count: entries.length,
                    selected: _activeTab == _RashtPanelTab.requests,
                    onTap: () => _setActiveTab(_RashtPanelTab.requests),
                  ),
                  const SizedBox(width: 8),
                  _PanelTabButton(
                    label: 'Errors',
                    count: errors.length,
                    selected: _activeTab == _RashtPanelTab.errors,
                    accentColor: const Color(0xFFDC2626),
                    onTap: () => _setActiveTab(_RashtPanelTab.errors),
                  ),
                ],
              ),
            ),
          Expanded(
            child: showingDetail
                ? _selectedEntry != null
                    ? _RashtDetailView(entry: _selectedEntry!)
                    : _RashtErrorDetailView(entry: _selectedError!)
                : _activeTab == _RashtPanelTab.errors
                    ? errors.isEmpty
                        ? const Center(
                            child: Text(
                              'No errors captured yet.\nApp crashes and exceptions appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF6A7288)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: errors.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              return _RashtErrorListTile(
                                entry: errors[index],
                                onTap: () => _selectError(errors[index]),
                              );
                            },
                          )
                    : entries.isEmpty
                        ? const Center(
                            child: Text(
                              'No REST requests yet.\nUse the app to capture API calls.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF6A7288)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: entries.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              return _RashtListTile(
                                entry: entries[index],
                                onTap: () => _selectEntry(entries[index]),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

enum _RashtPanelTab { requests, errors }

class _PanelTabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _PanelTabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.accentColor = const Color(0xFF0087E2),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF18537C)
                        : const Color(0xFF6A7288),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RashtListTile extends StatefulWidget {
  final RashtLogEntry entry;
  final VoidCallback onTap;

  const _RashtListTile({required this.entry, required this.onTap});

  @override
  State<_RashtListTile> createState() => _RashtListTileState();
}

class _RashtListTileState extends State<_RashtListTile> {
  _QuickCopyAction _quickCopied = _QuickCopyAction.none;

  RashtLogEntry get entry => widget.entry;

  Color get _statusColor {
    if (entry.isPending) return const Color(0xFFF59E0B);
    if (entry.isSuccess) return const Color(0xFF16A34A);
    return const Color(0xFFDC2626);
  }

  String get _statusLabel {
    if (entry.isPending) return '...';
    return entry.statusCode?.toString() ?? 'ERR';
  }

  Future<void> _copyCurl() async {
    await Clipboard.setData(ClipboardData(text: entry.toCurl));
    if (!mounted) return;
    setState(() => _quickCopied = _QuickCopyAction.curl);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _quickCopied = _QuickCopyAction.none);
  }

  Future<void> _copyPostman() async {
    await Clipboard.setData(ClipboardData(text: entry.toPostmanCollection));
    if (!mounted) return;
    setState(() => _quickCopied = _QuickCopyAction.postman);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _quickCopied = _QuickCopyAction.none);
  }

  @override
  Widget build(BuildContext context) {
    final duration = entry.duration;

    return ListTile(
      dense: true,
      onTap: widget.onTap,
      leading: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              entry.method,
              style: TextStyle(
                color: _statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      title: Text(
        entry.pathLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF18537C),
        ),
      ),
      subtitle: Text(
        [
          _formatTime(entry.startedAt),
          if (duration != null) '${duration.inMilliseconds}ms',
        ].join(' · '),
        style: const TextStyle(fontSize: 11, color: Color(0xFF6A7288)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _copyCurl,
            icon: Icon(
              _quickCopied == _QuickCopyAction.curl
                  ? Icons.check
                  : Icons.terminal,
              size: 18,
            ),
            color: _quickCopied == _QuickCopyAction.curl
                ? const Color(0xFF16A34A)
                : const Color(0xFF0087E2),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: _copyPostman,
            icon: Icon(
              _quickCopied == _QuickCopyAction.postman
                  ? Icons.check
                  : Icons.cloud_upload_outlined,
              size: 18,
            ),
            color: _quickCopied == _QuickCopyAction.postman
                ? const Color(0xFF16A34A)
                : const Color(0xFF0087E2),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }
}

class _RashtDetailView extends StatefulWidget {
  final RashtLogEntry entry;

  const _RashtDetailView({required this.entry});

  @override
  State<_RashtDetailView> createState() => _RashtDetailViewState();
}

class _RashtDetailViewState extends State<_RashtDetailView> {
  String? _copiedSectionTitle;
  bool _curlCopied = false;
  bool _postmanCopied = false;

  RashtLogEntry get entry => widget.entry;

  List<_DetailSection> get _sections => [
        _DetailSection('cURL', entry.toCurl),
        _DetailSection('Postman collection', entry.toPostmanCollection),
        _DetailSection('URL', entry.url),
        if (entry.queryParameters != null)
          _DetailSection('Query', RashtLogEntry.formatMap(entry.queryParameters)),
        if (entry.requestHeaders != null)
          _DetailSection(
            'Request headers',
            RashtLogEntry.formatMap(entry.requestHeaders),
          ),
        _DetailSection('Request body', RashtLogEntry.formatBody(entry.requestBody)),
        _DetailSection(
          'Response',
          entry.responseBody?.toString() ?? entry.errorMessage ?? '(pending)',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _copyCurl,
              icon: Icon(
                _curlCopied ? Icons.check : Icons.terminal,
                size: 16,
                color: _curlCopied
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF0087E2),
              ),
              label: Text(
                _curlCopied ? 'cURL copied!' : 'Copy cURL',
                style: TextStyle(
                  color: _curlCopied
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF0087E2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _copyPostman,
              icon: Icon(
                _postmanCopied ? Icons.check : Icons.cloud_upload_outlined,
                size: 16,
                color: _postmanCopied
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF0087E2),
              ),
              label: Text(
                _postmanCopied ? 'Postman copied!' : 'Copy for Postman',
                style: TextStyle(
                  color: _postmanCopied
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF0087E2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        for (final section in _sections)
          _CopyableDetailSection(
            title: section.title,
            body: section.body,
            copied: _copiedSectionTitle == section.title,
            onCopy: () => _copySection(section),
          ),
      ],
    );
  }

  Future<void> _copyPostman() async {
    await Clipboard.setData(ClipboardData(text: entry.toPostmanCollection));
    if (!mounted) return;
    setState(() {
      _postmanCopied = true;
      _copiedSectionTitle = 'Postman collection';
      _curlCopied = false;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _postmanCopied = false;
      if (_copiedSectionTitle == 'Postman collection') {
        _copiedSectionTitle = null;
      }
    });
  }

  Future<void> _copyCurl() async {
    await Clipboard.setData(ClipboardData(text: entry.toCurl));
    if (!mounted) return;
    setState(() {
      _curlCopied = true;
      _postmanCopied = false;
      _copiedSectionTitle = 'cURL';
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _curlCopied = false;
      if (_copiedSectionTitle == 'cURL') {
        _copiedSectionTitle = null;
      }
    });
  }

  Future<void> _copySection(_DetailSection section) async {
    await Clipboard.setData(ClipboardData(text: section.body));
    if (!mounted) return;
    setState(() {
      _copiedSectionTitle = section.title;
      _curlCopied = section.title == 'cURL';
      _postmanCopied = section.title == 'Postman collection';
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (_copiedSectionTitle == section.title) {
      setState(() {
        _copiedSectionTitle = null;
        if (section.title == 'cURL') _curlCopied = false;
        if (section.title == 'Postman collection') _postmanCopied = false;
      });
    }
  }
}

class _RashtErrorListTile extends StatelessWidget {
  final RashtErrorEntry entry;
  final VoidCallback onTap;

  const _RashtErrorListTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
          ],
        ),
      ),
      title: Text(
        entry.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF18537C),
        ),
      ),
      subtitle: Text(
        [
          entry.locationLabel,
          _formatTime(entry.occurredAt),
          entry.kindLabel,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: Color(0xFF6A7288)),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }
}

class _RashtErrorDetailView extends StatefulWidget {
  final RashtErrorEntry entry;

  const _RashtErrorDetailView({required this.entry});

  @override
  State<_RashtErrorDetailView> createState() => _RashtErrorDetailViewState();
}

class _RashtErrorDetailViewState extends State<_RashtErrorDetailView> {
  bool _copied = false;

  RashtErrorEntry get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _copyDetails,
              icon: Icon(
                _copied ? Icons.check : Icons.copy,
                size: 16,
                color: _copied
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF0087E2),
              ),
              label: Text(
                _copied ? 'Copied!' : 'Copy details',
                style: TextStyle(
                  color: _copied
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF0087E2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        _CopyableDetailSection(
          title: 'Reason',
          body: entry.message,
          copied: false,
          onCopy: () => _copyText(entry.message),
        ),
        _CopyableDetailSection(
          title: 'File',
          body: entry.file ?? '(unknown)',
          copied: false,
          onCopy: () => _copyText(entry.file ?? ''),
        ),
        _CopyableDetailSection(
          title: 'Line',
          body: entry.line?.toString() ?? '(unknown)',
          copied: false,
          onCopy: () => _copyText(entry.line?.toString() ?? ''),
        ),
        if (entry.stackTrace != null && entry.stackTrace!.isNotEmpty)
          _CopyableDetailSection(
            title: 'Stack trace',
            body: entry.stackTrace!,
            copied: false,
            onCopy: () => _copyText(entry.stackTrace!),
          ),
      ],
    );
  }

  Future<void> _copyDetails() async {
    await Clipboard.setData(ClipboardData(text: entry.detailText));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}

class _CopyableDetailSection extends StatelessWidget {
  final String title;
  final String body;
  final bool copied;
  final VoidCallback onCopy;

  const _CopyableDetailSection({
    required this.title,
    required this.body,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18537C),
                  ),
                ),
              ),
              if (copied)
                const Text(
                  'Copied!',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                const Text(
                  'Tap to copy',
                  style: TextStyle(
                    color: Color(0xFF6A7288),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Material(
            color: copied ? const Color(0xFFE8F5E9) : const Color(0xFFF3F7FA),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFF364152),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF0087E2)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF18537C),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF6A7288), fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

class _DetailSection {
  final String title;
  final String body;

  const _DetailSection(this.title, this.body);
}

enum _QuickCopyAction { none, curl, postman }
