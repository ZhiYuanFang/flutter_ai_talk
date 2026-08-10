import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 宝宝头像本地变更世代：选图/落盘后自增，驱动 [BabyAvatar] 重载。
final babyAvatarRevisionProvider = StateProvider<int>((ref) => 0);

void bumpBabyAvatarRevision(WidgetRef ref) {
  ref.read(babyAvatarRevisionProvider.notifier).state++;
}
