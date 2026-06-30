import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/event_catalog_notifier.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/voice_asr_ws_provider.dart';
import '../session/token_expiry.dart';
import '../ucg/providers/ucg_providers.dart';
import 'gateway_bootstrap_gate.dart';

/// 释放 Home 占用的 pangbao 同 host 连接：历史 WS、UCG chat WS、Voice ASR、logo 下载。
///
/// 登出、切账号、离开 Home 时调用；不销毁 Riverpod provider 实例。
/// [ref] 接受 Riverpod [Ref] 或 [WidgetRef]。
Future<void> releasePangbaoHomeTransports(dynamic ref) async {
  ref.read(feedRepositoryProvider).disconnectHistoryWebSocket();
  ref.read(eventCatalogProvider.notifier).cancelLogoDownloads();
  if (ref.exists(ucgRepositoryProvider)) {
    ref.read(ucgRepositoryProvider).setWsConnectionDesired(false);
  }
  if (ref.exists(voiceAsrWsClientProvider)) {
    await ref.read(voiceAsrWsClientProvider).disconnect();
  }
  GatewayBootstrapGate.reset();
}

/// gate 完成后挂载 UCG 传输（chat WS + unread）。
void mountUcgHomeTransportsIfEligible(dynamic ref) {
  if (!ref.read(sessionProvider).isLoggedIn) return;
  final wxId = readJwtWxId(ref.read(sessionProvider).accessToken);
  if (!isUcgWxAccountBound(wxId)) return;
  final repo = ref.read(ucgRepositoryProvider);
  repo.setWsConnectionDesired(true);
  unawaited(syncUcgUnreadFromServer(ref));
}
