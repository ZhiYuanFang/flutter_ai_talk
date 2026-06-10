import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/history_hourly_dual_day.dart';
import '../data/models.dart';
import 'chart_axis_granularity.dart';
import 'home_history_edit_glass_panel.dart';

/// 今/昨双折线（24 整点桶）；竖屏 X5/Y3，横屏 X7/Y5。
class HomeEventHourlyTrendChart extends StatelessWidget {
  const HomeEventHourlyTrendChart({
    super.key,
    required this.series,
    required this.accentColor,
    this.yAxisHint,
    this.compactHeader = false,
    this.denseAxes = false,
  });

  final HourlyDualDaySeries series;
  final Color accentColor;
  final String? yAxisHint;
  final bool compactHeader;
  /// 横屏矮面板：缩小轴标签占位，避免 RenderFlex 溢出。
  final bool denseAxes;

  static const _maxX = 23.0;

  static const double yesterdayLineOpacity = 0.3;

  static const double yesterdayLineWidth = 1.25;

  /// 昨日序列色：事件主题色向白混合的浅色，再 30% 不透明（实线）。
  static Color yesterdaySeriesColor(Color accentColor) {
    final lightTint = Color.lerp(accentColor, Colors.white, 0.62) ?? accentColor;
    return lightTint.withValues(alpha: yesterdayLineOpacity);
  }

  static double _maxVal(HourlyDualDaySeries s) {
    var m = 0.0;
    for (final p in s.today) {
      if (p.value > m) m = p.value;
    }
    for (final p in s.yesterday) {
      if (p.value > m) m = p.value;
    }
    return m;
  }

  static List<FlSpot> _spots(List<TrendPoint> pts) {
    return List<FlSpot>.generate(
      pts.length.clamp(0, 24),
      (i) => FlSpot(i.toDouble(), pts[i].value),
    );
  }

  SideTitles _bottomTitles(bool landscape, bool dense) {
    final marks = landscape
        ? ChartAxisGranularity.landscapeXHourMarks
        : ChartAxisGranularity.portraitXHourMarks;
    return ChartAxisGranularity.glassBottomTitles(
      landscape: landscape,
      dense: dense,
      showAtIndices: marks.toSet(),
      labelForIndex: (i) => i == 23 ? ChartAxisGranularity.hourLabel(24) : ChartAxisGranularity.hourLabel(i),
    );
  }

  SideTitles _leftTitles(double maxY, bool landscape, bool dense) {
    return ChartAxisGranularity.glassLeftTitles(
      maxY: maxY,
      landscape: landscape,
      dense: dense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final maxVal = _maxVal(series);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 1.0;
    final gridColor = Colors.white.withValues(alpha: 0.12);
    final borderColor = Colors.white.withValues(alpha: 0.18);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compactHeader && yAxisHint != null && yAxisHint!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              yAxisHint!,
              style: const TextStyle(
                fontSize: 11,
                color: HistoryEditGlassPanel.glassLabelColor,
              ),
            ),
          ),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: _maxX,
              minY: 0,
              maxY: maxY,
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: _bottomTitles(landscape, denseAxes)),
                leftTitles: AxisTitles(sideTitles: _leftTitles(maxY, landscape, denseAxes)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: borderColor),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
                getDrawingVerticalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _spots(series.yesterday),
                  isCurved: false,
                  color: yesterdaySeriesColor(accentColor),
                  barWidth: yesterdayLineWidth,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: _spots(series.today),
                  isCurved: false,
                  color: accentColor,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
