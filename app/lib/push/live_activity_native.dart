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

  /// 通知原生：确保观察 + Dart 可收 + flush inbox（禁止本地 Activity.request）。
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

  /// 强制重启原生 Push-to-Start / activity 观察（手动重试用）。
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

  /// 登出 / stop：暂停 Native→Dart 投递；原生观察与 inbox 继续。
  static Future<void> pauseDartListening() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('pauseDartListening');
      AppDebugLog.liveActivity('pauseDartListening ok');
    } catch (e) {
      AppDebugLog.liveActivity('pauseDartListening err=$e');
    }
  }

  /// 探测系统是否允许 Live Activities / 是否支持 Push-to-Start / PTS deliver 计数。
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
      final attributesKind = map['attributesKind']?.toString().trim() ?? '';
      if (token.isEmpty || tokenKind.isEmpty || attributesKind.isEmpty) return;
      final activityId = map['activityId']?.toString().trim();
      _controller!.add(
        LiveActivityTokenEvent(
          tokenKind: tokenKind,
          attributesKind: attributesKind,
          token: token,
          activityId: (activityId == null || activityId.isEmpty)
              ? null
              : activityId,
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
  /// Bridge 本进程已 deliver 的 push_to_start 次数。
  final int pushToStartDeliverCount;
  /// 如 `18.2`。
  final String iosVersion;
}

/// 单次 LA token 上报载荷。
class LiveActivityTokenEvent {
  const LiveActivityTokenEvent({
    required this.tokenKind,
    required this.attributesKind,
    required this.token,
    this.activityId,
  });

  final String tokenKind;
  final String attributesKind;
  final String token;
  final String? activityId;
}
