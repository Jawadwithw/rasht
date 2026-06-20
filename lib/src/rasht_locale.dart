import 'package:flutter/widgets.dart';

/// Resolves locale without assuming [BuildContext] has a [Localizations] ancestor.
///
/// [RashtOverlay] is typically placed in [MaterialApp.builder], which sits
/// *above* the localized app subtree — so [Localizations.localeOf] throws there.
abstract final class RashtLocale {
  static Locale? appLocale;

  static String resolve([BuildContext? context]) {
    final fromContext = context != null
        ? Localizations.maybeLocaleOf(context)
        : null;
    final locale = fromContext ?? appLocale ?? _platformLocale;
    return locale.toLanguageTag();
  }

  static Locale get _platformLocale =>
      WidgetsBinding.instance.platformDispatcher.locale;
}
