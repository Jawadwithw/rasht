import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rasht/src/rasht_config.dart';

/// Device and app metadata attached to exported session reports.
class RashtSessionMetadata {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String locale;
  final Map<String, String> extras;

  const RashtSessionMetadata({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.locale,
    this.extras = const {},
  });

  /// Collects app and device metadata for session reports.
  static Future<RashtSessionMetadata> collect({
    String? locale,
    Map<String, String>? extras,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final mergedExtras = {
      ...Rasht.sessionExtras,
      if (extras != null) ...extras,
    };

    if (kIsWeb) {
      final web = await deviceInfo.webBrowserInfo;
      return RashtSessionMetadata(
        appName: packageInfo.appName,
        packageName: packageInfo.packageName,
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        platform: 'web',
        osVersion: web.userAgent ?? 'unknown',
        deviceModel: web.browserName.name,
        locale: locale ?? 'unknown',
        extras: mergedExtras,
      );
    }

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return RashtSessionMetadata(
        appName: packageInfo.appName,
        packageName: packageInfo.packageName,
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        platform: 'android',
        osVersion: 'Android ${android.version.release} (SDK ${android.version.sdkInt})',
        deviceModel: '${android.manufacturer} ${android.model}',
        locale: locale ?? 'unknown',
        extras: mergedExtras,
      );
    }

    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return RashtSessionMetadata(
        appName: packageInfo.appName,
        packageName: packageInfo.packageName,
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        platform: 'ios',
        osVersion: '${ios.systemName} ${ios.systemVersion}',
        deviceModel: ios.utsname.machine,
        locale: locale ?? 'unknown',
        extras: mergedExtras,
      );
    }

    if (Platform.isMacOS) {
      final mac = await deviceInfo.macOsInfo;
      return RashtSessionMetadata(
        appName: packageInfo.appName,
        packageName: packageInfo.packageName,
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        platform: 'macos',
        osVersion: '${mac.osRelease} (${mac.kernelVersion})',
        deviceModel: mac.model,
        locale: locale ?? 'unknown',
        extras: mergedExtras,
      );
    }

    return RashtSessionMetadata(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      platform: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      deviceModel: 'unknown',
      locale: locale ?? 'unknown',
      extras: mergedExtras,
    );
  }

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'packageName': packageName,
        'version': version,
        'buildNumber': buildNumber,
        'platform': platform,
        'osVersion': osVersion,
        'deviceModel': deviceModel,
        'locale': locale,
        if (extras.isNotEmpty) 'extras': extras,
      };
}
