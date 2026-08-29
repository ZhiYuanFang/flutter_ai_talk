import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UCG 广场 Feed 布局。
enum UcgSquareFeedLayout {
  /// 纵向全宽列表
  list,

  /// 双列瀑布流（PK 全宽打断）
  waterfall,
}

const _prefsKey = 'ucg_square_feed_layout_v1';

/// 广场布局偏好（默认列表）。
final ucgSquareFeedLayoutProvider =
    AsyncNotifierProvider<UcgSquareFeedLayoutNotifier, UcgSquareFeedLayout>(
  UcgSquareFeedLayoutNotifier.new,
);

class UcgSquareFeedLayoutNotifier extends AsyncNotifier<UcgSquareFeedLayout> {
  @override
  Future<UcgSquareFeedLayout> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == UcgSquareFeedLayout.waterfall.name) {
      return UcgSquareFeedLayout.waterfall;
    }
    return UcgSquareFeedLayout.list;
  }

  Future<void> setLayout(UcgSquareFeedLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, layout.name);
    state = AsyncData(layout);
  }

  Future<void> toggle() async {
    final cur = state.asData?.value ?? UcgSquareFeedLayout.list;
    final next = cur == UcgSquareFeedLayout.list
        ? UcgSquareFeedLayout.waterfall
        : UcgSquareFeedLayout.list;
    await setLayout(next);
  }
}
