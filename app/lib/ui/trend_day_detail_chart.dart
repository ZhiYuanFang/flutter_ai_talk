import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/event_definition.dart';
import '../data/models.dart';
import 'chart_axis_granularity.dart';
import 'home_history_edit_glass_panel.dart';
import 'trend_metric_format.dart';

/// 某日详图：量/时稀疏柱（X 轴 HH:mm、柱顶量）；计次时间轴；无数据空坐标。
class TrendDayDetailChart extends StatelessWidget {
  const TrendDayDetailChart({
    super.key,
    required this.dayLocal,
    required this.rawForDay,
    required this.accentColor,
    required this.eventType,
    this.unit,
  });

  final DateTime dayLocal;
  final List<TrendPoint> rawForDay;
  final Color accentColor;
  final EventCatalogEventType? eventType;
  final String? unit;

  static final _timeFmt = DateFormat('HH:mm');

  /// 有效样本：量值大于 0。
  static List<TrendPoint> positiveSamples(List<TrendPoint> raw) {
    final out = raw.where((p) => p.value > 0).toList()
      ..sort((a, b) => a.t.compareTo(b.t));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final isOnce = eventType == EventCatalogEventType.one;
    final samples = positiveSamples(rawForDay);
    if (isOnce) {
      return _CountDayTimeline(
        occurrences: samples.isEmpty ? const [] : samples,
        accentColor: accentColor,
      );
    }
    if (samples.isEmpty) {
      return _EmptyDayBarChart(
        accentColor: accentColor,
        eventType: eventType,
        unit: unit,
      );
    }
    return _DaySparseBarChart(
      samples: samples,
      accentColor: accentColor,
      eventType: eventType,
      unit: unit,
    );
  }
}

/// 无样本：空柱坐标（不画 24 零柱、无幽灵折线）。
class _EmptyDayBarChart extends StatelessWidget {
  const _EmptyDayBarChart({
    required this.accentColor,
    required this.eventType,
    this.unit,
  });

  final Color accentColor;
  final EventCatalogEventType? eventType;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final dense = landscape;
    const maxY = 10.0;
    final axisSide =
        BorderSide(color: accentColor.withValues(alpha: 0.85), width: 1.2);
    final yUnit = trendYAxisUnitLabel(eventType: eventType, unit: unit);

    return wrapTrendChartWithYAxisUnit(
      context: context,
      unitLabel: yUnit,
      landscape: landscape,
      dense: dense,
      chart: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barGroups: const [],
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
          barTouchData: BarTouchData(enabled: false),
        ),
      ),
    );
  }
}

/// 一样本一柱；X 轴 HH:mm；柱顶量值；不强制 24 整点。
class _DaySparseBarChart extends StatelessWidget {
  const _DaySparseBarChart({
    required this.samples,
    required this.accentColor,
    required this.eventType,
    this.unit,
  });

  final List<TrendPoint> samples;
  final Color accentColor;
  final EventCatalogEventType? eventType;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final dense = landscape;
    final maxVal =
        samples.map((p) => p.value).fold(0.0, (a, b) => a > b ? a : b);
    // 柱顶量标占空。
    final maxY = maxVal > 0 ? maxVal * 1.35 : 10.0;
    final axisSide =
        BorderSide(color: accentColor.withValues(alpha: 0.85), width: 1.2);
    final yUnit = trendYAxisUnitLabel(eventType: eventType, unit: unit);
    final n = samples.length;
    final rodWidth = n <= 4 ? 18.0 : (n <= 8 ? 14.0 : 10.0);
    // 每柱都标时刻（不强制 24 整点桶）。
    final showAt = {for (var i = 0; i < n; i++) i};

    final groups = List<BarChartGroupData>.generate(n, (i) {
      final v = samples[i].value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: v,
            width: rodWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            color: accentColor,
          ),
        ],
        // 永久显示柱顶量值。
        showingTooltipIndicators: const [0],
      );
    });

    return wrapTrendChartWithYAxisUnit(
      context: context,
      unitLabel: yUnit,
      landscape: landscape,
      dense: dense,
      chart: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: n > 12 ? 4 : 8,
          barGroups: groups,
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: ChartAxisGranularity.glassBottomTitles(
                context: context,
                landscape: landscape,
                dense: dense,
                showAtIndices: showAt,
                labelForIndex: (i) {
                  if (i < 0 || i >= n) return '';
                  return TrendDayDetailChart._timeFmt
                      .format(samples[i].t.toLocal());
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
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 4,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= n) return null;
                final p = samples[groupIndex];
                return BarTooltipItem(
                  formatTrendMetricLabel(
                    value: p.value,
                    eventType: eventType,
                    unit: unit,
                  ),
                  TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CountDayTimeline extends StatelessWidget {
  const _CountDayTimeline({
    required this.occurrences,
    required this.accentColor,
  });

  final List<TrendPoint> occurrences;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CountTimelinePainter(
        occurrences: occurrences,
        accentColor: accentColor,
        labelColor: historyEditGlassLabelColor(context),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CountTimelinePainter extends CustomPainter {
  _CountTimelinePainter({
    required this.occurrences,
    required this.accentColor,
    required this.labelColor,
  });

  final List<TrendPoint> occurrences;
  final Color accentColor;
  final Color labelColor;

  static const _bands = [
    (0.0, 6.0),
    (6.0, 12.0),
    (12.0, 18.0),
    (18.0, 24.0),
  ];

  static const _stemLen = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final padL = 12.0;
    final padR = 12.0;
    final usable = size.width - padL - padR;
    if (usable <= 0) return;

    final bandTop = 10.0;
    final bandBottom = size.height * 0.58;
    final bandCenterY = (bandTop + bandBottom) / 2;

    final bandBases = [
      const Color(0xFFE8ECF4),
      const Color(0xFFF4EDE4),
      const Color(0xFFE8F0E8),
      const Color(0xFFEFE8F4),
    ];
    for (var i = 0; i < _bands.length; i++) {
      final b = _bands[i];
      final left = padL + (b.$1 / 24) * usable;
      final right = padL + (b.$2 / 24) * usable;
      final fill =
          Color.lerp(bandBases[i], accentColor, 0.22)!.withValues(alpha: 0.14);
      canvas.drawRect(
        Rect.fromLTRB(left, bandTop, right, bandBottom),
        Paint()..color = fill,
      );
    }

    final tickY = bandBottom + 10;
    final axisPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.75)
      ..strokeWidth = 1.2;
    canvas.drawLine(
        Offset(padL, tickY), Offset(padL + usable, tickY), axisPaint);

    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (final h in [0, 6, 12, 18, 24]) {
      final x = padL + (h / 24) * usable;
      canvas.drawLine(Offset(x, tickY), Offset(x, tickY + 4), axisPaint);
      tp.text = TextSpan(
        text: h == 24 ? '24:00' : '${h.toString().padLeft(2, '0')}:00',
        style: TextStyle(fontSize: 9, color: labelColor),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, tickY + 8));
    }

    final sorted = [...occurrences]..sort((a, b) => a.t.compareTo(b.t));
    final deep = Color.lerp(accentColor, Colors.black, 0.28) ?? accentColor;
    final stem = Paint()
      ..color = deep.withValues(alpha: 0.85)
      ..strokeWidth = 1;

    for (var i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      final frac = timeOfDayFraction(p.t);
      final x = padL + frac * usable;
      canvas.drawCircle(Offset(x, bandCenterY), 4, Paint()..color = deep);

      final below = i.isEven;
      final label = TrendDayDetailChart._timeFmt.format(p.t.toLocal());
      tp.text = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      );
      tp.layout();

      if (below) {
        final stemEnd = bandCenterY + 4 + _stemLen;
        canvas.drawLine(Offset(x, bandCenterY + 4), Offset(x, stemEnd), stem);
        final labelTop = math.min(stemEnd + 2, bandBottom - tp.height - 2);
        tp.paint(canvas, Offset(x - tp.width / 2, labelTop));
      } else {
        final stemEnd = bandCenterY - 4 - _stemLen;
        canvas.drawLine(Offset(x, bandCenterY - 4), Offset(x, stemEnd), stem);
        final labelTop = math.max(stemEnd - tp.height - 2, bandTop + 2);
        tp.paint(canvas, Offset(x - tp.width / 2, labelTop));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CountTimelinePainter oldDelegate) {
    return oldDelegate.occurrences != occurrences ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.labelColor != labelColor;
  }
}
