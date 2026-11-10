import 'package:shared_preferences/shared_preferences.dart';

const _kHistoryExpectResumeIdKey = 'history_expect_resume_id_v1';

/// 静默 expect 管线杀进程恢复游标：存 [HistoryRecord.id] 字符串。
class HistoryExpectResumeStore {
  /// 读取 resume 游标；无则 null。
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kHistoryExpectResumeIdKey)?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// 写入非空游标字符串。
  static Future<void> save(String historyId) async {
    final id = historyId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistoryExpectResumeIdKey, id);
  }

  /// 清空游标。
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryExpectResumeIdKey);
  }
}
