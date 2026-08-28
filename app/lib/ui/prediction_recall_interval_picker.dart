import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import 'event_logo.dart';
import 'glass_single_wheel_picker_sheet.dart';
import 'home_history_edit_glass_panel.dart';

/// recall / per-card 间隔滚轮选项（15 分钟步进，最长 24 小时）。
List<int> recallIntervalMinuteChoices() => [
      for (var m = 15; m <= 24 * 60; m += 15) m,
    ];

/// 间隔分钟数 → 展示文案。
String formatRecallIntervalMinutes(int minutes) {
  if (minutes < 60) return '$minutes 分钟';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '$h 小时';
  return '$h 小时 $m 分钟';
}

/// 弹出间隔滚轮；[definition] 非空时标题为 logo + 事件名 +「·大概多久一次」。
Future<int?> pickRecallIntervalMinutes(
  BuildContext context, {
  EventDefinition? definition,
  String? eventName,
  int initialMinutes = 180,
}) async {
  final items = recallIntervalMinuteChoices();
  var idx = items.indexOf(initialMinutes);
  if (idx < 0) idx = items.indexOf(180).clamp(0, items.length - 1);
  final labels = [for (final m in items) formatRecallIntervalMinutes(m)];
  final onSheet = historyEditGlassTextColor(context);
  Widget? titleWidget;
  if (definition != null) {
    final name = (eventName?.trim().isNotEmpty == true)
        ? eventName!.trim()
        : definition.name.trim();
    titleWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        EventLogo(definition: definition, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$name·大概多久一次',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: onSheet,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  final picked = await showGlassSingleWheelPickerSheet(
    context,
    title: definition == null ? '大概多久一次' : null,
    titleWidget: titleWidget,
    labels: labels,
    initialIndex: idx,
  );
  if (picked == null) return null;
  return items[picked];
}
