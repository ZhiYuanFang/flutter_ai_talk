import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ucg_push_channel.dart';

/// iOS APNs / Huawei HMS / Xiaomi MiPush via platform channel (no FCM).
class UcgPushNative {
  static const _channel = MethodChannel('com.fzy.pangbao/ucg_push');

  static final _tokenRefreshController = StreamController<UcgPushTokenEvent>.broadcast();
  static var _handlerBound = false;

  static Stream<UcgPushTokenEvent> get tokenRefreshStream {
    _bindTokenHandler();
    return _tokenRefreshController.stream;
  }

  static void _bindTokenHandler() {
    if (_handlerBound) return;
    _handlerBound = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTokenRefresh') {
        final args = call.arguments;
        if (args is Map) {
          final ch = UcgPushChannel.tryParse(args['channel']?.toString());
          final token = args['token']?.toString().trim() ?? '';
          if (ch != null && token.isNotEmpty) {
            _tokenRefreshController.add(UcgPushTokenEvent(channel: ch, token: token));
          }
        }
      }
    });
  }

  static Future<UcgPushChannel?> detectChannel() async {
    if (kIsWeb) return null;
    if (Platform.isIOS) return UcgPushChannel.apns;
    if (!Platform.isAndroid) return null;
    try {
      final android = await DeviceInfoPlugin().androidInfo;
      final m = android.manufacturer.toLowerCase();
      final brand = android.brand.toLowerCase();
      if (m.contains('huawei') || m.contains('honor') || brand.contains('huawei') || brand.contains('honor')) {
        return UcgPushChannel.hms;
      }
      if (m.contains('xiaomi') || m.contains('redmi') || brand.contains('xiaomi') || brand.contains('redmi')) {
        return UcgPushChannel.mipush;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    _bindTokenHandler();
    try {
      final ok = await _channel.invokeMethod<bool>('requestPermission');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> fetchToken(UcgPushChannel channel) async {
    if (kIsWeb) return null;
    _bindTokenHandler();
    try {
      final token = await _channel.invokeMethod<String>('getToken', {
        'channel': channel.apiValue,
      });
      final normalized = token?.trim();
      if (normalized == null || normalized.isEmpty) return null;
      return normalized;
    } catch (_) {
      return null;
    }
  }
}
