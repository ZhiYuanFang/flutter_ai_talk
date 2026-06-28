import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/device_no_notifier.dart';
import '../providers/session_provider.dart';

typedef WsReconnectFn = Future<void> Function({bool resetStrike});

/// refresh 单飞结束或 deviceNo 变化时触发 WS reconnect（token 轮换仍由各 provider 现有 listener 处理）。
void bindAuthenticatedWsSession(
  Ref ref, {
  required WsReconnectFn reconnect,
  bool watchDeviceNo = false,
  bool Function()? shouldReconnect,
}) {
  ref.listen<bool>(sessionProvider.select((s) => s.isRefreshInFlight), (prev, inFlight) {
    if (prev != true || inFlight) return;
    if (shouldReconnect != null && !shouldReconnect()) return;
    if (!ref.read(sessionProvider).isLoggedIn) return;
    unawaited(reconnect(resetStrike: false));
  });
  if (watchDeviceNo) {
    ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, (_, __) {
      if (shouldReconnect != null && !shouldReconnect()) return;
      unawaited(reconnect(resetStrike: true));
    });
  }
}
