import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/baby_avatar_local_store.dart';
import '../data/home_history_memory_cache.dart';
import '../data/remote_settings_repository.dart';
import '../providers/baby_avatar_provider.dart';
import '../providers/device_no_notifier.dart';
import '../providers/home_history_notifier.dart';
import '../providers/prediction_range_history_provider.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/settings_baby.dart';
import '../providers/sign_in_channel_provider.dart';
import '../providers/user_profile_provider.dart';

/// 切换账号 / 注销后的本地擦除（宝宝 + 喂养 + 会话侧缓存）。
///
/// 接受 [ProviderContainer]，供 Sheet dispose 后安全调用。
/// **不得**清除凭据历史 store（基线：切号保留登录建议列表）。
Future<void> wipeAccountLocalState(ProviderContainer container) async {
  // 清 deviceNo 前快照，便于删画像 prefs / 头像
  final dn =
      container.read(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
  final baby = container.read(settingsBabyProvider).asData?.value;
  final babyId = baby?.id.trim() ?? '';

  await container.read(sessionProvider).signOut();
  await container.read(signInChannelProvider.notifier).clear();
  await container.read(deviceNoNotifierProvider.notifier).clearLocal();
  await container.read(feedRepositoryProvider).clearCache();
  HomeHistoryMemoryCache.clear();
  container.read(homeHistoryProvider.notifier).clearForSignOut();
  container.read(predictionRangeHistoryProvider.notifier).clear();

  if (dn.isNotEmpty) {
    await RemoteSettingsRepository.clearLocalProfilePrefs(dn);
  }
  if (babyId.isNotEmpty) {
    await RemoteSettingsRepository.clearLocalProfilePrefs(babyId);
    await BabyAvatarLocalStore.clearAvatar(babyId);
  }

  container.invalidate(settingsBabyProvider);
  container.invalidate(userProfileProvider);
  container.read(babyAvatarRevisionProvider.notifier).state++;
}
