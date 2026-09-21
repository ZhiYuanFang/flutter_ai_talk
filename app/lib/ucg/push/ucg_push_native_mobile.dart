import 'dart:async';
import 'dart:io' show Platform;

import 'package:china_push/china_push.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/app_debug_log.dart';
import '../../push/push_click_inbox.dart';
import 'ucg_push_channel.dart';

/// 系统通知授权态。
enum OsNotificationAuth {
  /// 已授权（含 limited）。
  granted,

  /// 未授权但仍可弹系统框。
  denied,

  /// 需去系统设置开启。
  permanentlyDenied,

  /// Web 等不支持。
  unsupported,
}

/// iOS：原生 APNs MethodChannel；Android：仅经 `china_push` 取 token。
class UcgPushNative {
  static const _iosChannel = MethodChannel('com.fzy.pangbao/ucg_push');
  static const _clickChannel = MethodChannel('com.fzy.pangbao/push_click');

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

  /// 首帧前绑定点击。Android 冷启动从 MainActivity 拉取暂存的 bizType。
  static Future<void> bindNotificationTaps() async {
    if (kIsWeb) return;
    if (Platform.isIOS) {
      _bindIosTokenHandler();
      try {
        // 先声明可收，再拉 pending，避免 channel 已有但 handler 未绑时丢点击。
        await _iosChannel.invokeMethod<void>('readyForNotificationTaps');
      } catch (e) {
        PushClickDiagnostics.reportFailure('推送点击: ready 失败 $e');
      }
      try {
        final initial =
            await _iosChannel.invokeMethod<dynamic>('getInitialNotificationTap');
        // null = 普通启动无点击，不 Toast。
        PushClickInbox.instance.ingestInitial(initial);
      } catch (e) {
        PushClickDiagnostics.reportFailure('推送点击: getInitial 失败 $e');
      }
      // Scene 冷启可能略晚于首次 getInitial：再补拉一次。
      Future<void>.delayed(const Duration(milliseconds: 800), () async {
        try {
          final again = await _iosChannel
              .invokeMethod<dynamic>('getInitialNotificationTap');
          PushClickInbox.instance.ingestInitial(again);
        } catch (e) {
          PushClickDiagnostics.reportFailure('推送点击: 补拉失败 $e');
        }
      });
      return;
    }
    if (!Platform.isAndroid) return;
    ChinaPush.setOnClickNotification(PushClickInbox.instance.recordRaw);
    _clickChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPushClick') {
        PushClickInbox.instance.recordRaw(<String, dynamic>{
          'bizType': call.arguments?.toString(),
        });
      }
    });
    try {
      final initial = await _clickChannel.invokeMethod<String>('getInitialPushClick');
      if (initial != null && initial.trim().isNotEmpty) {
        PushClickInbox.instance.recordRaw(<String, dynamic>{'bizType': initial});
      }
    } catch (e) {
      AppDebugLog.ucgPush('android getInitialPushClick err=$e');
    }
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
        return;
      }
      // 前台/后台点击；冷启动另由 getInitialNotificationTap 拉取。
      if (call.method == 'onNotificationTap') {
        try {
          PushClickInbox.instance.ingestConfirmedTap(call.arguments);
        } catch (e) {
          PushClickDiagnostics.reportFailure('推送点击: channel 异常 $e');
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

  /// 系统通知授权态（只读）。
  static Future<OsNotificationAuth> notificationAuthStatus() async {
    if (kIsWeb) return OsNotificationAuth.unsupported;
    if (Platform.isIOS) {
      _bindIosTokenHandler();
      try {
        final raw =
            await _iosChannel.invokeMethod<String>('notificationStatus');
        switch ((raw ?? '').trim()) {
          case 'granted':
            return OsNotificationAuth.granted;
          case 'notDetermined':
            return OsNotificationAuth.denied;
          case 'denied':
            // iOS 已拒绝须去系统设置。
            return OsNotificationAuth.permanentlyDenied;
          default:
            return OsNotificationAuth.denied;
        }
      } catch (e) {
        AppDebugLog.ucgPush('ios notificationStatus err=$e');
        return OsNotificationAuth.denied;
      }
    }
    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        if (status.isGranted || status.isLimited) {
          return OsNotificationAuth.granted;
        }
        if (status.isPermanentlyDenied) {
          return OsNotificationAuth.permanentlyDenied;
        }
        return OsNotificationAuth.denied;
      } catch (e) {
        AppDebugLog.ucgPush('android notification status err=$e');
        return OsNotificationAuth.denied;
      }
    }
    return OsNotificationAuth.unsupported;
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
