import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../voice/voice_asr_ws_client.dart';
import 'device_no_notifier.dart';

final voiceAsrWsClientProvider = Provider<VoiceAsrWsClient>((ref) {
  final client = VoiceAsrWsClient(
    wsUrl: AppEnv.wsVoiceAsrUrlEffective,
    deviceNoGetter: () => ref.read(deviceNoNotifierProvider).asData?.value,
  );
  ref.onDispose(() => unawaited(client.dispose()));

  // 连接由首页 [_scheduleVoiceAsrConnectIfNeeded] 统一发起，避免与 Provider 重复 connect 互踢。

  return client;
});

/// 语音转写 WebSocket 是否已连接（可发 start）。
final voiceAsrWsReadyProvider = Provider<bool>((ref) {
  final client = ref.watch(voiceAsrWsClientProvider);
  ref.listen(voiceAsrWsClientProvider, (_, __) {});
  // 订阅以在 readyStream 变化时重建；Home 侧直接 listen stream 更稳。
  return client.isReady;
});
