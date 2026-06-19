import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rasht/src/rasht_config.dart';
import 'package:rasht/src/rasht_log_entry.dart';
import 'package:rasht/src/rasht_store.dart';

/// Draggable umbrella FAB and panel for inspecting captured API requests.
///
/// Wrap your app content in [MaterialApp.builder]:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     return RashtOverlay(child: child ?? const SizedBox.shrink());
///   },
/// );
/// ```
///
/// Hidden when [enabled] (or [Rasht.enabled]) is false.
class RashtOverlay extends StatefulWidget {
  /// Creates the overlay around [child].
  ///
  /// Pass [store] to use a custom [RashtStore], or omit for [RashtStore.instance].
  /// When [enabled] is null, [Rasht.enabled] is used.
  const RashtOverlay({
    super.key,
    required this.child,
    this.store,
    this.enabled,
  });

  /// App content rendered beneath the Rasht FAB and panel.
  final Widget child;

  /// Log store to display. Defaults to [RashtStore.instance].
  final RashtStore? store;

  /// Overrides [Rasht.enabled] for this overlay only.
  final bool? enabled;

  @override
  State<RashtOverlay> createState() => _RashtOverlayState();
}

class _RashtOverlayState extends State<RashtOverlay> {
  late final RashtStore _store = widget.store ?? RashtStore.instance;
  bool _panelOpen = false;
  RashtLogEntry? _selectedEntry;
  Offset _fabOffset = const Offset(16, 120);

  bool get _isActive => widget.enabled ?? Rasht.enabled;

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

  void _togglePanel() {
    setState(() {
      _panelOpen = !_panelOpen;
      if (!_panelOpen) {
        _selectedEntry = null;
      }
    });
  }

  void _selectEntry(RashtLogEntry entry) {
    setState(() => _selectedEntry = entry);
  }

  void _clearSelectedEntry() {
    setState(() => _selectedEntry = null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) return widget.child;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        widget.child,
        if (_panelOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePanel,
              child: Container(color: Colors.black26),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            top: MediaQuery.paddingOf(context).top + 72,
            child: _RashtPanel(
              store: _store,
              selectedEntry: _selectedEntry,
              onClose: _togglePanel,
              onEntrySelected: _selectEntry,
              onBackFromDetail: _clearSelectedEntry,
            ),
          ),
        ],
        Positioned(
          right: _fabOffset.dx,
          bottom: _fabOffset.dy,
          child: _RainFab(
            count: _store.count,
            isOpen: _panelOpen,
            onTap: _togglePanel,
            onPanUpdate: (details) {
              setState(() {
                _fabOffset = Offset(
                  (_fabOffset.dx - details.delta.dx).clamp(8.0, 120.0),
                  (_fabOffset.dy - details.delta.dy).clamp(80.0, 320.0),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class _RainFab extends StatelessWidget {
  final int count;
  final bool isOpen;
  final VoidCallback onTap;
  final ValueChanged<DragUpdateDetails> onPanUpdate;

  const _RainFab({
    required this.count,
    required this.isOpen,
    required this.onTap,
    required this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: Material(
        elevation: 6,
        color: isOpen ? const Color(0xFF0087E2) : const Color(0xFF18537C),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.umbrella,
                  color: Colors.white,
                  size: 22,
                ),
                if (count > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RashtPanel extends StatelessWidget {
  final RashtStore store;
  final RashtLogEntry? selectedEntry;
  final VoidCallback onClose;
  final ValueChanged<RashtLogEntry> onEntrySelected;
  final VoidCallback onBackFromDetail;

  const _RashtPanel({
    required this.store,
    required this.selectedEntry,
    required this.onClose,
    required this.onEntrySelected,
    required this.onBackFromDetail,
  });

  @override
  Widget build(BuildContext context) {
    final entries = store.entries;
    final showingDetail = selectedEntry != null;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            color: const Color(0xFF18537C),
            child: Row(
              children: [
                if (showingDetail)
                  IconButton(
                    onPressed: onBackFromDetail,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: FaIcon(
                      FontAwesomeIcons.umbrella,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    showingDetail
                        ? '${selectedEntry!.method} ${selectedEntry!.pathLabel}'
                        : 'Rasht',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!showingDetail)
                  TextButton(
                    onPressed: store.clear,
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: showingDetail
                ? _RashtDetailView(entry: selectedEntry!)
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
                            onTap: () => onEntrySelected(entries[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _RashtListTile extends StatefulWidget {
  final RashtLogEntry entry;
  final VoidCallback onTap;

  const _RashtListTile({
    required this.entry,
    required this.onTap,
  });

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

class _DetailSection {
  final String title;
  final String body;

  const _DetailSection(this.title, this.body);
}

enum _QuickCopyAction { none, curl, postman }
