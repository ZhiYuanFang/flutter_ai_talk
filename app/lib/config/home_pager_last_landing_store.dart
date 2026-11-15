import 'package:shared_preferences/shared_preferences.dart';

import '../providers/home_pager.dart';

/// 主壳冷启着陆：仅记忆喂养 / 预测（UCG 不写）。
///
/// [warm] 须在进 `/home` 前调用（如 `main`），以便 [peek] 同步可读、避免闪页。
class HomePagerLastLandingStore {
  HomePagerLastLandingStore._();

  static const prefsKey = 'home_pager_last_page_v1';

  /// 进程内缓存；[warm]/[save] 后可供同步 [peek]。
  static int? _memory;
  static SharedPreferences? _prefs;

  /// 拉取 prefs 并填充内存（可重复调用）。
  static Future<void> warm() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _memory = _decode(prefs.getInt(prefsKey));
  }

  /// 同步读合法页；未 warm 或无记忆返回 null（调用方回落预测）。
  static int? peek() {
    if (_memory != null) return _memory;
    final prefs = _prefs;
    if (prefs == null) return null;
    final decoded = _decode(prefs.getInt(prefsKey));
    _memory = decoded;
    return decoded;
  }

  /// 仅允许 feeding / prediction；UCG 等非法值忽略。
  static Future<void> save(int page) async {
    final normalized = _decode(page);
    if (normalized == null) return;
    _memory = normalized;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setInt(prefsKey, normalized);
  }

  /// 合法 → 原值；非法 → null。
  static int? _decode(int? raw) {
    if (raw == HomePagerPage.feeding || raw == HomePagerPage.prediction) {
      return raw;
    }
    return null;
  }
}
