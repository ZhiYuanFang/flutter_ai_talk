import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/app_debug_log.dart';

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
    if (!text.startsWith('{') && !text.startsWith('[')) {
      return const PushBizParse(found: false);
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

/// 最新一次通知点击。后一次覆盖前一次，不排队。
class PushClickInbox extends ChangeNotifier {
  PushClickInbox._();

  static final instance = PushClickInbox._();

  int _seq = 0;
  String? _bizType;

  int get seq => _seq;
  String? get bizType => _bizType;

  void recordRaw(dynamic raw) {
    final parsed = parsePushBizType(raw);
    if (!parsed.found) return;
    _seq += 1;
    _bizType = parsed.bizType;
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
