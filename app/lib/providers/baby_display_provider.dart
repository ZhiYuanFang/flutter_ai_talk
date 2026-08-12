import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/baby_age.dart';
import '../data/models.dart';
import 'device_no_notifier.dart';
import 'session_provider.dart';
import 'settings_baby.dart';

/// 身份展示用当前宝宝：loading/error → null（交给 L1 / [BabyDisplay] 空态）。
final currentBabyProvider = Provider<BabyProfile?>((ref) {
  return ref.watch(settingsBabyProvider).asData?.value;
});

/// 已绑定 deviceNo 下，画像是否仍为未绑定占位 / 未就绪。
bool isBabyProfileBoundPending(BabyProfile? baby) {
  if (baby == null) return true;
  if (baby.id.trim().isEmpty) return true;
  if (baby.nickname.trim() == kUnboundBabyPlaceholderNickname) return true;
  return false;
}

/// 身份展示快照：一次 watch 拿齐昵称/月龄/头像入参（墙钟 resolve，不订预测 clock）。
/// 未登录 / 已登录未绑定由会话态覆盖文案并隐藏月龄。
final babyDisplayProvider = Provider<BabyDisplay>((ref) {
  final loggedIn = ref.watch(sessionProvider).isLoggedIn;
  final deviceNo =
      ref.watch(deviceNoNotifierProvider).asData?.value?.trim() ?? '';
  final baby = ref.watch(currentBabyProvider);
  // 游客顶栏：不露出占位宝宝与虚假月龄。
  if (!loggedIn) {
    return BabyDisplay.authChrome(nickname: '未登录');
  }
  // 已登录未绑定：与预测门闸 bound 判定一致。
  if (deviceNo.isEmpty) {
    return BabyDisplay.authChrome(nickname: '未绑定宝宝', profile: baby);
  }
  // deviceNo 已有但画像仍占位：隐藏月龄，避免「宝宝 · 不满1个月啦」。
  if (isBabyProfileBoundPending(baby)) {
    return BabyDisplay.authChrome(nickname: '宝宝', profile: baby);
  }
  return BabyDisplay.resolve(baby);
});
