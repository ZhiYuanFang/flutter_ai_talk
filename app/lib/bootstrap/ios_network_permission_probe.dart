import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

const _kProbeAttemptedKey = 'ios_network_probe_attempted';

/// 国行 iOS：首次冷启动旁路 GET，触发系统「无线局域网与蜂窝网络」授权弹窗。
class IosNetworkPermissionProbe {
  IosNetworkPermissionProbe._();

  static Future<void> run() async {
    if (kIsWeb || !Platform.isIOS) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kProbeAttemptedKey) == true) return;
    await prefs.setBool(_kProbeAttemptedKey, true);
    unawaited(_fire());
  }

  static Future<void> _fire() async {
    try {
      final base = AppEnv.apiBaseUrl.endsWith('/')
          ? AppEnv.apiBaseUrl.substring(0, AppEnv.apiBaseUrl.length - 1)
          : AppEnv.apiBaseUrl;
      final uri = Uri.parse('$base/device/app/api/version/check').replace(
        queryParameters: const {'currentVersion': '0.0.0'},
      );
      await http.get(uri).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}
