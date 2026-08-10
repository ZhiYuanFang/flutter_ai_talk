import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/baby_age.dart';
import '../data/models.dart';
import 'settings_baby.dart';

/// 身份展示用当前宝宝：loading/error → null（交给 L1 / [BabyDisplay] 空态）。
final currentBabyProvider = Provider<BabyProfile?>((ref) {
  return ref.watch(settingsBabyProvider).asData?.value;
});

/// 身份展示快照：一次 watch 拿齐昵称/月龄/头像入参（墙钟 resolve，不订预测 clock）。
final babyDisplayProvider = Provider<BabyDisplay>((ref) {
  final baby = ref.watch(currentBabyProvider);
  return BabyDisplay.resolve(baby);
});
