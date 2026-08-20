import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/event_definition.dart';
import '../data/models.dart';
import 'chart_axis_granularity.dart';
import 'home_history_edit_glass_panel.dart';
import 'trend_metric_format.dart';

/// 近 N 日总量玻璃柱图（Y 轴 3 刻度；顶标仅选中柱；计次可柱内散点）。
class TrendNDayBarChart extends StatefulWidget {
  const TrendNDayBarChart({
    super.key,
    required this.daily,
    required this.raw,
    required this.accentColor,
    required this.eventType,
    this.unit,
    this.selectedDay,
    this.onSelectDay,
    this.barAnimationToken = 0,
    this.holdAtZeroBeforeAnimation = false,
  });

  final List<TrendPoint> daily;
  final List<TrendPoint> raw;
  final Color accentColor;
  final EventCatalogEventType? eventType;
  final String? unit;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onSelectDay;
  final int barAnimationToken;
  final bool holdAtZeroBeforeAnimation;

  static final _dateFmt = DateFormat('MM-dd');

  @override
  State<TrendNDayBarChart> createState() => _TrendNDayBarChartState();
}

class _TrendNDayBarChartState extends State<TrendNDayBarChart> {
  /// TapUp 时 fl_chart 常清空 spot，需在 Down 时缓存。
  int? _pendingSelectIndex;

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final dense = landscape;
    final glassLabel = historyEditGlassLabelColor(context);

    if (widget.daily.isEmpty) {
      return Center(
        child: Text(
          '当前时间范围暂无数据',
          style: TextStyle(color: glassLabel, fontSize: 15),
        ),
      );
    }

    if (widget.holdAtZeroBeforeAnimation && widget.barAnimationToken <= 0) {
      return _body(context, 0.0, landscape, dense);
    }
    if (widget.barAnimationToken <= 0) {
      return _body(context, 1.0, landscape, dense);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(widget.barAnimationToken),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeOutCubic,
      builder: (context, factor, _) => _body(context, factor, landscape, dense),
    );
  }

  int? _selectedIndex() {
    final sel = widget.selectedDay;
    if (sel == null) return null;
    final key = DateTime(sel.year, sel.month, sel.day);
    for (var i = 0; i < widget.daily.length; i++) {
      final d = widget.daily[i].t.toLocal();
      if (DateTime(d.year, d.month, d.day) == key) return i;
    }
    return null;
  }

  void _commitPending() {
    final i = _pendingSelectIndex;
    _pendingSelectIndex = null;
    if (i == null) return;
    final pts = widget.daily;
    if (i < 0 || i >= pts.length) return;
    widget.onSelectDay?.call(pts[i].t);
  }

  Widget _body(
    BuildContext context,
    double growFactor,
    bool landscape,
    bool dense,
  ) {
    final pts = widget.daily;
    final accentColor = widget.accentColor;
    final selectedIndex = _selectedIndex();
    final maxVal = pts.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 1.0;
    final barWidth = (pts.length > 12 ? 8.0 : 10.0).clamp(4.0, 14.0);
    final topHighlight = Color.lerp(accentColor, Colors.white, 0.35) ?? accentColor;
    final xIndices = ChartAxisGranularity.evenlySpacedIndices(
      pts.length,
      landscape
          ? ChartAxisGranularity.landscapeXLabelCount
          : ChartAxisGranularity.portraitXLabelCount,
    );
    final showAt = xIndices.toSet();
    final showScatter = widget.eventType == EventCatalogEventType.one;

    final scatterSpots = <ScatterSpot>[];
    if (showScatter) {
      final byDayIndex = <int, List<TrendPoint>>{};
      for (final p in widget.raw) {
        final l = p.t.toLocal();
        final day = DateTime(l.year, l.month, l.day);
        for (var i = 0; i < pts.length; i++) {
          final d = pts[i].t.toLocal();
          if (DateTime(d.year, d.month, d.day) == day) {
            (byDayIndex[i] ??= []).add(p);
            break;
          }
        }
      }
      final deep = Color.lerp(accentColor, Colors.black, 0.35) ?? accentColor;
      for (final e in byDayIndex.entries) {
        final dayTotal = pts[e.key].value;
        if (dayTotal <= 0) continue;
        for (final p in e.value) {
          final y = timeOfDayFraction(p.t) * dayTotal * growFactor;
          scatterSpots.add(
            ScatterSpot(
              e.key.toDouble(),
              y,
              dotPainter: FlDotCirclePainter(
                radius: 3.2,
                color: deep.withValues(alpha: 0.92),
                strokeWidth: 0,
              ),
            ),
          );
        }
      }
    }

    final barGroups = List<BarChartGroupData>.generate(pts.length, (i) {
      final selected = i == selectedIndex;
      return BarChartGroupData(
        x: i,
        showingTooltipIndicators: selected && pts[i].value > 0 ? [0] : const [],
        barRods: [
          BarChartRodData(
            toY: pts[i].value * growFactor,
            width: barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            borderSide: selected
                ? BorderSide(color: Colors.white.withValues(alpha: 0.85), width: 1.5)
                : BorderSide.none,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                accentColor.withValues(alpha: selected ? 0.55 : 0.45),
                accentColor.withValues(alpha: selected ? 0.95 : 0.88),
                topHighlight.withValues(alpha: 0.95),
              ],
            ),
          ),
        ],
      );
    });

    final axisSide = BorderSide(color: accentColor.withValues(alpha: 0.85), width: 1.2);

    // Y 顶固定单位（时长 / unit|量 / 次）。
    final yUnit = trendYAxisUnitLabel(
      eventType: widget.eventType,
      unit: widget.unit,
    );

    final chart = BarChart(
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
              context: context,
              landscape: landscape,
              dense: dense,
              showAtIndices: showAt,
              labelForIndex: (i) {
                if (i < 0 || i >= pts.length) return '';
                return TrendNDayBarChart._dateFmt.format(pts[i].t.toLocal());
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: ChartAxisGranularity.glassLeftTitles(
              context: context,
              maxY: maxY,
              landscape: landscape,
              dense: dense,
              forceYLabelCount: 3,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(left: axisSide, bottom: axisSide),
        ),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            final group = response?.spot?.touchedBarGroup;
            if (group != null) {
              _pendingSelectIndex = group.x;
            }
            if (event is FlTapUpEvent || event is FlPanEndEvent) {
              _commitPending();
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 6,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final i = group.x;
              if (i < 0 || i >= pts.length) return null;
              final v = pts[i].value;
              if (v <= 0) return null;
              return BarTooltipItem(
                formatTrendMetricLabel(
                  value: v,
                  eventType: widget.eventType,
                  unit: widget.unit,
                ),
                TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
      ),
    );

    Widget layered = chart;
    if (showScatter && scatterSpots.isNotEmpty) {
      layered = Stack(
        fit: StackFit.expand,
        children: [
          chart,
          IgnorePointer(
            child: ScatterChart(
              ScatterChartData(
                minX: -0.5,
                maxX: pts.length - 0.5,
                minY: 0,
                maxY: maxY,
                scatterSpots: scatterSpots,
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: dense ? 30 : (landscape ? 36 : 40),
                      getTitlesWidget: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: dense ? 22 : 28,
                      getTitlesWidget: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                scatterTouchData: ScatterTouchData(enabled: false),
              ),
            ),
          ),
        ],
      );
    }

    return wrapTrendChartWithYAxisUnit(
      context: context,
      chart: layered,
      unitLabel: yUnit,
      landscape: landscape,
      dense: dense,
    );
  }
}
