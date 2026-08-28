import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/gateway_bootstrap_gate.dart';
import '../bootstrap/pangbao_transport_release.dart';
import '../config/env.dart';
import '../data/remote_auth_repository.dart';
import '../data/remote_feed_repository.dart';
import '../data/remote_settings_repository.dart';
import '../data/remote_trends_repository.dart';
import '../data/remote_version_repository.dart';
import '../data/repositories.dart';
import '../session/session_controller.dart';
import '../network/ws_session_binding.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';
import 'sign_in_channel_provider.dart';
import 'toast_bus.dart';
import 'wechat_auth_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthRepository(
    ref,
    weChatAuthGetter: () => ref.read(weChatAuthClientProvider),
  );
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final api = ref.watch(authorizedApiClientProvider);
  final remote = RemoteFeedRepository(
    api: api,
    deviceNoGetter: () => ref.read(deviceNoNotifierProvider).asData?.value,
    wsUrl: AppEnv.wsHistoryUrlEffective,
    ref: ref,
  );
  ref.onDispose(remote.dispose);

  void tryReconnectHistoryWs({bool resetStrike = false}) {
    if (AppEnv.disablePangbaoWebSocketSpike) return;
    // 门闸：主壳 UcgHomeShell 已挂载（非喂养页）
    if (!PangbaoHomeTransportGate.isHomeMounted) return;
    if (!GatewayBootstrapGate.isLoggedInComplete) return;
    if (AppEnv.wsHistoryUrlEffective.isEmpty) return;
    // reconnect 先断开旧连接，再在 token / deviceNo 就绪时建链；登出或解绑时也会关掉 WS。
    unawaited(remote.reconnectHistoryWebSocket(resetStrike: resetStrike));
  }

  ref.listen<bool>(
    sessionProvider.select((s) => s.isLoggedIn),
    (prev, loggedIn) {
      if (prev == true && !loggedIn) {
        unawaited(releasePangbaoHomeTransports(ref));
      }
    },
  );
  ref.listen<String?>(
    sessionProvider.select((s) => s.accessToken),
    (prev, next) {
      if (!SessionController.isAccessTokenRotation(prev, next)) return;
      if (!ref.read(sessionProvider).isLoggedIn) return;
      final gaveUp = remote.historyWsPhase == HistoryWsPhase.gaveUp;
      tryReconnectHistoryWs(resetStrike: gaveUp);
    },
  );
  bindAuthenticatedWsSession(
    ref,
    watchDeviceNo: true,
    reconnect: ({bool resetStrike = false}) async {
      tryReconnectHistoryWs(resetStrike: resetStrike);
    },
    shouldReconnect: () {
      if (!ref.read(sessionProvider).isLoggedIn) return false;
      if (!PangbaoHomeTransportGate.isHomeMounted) return false;
      if (!GatewayBootstrapGate.isLoggedInComplete) return false;
      if (AppEnv.wsHistoryUrlEffective.isEmpty) return false;
      final dn = ref.read(deviceNoNotifierProvider).asData?.value;
      return dn != null && dn.isNotEmpty;
    },
  );

  // 建连由主壳 watchLatest() 订阅后 ensure，避免 provider 创建时抢连。
  return remote;
});

final trendsRepositoryProvider = Provider<TrendsRepository>((ref) {
  return RemoteTrendsRepository(ref);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final api = ref.watch(authorizedApiClientProvider);
  return RemoteSettingsRepository(
    api,
    () => ref.read(deviceNoNotifierProvider).asData?.value,
    signInChannelGetter: () => ref.read(signInChannelProvider),
    onToast: (m) => ref.showApiToastError(m),
  );
});

final versionRepositoryProvider = Provider<VersionRepository>((ref) {
  final api = ref.watch(authorizedApiClientProvider);
  return RemoteVersionRepository(api);
});
