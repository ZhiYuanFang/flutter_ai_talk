import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../voice/voice_chat_ws_client.dart';
import 'device_no_notifier.dart';

/// `/voice/chat/ws` 客户端；连接仅由预测横屏生命周期显式发起。
final voiceChatWsClientProvider = Provider<VoiceChatWsClient>((ref) {
  final client = VoiceChatWsClient(
    wsUrl: AppEnv.wsVoiceChatUrlEffective,
    deviceNoGetter: () => ref.read(deviceNoNotifierProvider).asData?.value,
  );
  ref.onDispose(() => unawaited(client.dispose()));
  return client;
});
