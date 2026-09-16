import 'dart:async';
import 'dart:io' show Platform;

import 'package:china_push/china_push.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/app_debug_log.dart';
import 'ucg_push_channel.dart';

/// iOS：原生 APNs MethodChannel；Android：仅经 `china_push` 取 token。
class UcgPushNative {
  static const _iosChannel = MethodChannel('com.fzy.pangbao/ucg_push');

  static final _tokenRefreshController =
      StreamController<UcgPushTokenEvent>.broadcast();
  static var _iosHandlerBound = false;

  /// Android china_push 初始化缓存（regId + manufacturer）。
  static String? _androidRegId;
  static String? _androidManufacturer;
  static Future<bool>? _androidInitInFlight;
  static var _androidInitFailed = false;

  static Stream<UcgPushTokenEvent> get tokenRefreshStream {
    if (!kIsWeb && Platform.isIOS) {
      _bindIosTokenHandler();
    }
    return _tokenRefreshController.stream;
  }

  static void _bindIosTokenHandler() {
    if (_iosHandlerBound) return;
    _iosHandlerBound = true;
    _iosChannel.setMethodCallHandler((call) async {
      if (call.method == 'onTokenRefresh') {
        final args = call.arguments;
        if (args is Map) {
          final ch = UcgPushChannel.tryParse(args['channel']?.toString());
          final token = args['token']?.toString().trim() ?? '';
          if (ch != null && token.isNotEmpty) {
            _tokenRefreshController.add(
              UcgPushTokenEvent(channel: ch, token: token),
            );
          }
        }
      }
    });
  }

  /// 将 china_push manufacturer 映射为 Go 一期支持的 channel；无法映射返回 null。
  static UcgPushChannel? mapManufacturerToChannel(String? manufacturer) {
    final m = manufacturer?.trim().toLowerCase() ?? '';
    if (m.isEmpty) return null;
    // china_push 返回值：HMS / MI / HONOR / OPPO / VIVO
    if (m == 'hms' || m.contains('huawei')) return UcgPushChannel.hms;
    if (m == 'mi' || m.contains('xiaomi') || m.contains('redmi')) {
      return UcgPushChannel.mipush;
    }
    // 一期 Go 无 honor/oppo/vivo Sender → 跳过注册
    return null;
  }

  /// 确保 Android china_push 已 init；失败可接受。
  static Future<bool> ensureAndroidChinaPushInit() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (_androidRegId != null &&
        _androidRegId!.isNotEmpty &&
        _androidManufacturer != null) {
      return true;
    }
    if (_androidInitFailed) return false;
    if (_androidInitInFlight != null) return _androidInitInFlight!;

    final run = () async {
      try {
        ChinaPush.enableLog(kDebugMode);
        final value = await ChinaPush.initPush();
        String? regId;
        String? manufacturer;
        if (value is Map) {
          regId = value['regId']?.toString().trim();
          manufacturer = value['manufacturer']?.toString().trim();
        }
        regId ??= (await ChinaPush.getRegId())?.trim();
        manufacturer ??= (await ChinaPush.getManufacturer())?.trim();
        if (regId == null || regId.isEmpty) {
          AppDebugLog.ucgPush(
            'china_push init ok but empty regId manufacturer=$manufacturer',
          );
          _androidInitFailed = true;
          return false;
        }
        _androidRegId = regId;
        _androidManufacturer = manufacturer ?? '';
        AppDebugLog.ucgPush(
          'china_push init ok manufacturer=$_androidManufacturer',
        );
        final ch = mapManufacturerToChannel(_androidManufacturer);
        if (ch != null) {
          _tokenRefreshController.add(
            UcgPushTokenEvent(channel: ch, token: regId),
          );
        }
        return true;
      } catch (e) {
        AppDebugLog.ucgPush('china_push init err=$e');
        _androidInitFailed = true;
        return false;
      } finally {
        _androidInitInFlight = null;
      }
    }();

    _androidInitInFlight = run;
    return run;
  }

  static Future<UcgPushChannel?> detectChannel() async {
    if (kIsWeb) return null;
    if (Platform.isIOS) return UcgPushChannel.apns;
    if (!Platform.isAndroid) return null;
    final ok = await ensureAndroidChinaPushInit();
    if (!ok) return null;
    final ch = mapManufacturerToChannel(_androidManufacturer);
    if (ch == null) {
      AppDebugLog.ucgPush(
        'china_push skip unsupported manufacturer=$_androidManufacturer',
      );
    }
    return ch;
  }

  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      _bindIosTokenHandler();
      try {
        final ok = await _iosChannel.invokeMethod<bool>('requestPermission');
        return ok ?? false;
      } catch (e) {
        AppDebugLog.ucgPush('ios requestPermission err=$e');
        return false;
      }
    }
    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.request();
        return status.isGranted || status.isLimited;
      } catch (e) {
        AppDebugLog.ucgPush('android notification permission err=$e');
        return false;
      }
    }
    return false;
  }

  static Future<String?> fetchToken(UcgPushChannel channel) async {
    if (kIsWeb) return null;
    if (Platform.isIOS) {
      _bindIosTokenHandler();
      try {
        final token = await _iosChannel.invokeMethod<String>('getToken', {
          'channel': channel.apiValue,
        });
        final normalized = token?.trim();
        if (normalized == null || normalized.isEmpty) return null;
        return normalized;
      } catch (e) {
        AppDebugLog.ucgPush('ios getToken err=$e');
        return null;
      }
    }
    if (Platform.isAndroid) {
      final ok = await ensureAndroidChinaPushInit();
      if (!ok) return null;
      final mapped = mapManufacturerToChannel(_androidManufacturer);
      if (mapped != channel) {
        AppDebugLog.ucgPush(
          'fetchToken channel mismatch want=${channel.apiValue} got=${mapped?.apiValue}',
        );
        return null;
      }
      final token = _androidRegId?.trim();
      if (token == null || token.isEmpty) return null;
      return token;
    }
    return null;
  }
}
