import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (AppEnv.wsHistoryUrlEffective.isEmpty) return;
    // reconnect 先断开旧连接，再在 token / deviceNo 就绪时建链；登出或解绑时也会关掉 WS。
    unawaited(remote.reconnectHistoryWebSocket(resetStrike: resetStrike));
  }

  ref.listen<bool>(
    sessionProvider.select((s) => s.isLoggedIn),
    (prev, loggedIn) {
      if (prev == true && !loggedIn) {
        remote.disconnectHistoryWebSocket();
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
    reconnect: ({bool resetStrike = false}) async {
      tryReconnectHistoryWs(resetStrike: resetStrike);
    },
    shouldReconnect: () {
      if (AppEnv.wsHistoryUrlEffective.isEmpty) return false;
      final dn = ref.read(deviceNoNotifierProvider).asData?.value;
      return dn != null && dn.isNotEmpty;
    },
  );

  // 建连由 watchLatest() 订阅后触发，避免 provider 创建时 watch 未订阅导致失败不重试。
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
