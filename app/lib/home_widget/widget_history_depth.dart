import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../data/models.dart';
import '../providers/prediction_range_history_provider.dart';

/// 小组件预测历史：委托近 7 日 range ensure（不再分页拉满 30 日）。
Future<void> ensureWidgetHistoryDepth(dynamic ref) {
  if (kIsWeb) return Future.value();
  return ref.read(predictionRangeHistoryProvider.notifier).ensureLoaded();
}

/// 供其它模块判断列表是否已跨满 [days]（升序 items.first 为最旧）。
bool historySpansEnoughDays(List<HistoryRecord> items, int days) {
  if (items.isEmpty) return false;
  final oldest = items.first.createdAt.toLocal();
  return DateTime.now().difference(oldest).inDays >= days;
}
