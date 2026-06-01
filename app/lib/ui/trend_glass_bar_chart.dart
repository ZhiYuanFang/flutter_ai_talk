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
    required this.dateRangeLabel,
    this.barAnimationToken = 0,
    this.holdAtZeroBeforeAnimation = false,
    this.suppressEmptyState = false,
    this.headerTopOffset = 0,
    this.headerLogo,
    this.onTitleTap,
    this.onDateRangeTap,
  });

  final TrendSeries? series;
  final TrendBucketMode bucketMode;
  final Color accentColor;

  /// 玻璃区内标题，如「拉屎趋势图」。
  final String chartTitle;
  final String dateRangeLabel;
  final int barAnimationToken;
  final bool holdAtZeroBeforeAnimation;
  final bool suppressEmptyState;
  final double headerTopOffset;
  final Widget? headerLogo;
  final VoidCallback? onTitleTap;
  final VoidCallback? onDateRangeTap;

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
    final borderColor = Colors.white.withValues(alpha: 0.18);
    final glassLabel = HistoryEditGlassPanel.glassLabelColor;

    return HistoryEditGlassPanel(
      eventAccent: accentColor,
      borderRadius: 0,
      contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerTopOffset > 0) SizedBox(height: headerTopOffset),
          if (headerLogo != null) ...[
            Align(
              alignment: Alignment.center,
              child: headerLogo!,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTitleTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          chartTitle,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: HistoryEditGlassPanel.glassTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.expand_more,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDateRangeTap,
                child: Text(
                  dateRangeLabel,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: glassLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: pts.isEmpty
                ? suppressEmptyState
                    ? const SizedBox.expand()
                    : Center(
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
                    borderColor: borderColor,
                    barAnimationToken: barAnimationToken,
                    holdAtZeroBeforeAnimation: holdAtZeroBeforeAnimation,
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
    required this.borderColor,
    required this.barAnimationToken,
    required this.holdAtZeroBeforeAnimation,
  });

  final List<TrendPoint> pts;
  final bool hourly;
  final bool landscape;
  final bool dense;
  final Color accentColor;
  final Color borderColor;
  final int barAnimationToken;
  final bool holdAtZeroBeforeAnimation;

  String _bottomLabel(int index) {
    if (index < 0 || index >= pts.length) return '';
    final d = pts[index].t.toLocal();
    if (hourly) {
      if (index == 23) return ChartAxisGranularity.hourLabel(24);
      return ChartAxisGranularity.hourLabel(d.hour);
    }
    return TrendGlassBarChart._dateFmt.format(d);
  }

  String _tooltipValue(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  @override
  Widget build(BuildContext context) {
    if (holdAtZeroBeforeAnimation && barAnimationToken <= 0) {
      return _buildBarChart(0.0);
    }
    if (barAnimationToken <= 0) {
      return _buildBarChart(1.0);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(barAnimationToken),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeOutCubic,
      builder: (context, factor, _) => _buildBarChart(factor),
    );
  }

  Widget _buildBarChart(double growFactor) {
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
            toY: pts[i].value * growFactor,
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
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: borderColor),
          ),
        ),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black.withValues(alpha: 0.76),
            tooltipRoundedRadius: 10,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final rawValue = (group.x >= 0 && group.x < pts.length)
                  ? pts[group.x].value
                  : rod.toY;
              return BarTooltipItem(
                _tooltipValue(rawValue),
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
