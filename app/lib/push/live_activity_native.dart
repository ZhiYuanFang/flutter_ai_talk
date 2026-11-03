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

  /// 通知原生开始监听 ActivityKit token（禁止本地 Activity.request）。
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
