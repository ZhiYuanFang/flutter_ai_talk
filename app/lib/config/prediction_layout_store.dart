import 'package:shared_preferences/shared_preferences.dart';

/// 智能预测卡片排列。
enum PredictionCardsLayout {
  list,
  grid,
}

const kPredictionCardsLayoutKey = 'prediction_cards_layout_v1';

/// 布局偏好：默认网格。
class PredictionLayoutStore {
  PredictionLayoutStore._();

  static Future<PredictionCardsLayout> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kPredictionCardsLayoutKey);
    if (raw == 'list') return PredictionCardsLayout.list;
    // 缺省 / grid / 未知 → 网格
    return PredictionCardsLayout.grid;
  }

  static Future<void> save(PredictionCardsLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kPredictionCardsLayoutKey,
      layout == PredictionCardsLayout.list ? 'list' : 'grid',
    );
  }
}
