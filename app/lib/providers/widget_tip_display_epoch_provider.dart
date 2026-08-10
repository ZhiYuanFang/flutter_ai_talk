import 'package:flutter_riverpod/flutter_riverpod.dart';

/// tip 缓存可供预测页展示时递增，驱动 [widgetTipCardTextProvider] 重 peek。
/// （独立文件避免 home_widget_sync → smart_prediction 循环依赖）
final widgetTipDisplayEpochProvider = StateProvider<int>((ref) => 0);

void bumpWidgetTipDisplayEpoch(dynamic ref) {
  try {
    final notifier = ref.read(widgetTipDisplayEpochProvider.notifier);
    notifier.state = ref.read(widgetTipDisplayEpochProvider) + 1;
  } catch (_) {
    // 无 ProviderScope / 测试桩时忽略
  }
}
