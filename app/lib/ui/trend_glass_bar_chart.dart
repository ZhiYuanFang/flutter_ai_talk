import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/trend_series_bucket.dart';
import 'chart_axis_granularity.dart';
import 'home_history_edit_glass_panel.dart';

/// 趋势中心玻璃态量柱图（仅柱图；轴粒度同主页今日趋势）。
class TrendGlassBarChart extends StatelessWidget {
  const TrendGlassBarChart({
    super.key,
    required this.series,
    required this.bucketMode,
    required this.accentColor,
    required this.chartTitle,
  });

  final TrendSeries? series;
  final TrendBucketMode bucketMode;
  final Color accentColor;

  /// 玻璃区内标题，如「拉屎趋势图」。
  final String chartTitle;

  static String chartTitleForEvent(String? eventName) {
    final name = eventName?.trim();
    if (name == null || name.isEmpty) return '趋势图';
    return '$name趋势图';
  }

  static final _dateFmt = DateFormat('MM-dd');

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final dense = landscape;
    final pts = series?.points ?? const <TrendPoint>[];
    final hourly = bucketMode == TrendBucketMode.hourly;
    final gridColor = Colors.white.withValues(alpha: 0.12);
    final borderColor = Colors.white.withValues(alpha: 0.18);
    final glassLabel = HistoryEditGlassPanel.glassLabelColor;

    return HistoryEditGlassPanel(
      eventAccent: accentColor,
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            chartTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: HistoryEditGlassPanel.glassTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '纵轴：计时类为小时(h)，计数类为次数',
            style: TextStyle(fontSize: 11, color: glassLabel),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: pts.isEmpty
                ? Center(
                    child: Text(
                      hourly ? '所选日期暂无数据' : '当前时间范围暂无数据',
                      style: TextStyle(color: glassLabel, fontSize: 15),
                    ),
                  )
                : _BarChartBody(
                    pts: pts,
                    hourly: hourly,
                    landscape: landscape,
                    dense: dense,
                    accentColor: accentColor,
                    gridColor: gridColor,
                    borderColor: borderColor,
                  ),
          ),
        ],
      ),
    );
  }
}

class _BarChartBody extends StatelessWidget {
  const _BarChartBody({
    required this.pts,
    required this.hourly,
    required this.landscape,
    required this.dense,
    required this.accentColor,
    required this.gridColor,
    required this.borderColor,
  });

  final List<TrendPoint> pts;
  final bool hourly;
  final bool landscape;
  final bool dense;
  final Color accentColor;
  final Color gridColor;
  final Color borderColor;

  String _bottomLabel(int index) {
    if (index < 0 || index >= pts.length) return '';
    final d = pts[index].t.toLocal();
    if (hourly) {
      if (index == 23) return ChartAxisGranularity.hourLabel(24);
      return ChartAxisGranularity.hourLabel(d.hour);
    }
    return TrendGlassBarChart._dateFmt.format(d);
  }

  @override
  Widget build(BuildContext context) {
    final xIndices = ChartAxisGranularity.xLabelIndices(
      pointCount: pts.length,
      landscape: landscape,
      hourlyToday: hourly,
    );
    final showAt = xIndices.toSet();

    final maxVal = pts.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 1.0;
    final barWidth = (pts.length > 12 ? 8.0 : 10.0).clamp(4.0, 14.0);
    final topHighlight = Color.lerp(accentColor, Colors.white, 0.35) ?? accentColor;

    final barGroups = List<BarChartGroupData>.generate(
      pts.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: pts[i].value,
            width: barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                accentColor.withValues(alpha: 0.45),
                accentColor.withValues(alpha: 0.88),
                topHighlight.withValues(alpha: 0.95),
              ],
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 4,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: ChartAxisGranularity.glassBottomTitles(
              landscape: landscape,
              dense: dense,
              showAtIndices: showAt,
              labelForIndex: _bottomLabel,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: ChartAxisGranularity.glassLeftTitles(
              maxY: maxY,
              landscape: landscape,
              dense: dense,
            ),
          ),
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
      ),
    );
  }
}
