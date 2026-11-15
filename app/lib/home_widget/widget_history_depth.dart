import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../data/models.dart';
import '../providers/home_history_notifier.dart';

/// 小组件预测历史：委托统一池近 7 日种子（不再独立 range HTTP）。
Future<void> ensureWidgetHistoryDepth(dynamic ref) {
  if (kIsWeb) return Future.value();
  return ref.read(homeHistoryProvider.notifier).seedSevenDayHistory(
        force: false,
        preserveOlderOutsideWindow: true,
      );
}

/// 供其它模块判断列表是否已跨满 [days]（升序 items.first 为最旧）。
bool historySpansEnoughDays(List<HistoryRecord> items, int days) {
  if (items.isEmpty) return false;
  final oldest = items.first.createdAt.toLocal();
  return DateTime.now().difference(oldest).inDays >= days;
}
