import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../data/remote_auth_repository.dart';
import '../data/remote_feed_repository.dart';
import '../data/remote_settings_repository.dart';
import '../data/remote_trends_repository.dart';
import '../data/remote_version_repository.dart';
import '../data/repositories.dart';
import 'authorized_api_client_provider.dart';
import 'device_no_notifier.dart';
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
    onToast: (m) => ref.read(apiToastProvider.notifier).state = m,
  );
});

final versionRepositoryProvider = Provider<VersionRepository>((ref) {
  final api = ref.watch(authorizedApiClientProvider);
  return RemoteVersionRepository(api);
});
