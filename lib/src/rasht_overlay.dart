import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rasht/src/rasht_config.dart';
import 'package:rasht/src/rasht_screen.dart';
import 'package:rasht/src/rasht_store.dart';

/// Floating umbrella FAB that opens [RashtScreen].
class RashtOverlay extends StatefulWidget {
  /// Creates an overlay with a draggable umbrella button.
  const RashtOverlay({
    super.key,
    required this.child,
    this.store,
    this.enabled,
    this.navigatorKey,
  });

  /// Root widget tree wrapped by this overlay.
  final Widget child;

  /// Optional custom store. Defaults to [RashtStore.instance].
  final RashtStore? store;

  /// When null, uses [Rasht.enabled].
  final bool? enabled;

  /// Navigator key used to open [RashtScreen]. Falls back to [Rasht.navigatorKey].
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<RashtOverlay> createState() => _RashtOverlayState();
}

class _RashtOverlayState extends State<RashtOverlay> {
  late final RashtStore _store = widget.store ?? RashtStore.instance;
  Offset _fabOffset = const Offset(16, 120);

  GlobalKey<NavigatorState>? get _navigatorKey =>
      widget.navigatorKey ?? Rasht.navigatorKey;

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

  void _openRashtScreen() {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    navigator.push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => RashtScreen(store: _store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) return widget.child;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        widget.child,
        Positioned(
          right: _fabOffset.dx,
          bottom: _fabOffset.dy,
          child: _RainFab(
            count: _store.totalCount,
            errorCount: _store.errorCount,
            onTap: _openRashtScreen,
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
  final int errorCount;
  final VoidCallback onTap;
  final ValueChanged<DragUpdateDetails> onPanUpdate;

  const _RainFab({
    required this.count,
    required this.errorCount,
    required this.onTap,
    required this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: Material(
        elevation: 6,
        color: const Color(0xFF18537C),
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
                        color: errorCount > 0
                            ? const Color(0xFFDC2626)
                            : Colors.red,
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
