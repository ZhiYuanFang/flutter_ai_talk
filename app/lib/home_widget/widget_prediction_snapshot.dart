import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';
import '../data/event_next_predictor.dart';
import 'home_widget_constants.dart';

/// 后台 skip 可读的预测结果快照单行（与 [EventNextPrediction] 对齐）。
class WidgetPredictionSnapshotRow {
  const WidgetPredictionSnapshotRow({
    required this.eventId,
    required this.eventName,
    required this.lastAt,
    required this.nextAt,
    required this.colorHex,
    required this.confidence,
  });

  final String eventId;
  final String eventName;
  final DateTime lastAt;
  final DateTime nextAt;
  final String colorHex;
  final double confidence;

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventName': eventName,
        'lastAt': lastAt.toUtc().toIso8601String(),
        'nextAt': nextAt.toUtc().toIso8601String(),
        'colorHex': colorHex,
        'confidence': confidence,
      };

  static WidgetPredictionSnapshotRow? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final eventId = (map['eventId'] as String?)?.trim() ?? '';
    if (eventId.isEmpty) return null;
    final lastAt = DateTime.tryParse(map['lastAt'] as String? ?? '');
    final nextAt = DateTime.tryParse(map['nextAt'] as String? ?? '');
    if (lastAt == null || nextAt == null) return null;
    return WidgetPredictionSnapshotRow(
      eventId: eventId,
      eventName: (map['eventName'] as String?)?.trim() ?? '',
      lastAt: lastAt,
      nextAt: nextAt,
      colorHex: (map['colorHex'] as String?)?.trim().isNotEmpty == true
          ? (map['colorHex'] as String).trim()
          : '#5BA3E8',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  EventNextPrediction toPrediction() => EventNextPrediction(
        eventId: eventId,
        eventName: eventName,
        lastAt: lastAt,
        nextAt: nextAt,
        colorHex: colorHex,
        confidence: confidence,
      );

  static WidgetPredictionSnapshotRow fromPrediction(EventNextPrediction p) =>
      WidgetPredictionSnapshotRow(
        eventId: p.eventId,
        eventName: p.eventName,
        lastAt: p.lastAt,
        nextAt: p.nextAt,
        colorHex: p.colorHex,
        confidence: p.confidence,
      );
}

/// 预测结果快照：前台 sync 写出，后台 skip 重建 hero / recentLast。
class WidgetPredictionSnapshotStore {
  WidgetPredictionSnapshotStore._();

  /// 最多保留条数（覆盖 large：hero + 6，留余量供连续跳过）。
  static const maxRows = 16;

  /// 将有序预测写入 prefs（后台 isolate 可读）。
  static Future<void> savePredictions(List<EventNextPrediction> predictions) async {
    try {
      final rows = predictions
          .take(maxRows)
          .map(WidgetPredictionSnapshotRow.fromPrediction)
          .toList();
      final prefs = await SharedPreferences.getInstance();
      if (rows.isEmpty) {
        await prefs.remove(HomeWidgetConstants.predictionSnapshotKey);
        AppDebugLog.homeWidget('prediction snapshot cleared (empty)');
        return;
      }
      final encoded = jsonEncode({
        'v': 1,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'rows': rows.map((r) => r.toJson()).toList(),
      });
      await prefs.setString(HomeWidgetConstants.predictionSnapshotKey, encoded);
      AppDebugLog.homeWidget('prediction snapshot save n=${rows.length}');
    } catch (e) {
      AppDebugLog.homeWidget('prediction snapshot save err=$e');
    }
  }

  /// 读取快照为 [EventNextPrediction] 列表；损坏或空则返回空并打日志。
  static Future<List<EventNextPrediction>> loadPredictions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(HomeWidgetConstants.predictionSnapshotKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        AppDebugLog.homeWidget('prediction snapshot load err=not_map');
        return const [];
      }
      final rowsRaw = decoded['rows'];
      if (rowsRaw is! List) {
        AppDebugLog.homeWidget('prediction snapshot load err=no_rows');
        return const [];
      }
      final out = <EventNextPrediction>[];
      for (final item in rowsRaw) {
        final row = WidgetPredictionSnapshotRow.fromJson(item);
        if (row != null) out.add(row.toPrediction());
      }
      return out;
    } catch (e) {
      AppDebugLog.homeWidget('prediction snapshot load err=$e');
      return const [];
    }
  }

  /// 登出或 empty 时清除，避免串用户。
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(HomeWidgetConstants.predictionSnapshotKey);
      AppDebugLog.homeWidget('prediction snapshot cleared');
    } catch (e) {
      AppDebugLog.homeWidget('prediction snapshot clear err=$e');
    }
  }
}
