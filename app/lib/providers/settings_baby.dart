import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import 'device_no_notifier.dart';
import 'repositories.dart';

/// 宝宝画像：依赖规范化 deviceNo，空↔有 / A→B 时重建，避免未绑定占位缓存为终态。
final settingsBabyProvider = FutureProvider<BabyProfile>((ref) async {
  // watch 建立依赖；实际 deviceNo 仍由 repository getter 读取。
  ref.watch(
    deviceNoNotifierProvider.select(
      (v) => v.asData?.value?.trim() ?? '',
    ),
  );
  return ref.read(settingsRepositoryProvider).loadBaby();
});
