import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'home_history_edit_glass_panel.dart';

/// 与主页今日小时趋势图一致的横纵轴标签粒度（竖屏 X5/Y3，横屏 X7/Y5）。
class ChartAxisGranularity {
  ChartAxisGranularity._();

  static const portraitXHourMarks = [0, 6, 12, 18, 23];
  static const landscapeXHourMarks = [0, 4, 8, 12, 16, 20, 23];

  static int get portraitXLabelCount => portraitXHourMarks.length;
  static int get landscapeXLabelCount => landscapeXHourMarks.length;
  static int yLabelCount(bool landscape) => landscape ? 5 : 3;

  static String formatY(double value) {
    if (value == 0) return '0';
    if (value.abs() < 1) return value.toStringAsFixed(2);
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  static String hourLabel(int hour) {
    if (hour >= 24) return '24:00';
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  /// 周/月/季按日分桶：在 [0, length-1] 上均匀取 labelCount 个索引。
  static List<int> evenlySpacedIndices(int length, int labelCount) {
    if (length <= 0) return const [];
    if (length <= labelCount) {
      return List.generate(length, (i) => i);
    }
    final out = <int>{0, length - 1};
    for (var k = 1; k < labelCount - 1; k++) {
      out.add((k * (length - 1) / (labelCount - 1)).round());
    }
    final sorted = out.toList()..sort();
    return sorted;
  }

  static List<int> xLabelIndices({
    required int pointCount,
    required bool landscape,
    required bool hourlyToday,
  }) {
    if (pointCount <= 0) return const [];
    if (hourlyToday) {
      final marks = landscape ? landscapeXHourMarks : portraitXHourMarks;
      return marks.where((i) => i < pointCount).toList();
    }
    return evenlySpacedIndices(
      pointCount,
      landscape ? landscapeXLabelCount : portraitXLabelCount,
    );
  }

  static SideTitles glassBottomTitles({
    required BuildContext context,
    required bool landscape,
    required bool dense,
    required Set<int> showAtIndices,
    required String Function(int index) labelForIndex,
  }) {
    return SideTitles(
      showTitles: true,
      reservedSize: dense ? 22 : 28,
      interval: 1,
      getTitlesWidget: (value, meta) {
        final i = value.round();
        if ((value - i).abs() > 1e-6) return const SizedBox.shrink();
        if (!showAtIndices.contains(i)) return const SizedBox.shrink();
        return SideTitleWidget(
          axisSide: meta.axisSide,
          space: 4,
          child: Text(
            labelForIndex(i),
            style: TextStyle(
              fontSize: 10,
              color: historyEditGlassLabelColor(context),
            ),
          ),
        );
      },
    );
  }

  static SideTitles glassLeftTitles({
    required BuildContext context,
    required double maxY,
    required bool landscape,
    required bool dense,
  }) {
    final count = yLabelCount(landscape);
    if (maxY <= 0 || count < 2) {
      return const SideTitles(showTitles: false);
    }
    final step = maxY / (count - 1);
    if (step <= 0) {
      return const SideTitles(showTitles: false);
    }
    return SideTitles(
      showTitles: true,
      reservedSize: dense ? 30 : (landscape ? 36 : 40),
      interval: step,
      getTitlesWidget: (value, meta) {
        if (value < -1e-6 || value > maxY + 1e-6) {
          return const SizedBox.shrink();
        }
        final index = (value / step).round();
        if (index < 0 || index >= count) return const SizedBox.shrink();
        if ((value - index * step).abs() > step * 0.25 + 1e-6) {
          return const SizedBox.shrink();
        }
        return SideTitleWidget(
          axisSide: meta.axisSide,
          space: 4,
          child: Text(
            formatY(value),
            style: TextStyle(
              fontSize: 9,
              color: historyEditGlassLabelColor(context),
            ),
          ),
        );
      },
    );
  }
}
