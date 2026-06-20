import 'package:flutter/widgets.dart';

/// Safe view metrics for widgets placed in [MaterialApp.builder], which sits
/// above the [MediaQuery] subtree.
abstract final class RashtViewInsets {
  static double topPadding([BuildContext? context]) {
    final fromContext = context != null
        ? MediaQuery.maybeOf(context)?.padding.top
        : null;
    if (fromContext != null) return fromContext;

    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 0;
    return MediaQueryData.fromView(views.first).padding.top;
  }
}
