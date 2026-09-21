import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';
import '../scaffold_messenger_key.dart';
import '../ui/widgets/app_toast.dart';

/// 可见通知里会路由的业务类型。
const kPushBizUcgAlert = 'ucg_alert';
const kPushBizPredictImminent = 'predict_imminent';
const kPushBizUcgSilentBadge = 'ucg_silent_badge';

/// 从厂商点击载荷里抽出 `bizType`。没有该键时 [found] 为 false，避免普通启动 extras 冲掉真点击。
class PushBizParse {
  const PushBizParse({required this.found, this.bizType});

  final bool found;
  final String? bizType;
}

PushBizParse parsePushBizType(dynamic data, {int depth = 0}) {
  if (data == null || depth > 4) {
    return const PushBizParse(found: false);
  }
  if (data is String) {
    final text = data.trim();
    if (text.isEmpty) {
      return const PushBizParse(found: false);
    }
    // 纯 bizType 字符串（iOS 对齐 Android getInitial）。
    if (!text.startsWith('{') && !text.startsWith('[')) {
      return PushBizParse(found: true, bizType: text.toLowerCase());
    }
    try {
      return parsePushBizType(jsonDecode(text), depth: depth + 1);
    } catch (e) {
      AppDebugLog.ucgPush('notification tap json err=$e');
      return const PushBizParse(found: false);
    }
  }
  if (data is Map) {
    for (final entry in data.entries) {
      if (entry.key.toString() != 'bizType') continue;
      final value = entry.value?.toString().trim().toLowerCase() ?? '';
      return PushBizParse(found: true, bizType: value.isEmpty ? null : value);
    }
    for (final value in data.values) {
      if (value is String || value is Map) {
        final nested = parsePushBizType(value, depth: depth + 1);
        if (nested.found) return nested;
      }
    }
  }
  return const PushBizParse(found: false);
}

/// 推送点击失败诊断：Release 也 Toast；首帧前排队。
class PushClickDiagnostics {
  PushClickDiagnostics._();

  static final List<String> _queued = <String>[];
  static String? _lastMsg;
  static DateTime? _lastAt;

  /// 失败上报（正式包也弹）。
  static void reportFailure(String message, {bool toast = true}) {
    final text = message.trim();
    if (text.isEmpty) return;
    AppDebugLog.ucgPush(text);
    if (!toast) return;
    if (appScaffoldMessengerKey.currentState != null) {
      _showDeduped(text);
    } else {
      _queued.add(text);
    }
  }

  /// 首帧后冲刷 runApp 前排队的失败 Toast。
  static void flushPendingToasts() {
    if (_queued.isEmpty) return;
    final copy = List<String>.from(_queued);
    _queued.clear();
    for (final msg in copy) {
      _showDeduped(msg);
    }
  }

  static void _showDeduped(String message) {
    final now = DateTime.now();
    if (_lastMsg == message &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastMsg = message;
    _lastAt = now;
    showAppToast(message, tone: AppToastTone.error);
  }
}

/// 最新一次通知点击。后一次覆盖前一次，不排队。
class PushClickInbox extends ChangeNotifier {
  PushClickInbox._();

  static final instance = PushClickInbox._();

  int _seq = 0;
  String? _bizType;

  int get seq => _seq;
  String? get bizType => _bizType;

  /// Android / 已归一化成功路径：无 bizType 键时静默忽略。
  void recordRaw(dynamic raw) {
    final parsed = parsePushBizType(raw);
    if (!parsed.found) return;
    _commit(parsed.bizType);
  }

  /// iOS 热点击或已确认的点击回调：解析失败则 Toast（Release 也弹）。
  void ingestConfirmedTap(dynamic raw) {
    if (raw is Map && raw['__confirmedPushTap'] == true) {
      PushClickDiagnostics.reportFailure('推送点击: 无 bizType');
      return;
    }
    if (raw == null) {
      PushClickDiagnostics.reportFailure('推送点击: 空载荷');
      return;
    }
    final parsed = parsePushBizType(raw);
    if (!parsed.found) {
      PushClickDiagnostics.reportFailure('推送点击: 无 bizType');
      return;
    }
    _commit(parsed.bizType);
  }

  /// iOS getInitial：null 表示无点击（不 Toast）；非 null 按确认点击处理。
  void ingestInitial(dynamic raw) {
    if (raw == null) return;
    ingestConfirmedTap(raw);
  }

  void _commit(String? bizType) {
    _seq += 1;
    _bizType = bizType;
    AppDebugLog.ucgPush('notification tap bizType=${_bizType ?? ''} seq=$_seq');
    notifyListeners();
  }
}

final pushClickInboxProvider =
    ChangeNotifierProvider<PushClickInbox>((ref) => PushClickInbox.instance);

/// 冷启动 restore 结束后才允许按登录态分流，避免深链提前进主页时把已登录判成未登录。
final pushClickRoutingReadyProvider = StateProvider<bool>((ref) => false);

/// 请求 UCG 壳在挂载后走消息 Tab。null 表示没有待处理请求。
final ucgMessagesTabRequestProvider =
    NotifierProvider<UcgMessagesTabRequestNotifier, int?>(
  UcgMessagesTabRequestNotifier.new,
);

class UcgMessagesTabRequestNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void request() {
    state = (state ?? 0) + 1;
  }

  void clear() {
    state = null;
  }
}
