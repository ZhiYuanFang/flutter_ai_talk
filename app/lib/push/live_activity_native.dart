import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import '../api/app_debug_log.dart';

/// iOS Live Activity MethodChannel（Push-to-Start / activity token）。
/// Web / 非 iOS 为空操作。
class LiveActivityNative {
  LiveActivityNative._();

  static const _channel = MethodChannel('com.fzy.pangbao/live_activity');
  static StreamController<LiveActivityTokenEvent>? _controller;
  static var _listening = false;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// 原生推送 token 事件流。
  static Stream<LiveActivityTokenEvent> get tokenStream {
    _ensureHandler();
    return _controller!.stream;
  }

  /// 通知原生：确保观察 + Dart 可收 + flush inbox。
  static Future<void> startListening() async {
    if (!_supported) return;
    _ensureHandler();
    try {
      await _channel.invokeMethod<void>('startListening');
      AppDebugLog.liveActivity('startListening ok');
    } catch (e) {
      AppDebugLog.liveActivity('startListening err=$e');
    }
  }

  /// 强制重启原生观察（手动重试用）。
  static Future<void> restartListening() async {
    if (!_supported) return;
    _ensureHandler();
    try {
      await _channel.invokeMethod<void>('restartListening');
      AppDebugLog.liveActivity('restartListening ok');
    } catch (e) {
      AppDebugLog.liveActivity('restartListening err=$e');
    }
  }

  /// 登出 / stop：暂停 Native→Dart 投递。
  static Future<void> pauseDartListening() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('pauseDartListening');
      AppDebugLog.liveActivity('pauseDartListening ok');
    } catch (e) {
      AppDebugLog.liveActivity('pauseDartListening err=$e');
    }
  }

  /// 登录后写入原生可读 register 上下文。
  static Future<void> setRegisterContext({
    required int wxId,
    required String deviceKey,
    required String apiBaseUrl,
  }) async {
    if (!_supported) return;
    if (wxId <= 0) return;
    final dk = deviceKey.trim();
    final base = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (dk.isEmpty || base.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('setRegisterContext', {
        'wxId': wxId,
        'deviceKey': dk,
        'apiBaseUrl': base,
      });
      AppDebugLog.liveActivity(
        'setRegisterContext ok wxId=$wxId deviceKeyLen=${dk.length}',
      );
    } catch (e) {
      AppDebugLog.liveActivity('setRegisterContext err=$e');
    }
  }

  /// 登出：清除原生上下文。
  static Future<void> clearRegisterContext() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('clearRegisterContext');
      AppDebugLog.liveActivity('clearRegisterContext ok');
    } catch (e) {
      AppDebugLog.liveActivity('clearRegisterContext err=$e');
    }
  }

  /// 本机是否仍有可展示的统一 `BabyLiveActivityAttributes` Live Activity。
  /// 非 iOS 返回 `false`；查询失败返回 `null`（调用方不得据此 clear）。
  static Future<bool?> hasActiveUnifiedLiveActivity() async {
    if (!_supported) return false;
    try {
      final raw =
          await _channel.invokeMethod<dynamic>('hasActiveUnifiedLiveActivity');
      return raw == true;
    } catch (e) {
      AppDebugLog.liveActivity('hasActiveUnifiedLiveActivity err=$e');
      return null;
    }
  }

  /// 探测系统是否允许 Live Activities / Push-to-Start / deliver 计数。
  static Future<LiveActivitySystemInfo> getSystemStatus() async {
    if (!_supported) {
      return const LiveActivitySystemInfo(
        supported: false,
        areActivitiesEnabled: false,
        pushToStartSupported: false,
        pushToStartDeliverCount: 0,
        iosVersion: '',
      );
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>('getSystemStatus');
      if (raw is! Map) {
        return const LiveActivitySystemInfo(
          supported: true,
          areActivitiesEnabled: false,
          pushToStartSupported: false,
          pushToStartDeliverCount: 0,
          iosVersion: '',
        );
      }
      final map = Map<String, dynamic>.from(raw);
      final deliverRaw = map['pushToStartDeliverCount'];
      final deliver = deliverRaw is int
          ? deliverRaw
          : int.tryParse('$deliverRaw') ?? 0;
      return LiveActivitySystemInfo(
        supported: true,
        areActivitiesEnabled: map['areActivitiesEnabled'] == true,
        pushToStartSupported: map['pushToStartSupported'] == true,
        pushToStartDeliverCount: deliver < 0 ? 0 : deliver,
        iosVersion: map['iosVersion']?.toString().trim() ?? '',
      );
    } catch (e) {
      AppDebugLog.liveActivity('getSystemStatus err=$e');
      return const LiveActivitySystemInfo(
        supported: true,
        areActivitiesEnabled: false,
        pushToStartSupported: false,
        pushToStartDeliverCount: 0,
        iosVersion: '',
      );
    }
  }

  static void _ensureHandler() {
    if (_listening) return;
    _listening = true;
    _controller = StreamController<LiveActivityTokenEvent>.broadcast();
    if (!_supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onLiveActivityToken') return;
      final raw = call.arguments;
      if (raw is! Map) return;
      final map = Map<String, dynamic>.from(raw);
      final token = map['token']?.toString().trim() ?? '';
      final tokenKind = map['tokenKind']?.toString().trim() ?? '';
      // 统一轨：不再要求 attributesKind
      if (token.isEmpty || tokenKind.isEmpty) return;
      _controller!.add(
        LiveActivityTokenEvent(
          tokenKind: tokenKind,
          token: token,
        ),
      );
    });
  }
}

/// 原生系统能力探测结果。
class LiveActivitySystemInfo {
  const LiveActivitySystemInfo({
    required this.supported,
    required this.areActivitiesEnabled,
    required this.pushToStartSupported,
    this.pushToStartDeliverCount = 0,
    this.iosVersion = '',
  });

  final bool supported;
  final bool areActivitiesEnabled;
  final bool pushToStartSupported;
  final int pushToStartDeliverCount;
  final String iosVersion;
}

/// 单次 LA token 上报载荷（统一轨，无 attributesKind/activityId）。
class LiveActivityTokenEvent {
  const LiveActivityTokenEvent({
    required this.tokenKind,
    required this.token,
  });

  final String tokenKind;
  final String token;
}
