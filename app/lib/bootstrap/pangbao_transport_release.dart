import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/clinic_ws_provider.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/repositories.dart';
import '../providers/voice_asr_ws_provider.dart';
import '../ucg/providers/ucg_providers.dart';
import 'gateway_bootstrap_gate.dart';

/// 主壳（[UcgHomeShell]）是否挂载；仅挂载时允许 history/UCG WS desired 与 token 轮换 reconnect。
///
/// 语义是「胖宝主壳会话」，不是喂养页 `HomeScreen` widget。
class PangbaoHomeTransportGate {
  static var _mountedCount = 0;

  static bool get isHomeMounted => _mountedCount > 0;

  static void onHomeMounted() => _mountedCount++;

  static void onHomeUnmounted() {
    if (_mountedCount > 0) _mountedCount--;
  }
}

/// 释放主壳占用的 pangbao 同 host 连接：历史 WS、UCG chat WS、Voice ASR、logo 下载。
///
/// 登出、切账号、离开主壳时调用；不销毁 Riverpod provider 实例。
/// [ref] 接受 Riverpod [Ref] 或 [WidgetRef]。
Future<void> releasePangbaoHomeTransports(dynamic ref) async {
  if (ref.exists(feedRepositoryProvider)) {
    ref.read(feedRepositoryProvider).disconnectHistoryWebSocket();
  }
  ref.read(eventCatalogProvider.notifier).cancelLogoDownloads();
  if (ref.exists(voiceAsrWsClientProvider)) {
    await ref.read(voiceAsrWsClientProvider).disconnect();
  }
  await deactivateUcgHomeSession(ref);
  // 离开 Home 时断开陪伴 Clinic WS（滑页保持，离壳释放）
  deactivateCompanionClinicWs(ref);
  GatewayBootstrapGate.reset();
}

/// gate 完成后串行激活 UCG（unread → WS → push）；须主壳仍挂载。
Future<void> mountUcgHomeTransportsIfEligible(dynamic ref) async {
  await activateUcgHomeSession(ref);
}
