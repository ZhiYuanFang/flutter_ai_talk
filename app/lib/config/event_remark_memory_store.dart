import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 按事件 ID 记忆最近确认的 remark（最多 3 条），供快捷标签选取。
class EventRemarkMemoryStore {
  static const _keyPrefix = 'event_remark_recent_v1_';
  static const _maxCount = 3;

  static Future<List<String>> load(String eventId) async {
    if (eventId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$eventId');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(_maxCount)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(String eventId, String remark) async {
    final trimmed = remark.trim();
    if (eventId.isEmpty || trimmed.isEmpty) return;
    final existing = await load(eventId);
    final updated = [
      trimmed,
      ...existing.where((e) => e != trimmed),
    ].take(_maxCount).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$eventId', jsonEncode(updated));
  }
}
