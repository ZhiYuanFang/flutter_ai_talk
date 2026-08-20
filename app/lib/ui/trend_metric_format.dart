import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import '../data/history_record_metric.dart';
import 'home_history_edit_glass_panel.dart';

/// 趋势图量标：计时→时分；计数→数值+unit；计次→数值+「次」。
String formatTrendMetricLabel({
  required double value,
  required EventCatalogEventType? eventType,
  String? unit,
}) {
  final isDuration = eventType == EventCatalogEventType.time;
  final isOnce = eventType == EventCatalogEventType.one;
  final amount = formatTodayTotalAmount(
    TodayEventTotal(
      eventId: '',
      eventName: '',
      value: value,
      isDurationHours: isDuration,
      unit: unit ?? '',
    ),
  );
  if (isDuration) return amount;
  if (isOnce) return '$amount次';
  final u = (unit ?? '').trim();
  if (u.isEmpty) return amount;
  return '$amount$u';
}

/// Y 轴顶固定单位：计时→时长；计次→次；计数→unit（空则「量」）。
String trendYAxisUnitLabel({
  required EventCatalogEventType? eventType,
  String? unit,
}) {
  if (eventType == EventCatalogEventType.time) return '时长';
  if (eventType == EventCatalogEventType.one) return '次';
  final u = (unit ?? '').trim();
  return u.isEmpty ? '量' : u;
}

/// 单位文案放在图表上方、对齐 Y 轴 reserved 宽，避免叠在顶刻度或居中标题上。
Widget wrapTrendChartWithYAxisUnit({
  required BuildContext context,
  required Widget chart,
  required String unitLabel,
  required bool landscape,
  required bool dense,
}) {
  final leftReserved = dense ? 30.0 : (landscape ? 36.0 : 40.0);
  final color = historyEditGlassLabelColor(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Y 轴正上方：仅占左侧刻度列宽，不与居中标题抢位。
      SizedBox(
        height: 14,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: leftReserved,
            child: Text(
              unitLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Expanded(child: chart),
    ],
  );
}

/// 本地日时刻映射到 [0,1)（用于柱内散点 / 时间轴）。
double timeOfDayFraction(DateTime t) {
  final l = t.toLocal();
  return (l.hour * 60 + l.minute + l.second / 60.0) / (24 * 60);
}
