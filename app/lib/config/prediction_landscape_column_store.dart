import 'package:shared_preferences/shared_preferences.dart';

const kPredictionLandscapeColumnCountKey =
    'prediction_landscape_column_count_v1';

/// 横屏瀑布列数下限/上限。
const kLandscapeColumnCountMin = 3;
const kLandscapeColumnCountMax = 7;

/// 横屏瀑布列数持久化（3–7）；无存档时由 UI 按设备档默认 3/5。
class PredictionLandscapeColumnStore {
  PredictionLandscapeColumnStore._();

  static Future<int?> loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(kPredictionLandscapeColumnCountKey);
    if (raw == null) return null;
    return raw.clamp(kLandscapeColumnCountMin, kLandscapeColumnCountMax);
  }

  static Future<void> save(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      kPredictionLandscapeColumnCountKey,
      count.clamp(kLandscapeColumnCountMin, kLandscapeColumnCountMax),
    );
  }
}

/// 有效列数：有存档用存档，否则手机 3 / 平板 5；始终 clamp 3–7。
int effectiveLandscapeColumnCount({
  required int? stored,
  required bool isTabletLandscape,
}) {
  final fallback = isTabletLandscape ? 5 : 3;
  return (stored ?? fallback)
      .clamp(kLandscapeColumnCountMin, kLandscapeColumnCountMax);
}
