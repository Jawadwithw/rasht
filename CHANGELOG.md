## 0.4.2

* Require `dio` ^5.8.0 so lower-bound resolution includes `DioException` (pub score).
* Use latest `device_info_plus`, `package_info_plus`, and `share_plus` versions
  compatible with `win32` 5.x (fixes conflicts with `file_picker` ^11).

## 0.4.1

* Bump `device_info_plus`, `package_info_plus`, and `share_plus` to latest versions for pub.dev dependency score.

## 0.4.0

* Open Rasht as a full-screen inspector instead of an overlay panel.
* Export bottom sheet now opens above dialogs and modals.
* Umbrella FAB only — tap to navigate to [RashtScreen].

## 0.3.2

* Fix app freeze when opening Rasht from `MaterialApp.builder`.
* Render panel via navigator overlay with safe view insets.
* Deduplicate rapid error captures to prevent rebuild loops.

## 0.3.1

* Fix `Localizations` lookup crash when overlay sits above the app subtree.
* Add `Rasht.navigatorKey` and `appRunner` parameter rename in `Rasht.initialize`.

## 0.3.0

* Session export: copy/share text, JSON, and HTML reports.
* Auto-redact tokens, passwords, and sensitive headers before export.
* Include app version, device, OS, and locale in every report.
* Optional `Rasht.sessionExtras` for tester metadata.

## 0.2.0

* Capture Flutter, Dart, and zone errors with file and line.
* Requests and Errors tabs in the inspector.
* `Rasht.initialize()` for one-call error handler setup.

## 0.1.0

* Dio interceptor with draggable umbrella FAB.
* Request list, detail view, cURL and Postman export.
