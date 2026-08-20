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

/// 某日详图：计时/计数折线；计次时间轴；无数据时空坐标（折线）或空时间轴。
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

  bool get _hasData =>
      rawForDay.any((p) => p.value > 0) || rawForDay.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isOnce = eventType == EventCatalogEventType.one;
    if (!_hasData) {
      return isOnce
          ? _CountDayTimeline(occurrences: const [], accentColor: accentColor)
          : _EmptyDayLineChart(
              accentColor: accentColor,
              eventType: eventType,
              unit: unit,
            );
    }
    if (isOnce) {
      // 计次时间轴：不加数值 Y 单位文案。
      return _CountDayTimeline(
        occurrences: rawForDay,
        accentColor: accentColor,
      );
    }
    return _DayLineChartInteractive(
      dayLocal: dayLocal,
      rawForDay: rawForDay,
      accentColor: accentColor,
      eventType: eventType,
      unit: unit,
    );
  }
}

/// 无数据：空折线坐标，x 0–24、y 0–10，无幽灵折线。
class _EmptyDayLineChart extends StatelessWidget {
  const _EmptyDayLineChart({
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
    final marks = landscape
        ? ChartAxisGranularity.landscapeXHourMarks
        : ChartAxisGranularity.portraitXHourMarks;
    final axisSide =
        BorderSide(color: accentColor.withValues(alpha: 0.85), width: 1.2);
    final yUnit = trendYAxisUnitLabel(eventType: eventType, unit: unit);

    return wrapTrendChartWithYAxisUnit(
      context: context,
      unitLabel: yUnit,
      landscape: landscape,
      dense: dense,
      chart: LineChart(
        LineChartData(
          minX: 0,
          maxX: 23,
          minY: 0,
          maxY: maxY,
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
                showAtIndices: marks.toSet(),
                labelForIndex: (i) => i == 23
                    ? ChartAxisGranularity.hourLabel(24)
                    : ChartAxisGranularity.hourLabel(i),
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
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: const [],
        ),
      ),
    );
  }
}

List<TrendPoint> _fillHourlyToday(List<TrendPoint> raw, DateTime now) {
  final n = now.toLocal();
  final dayStart = DateTime(n.year, n.month, n.day);
  final endHour = DateTime(n.year, n.month, n.day, n.hour);
  final byHour = <DateTime, double>{};
  for (final p in raw) {
    final l = p.t.toLocal();
    if (l.isBefore(dayStart) || l.isAfter(n)) continue;
    final k = DateTime(l.year, l.month, l.day, l.hour);
    byHour[k] = (byHour[k] ?? 0) + p.value;
  }
  final out = <TrendPoint>[];
  for (var h = dayStart;
      !h.isAfter(endHour);
      h = h.add(const Duration(hours: 1))) {
    out.add(TrendPoint(t: h, value: byHour[h] ?? 0));
  }
  return out;
}

List<TrendPoint> _fillHourlyFull(List<TrendPoint> raw, DateTime day) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final byHour = <DateTime, double>{};
  final next = dayStart.add(const Duration(days: 1));
  for (final p in raw) {
    final l = p.t.toLocal();
    if (l.isBefore(dayStart) || !l.isBefore(next)) continue;
    final k = DateTime(l.year, l.month, l.day, l.hour);
    byHour[k] = (byHour[k] ?? 0) + p.value;
  }
  return List.generate(24, (h) {
    final bucket = dayStart.add(Duration(hours: h));
    return TrendPoint(t: bucket, value: byHour[bucket] ?? 0);
  });
}

/// 全部非零小时点放入同一折线；支持选中竖线与时间。
class _DayLineChartInteractive extends StatefulWidget {
  const _DayLineChartInteractive({
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

  @override
  State<_DayLineChartInteractive> createState() =>
      _DayLineChartInteractiveState();
}

class _DayLineChartInteractiveState extends State<_DayLineChartInteractive> {
  /// 选中点在 [spots] 中的下标；null 表示尚无初始化。
  int? _selectedSpotIndex;

  List<TrendPoint> _hourlyFor(DateTime dayLocal, List<TrendPoint> raw) {
    final today = DateTime.now().toLocal();
    final todayDay = DateTime(today.year, today.month, today.day);
    final day = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    if (day == todayDay) return _fillHourlyToday(raw, today);
    return _fillHourlyFull(raw, day);
  }

  /// 仅非零点，按小时索引一条线（可斜跨空隙，不经 y=0）。
  static List<FlSpot> nonZeroSpots(List<TrendPoint> hourly) {
    final out = <FlSpot>[];
    for (var i = 0; i < hourly.length; i++) {
      if (hourly[i].value > 0) {
        out.add(FlSpot(i.toDouble(), hourly[i].value));
      }
    }
    return out;
  }

  @override
  void didUpdateWidget(covariant _DayLineChartInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayLocal != widget.dayLocal ||
        oldWidget.rawForDay != widget.rawForDay) {
      _selectedSpotIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final dense = landscape;
    final hourly = _hourlyFor(widget.dayLocal, widget.rawForDay);
    final spots = nonZeroSpots(hourly);
    final maxVal = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.2 : 10.0;
    final maxX = math.max(hourly.length - 1, 23).toDouble();
    final marks = landscape
        ? ChartAxisGranularity.landscapeXHourMarks
        : ChartAxisGranularity.portraitXHourMarks;
    final accent = widget.accentColor;
    final axisSide =
        BorderSide(color: accent.withValues(alpha: 0.85), width: 1.2);
    final gridColor = accent.withValues(alpha: 0.12);

    // 默认选中最后一个非零点（不在 build 里 setState）。
    final selRaw = _selectedSpotIndex;
    final sel = spots.isEmpty
        ? null
        : (selRaw == null
            ? spots.length - 1
            : selRaw.clamp(0, spots.length - 1));
    final selectedSpot =
        (sel != null && sel >= 0 && sel < spots.length) ? spots[sel] : null;

    final leftReserved = dense ? 30.0 : (landscape ? 36.0 : 40.0);
    final bottomReserved = dense ? 22.0 : 28.0;
    final yUnit = trendYAxisUnitLabel(
      eventType: widget.eventType,
      unit: widget.unit,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final plotW = constraints.maxWidth - leftReserved;
        final plotH = constraints.maxHeight - bottomReserved;
        // 与 LineChart 的 maxX 对齐，避免单点时标签横轴漂移。
        final xSpan = maxX <= 0 ? 1.0 : maxX;

        // 选中点旁时间+量标（非选中点不叠永久量标，避免与触控抢视觉）。
        final overlayLabels = <Widget>[];
        if (selectedSpot != null) {
          final hour = selectedSpot.x.round();
          final timeLabel = ChartAxisGranularity.hourLabel(hour);
          final amount = formatTrendMetricLabel(
            value: selectedSpot.y,
            eventType: widget.eventType,
            unit: widget.unit,
          );
          final x = leftReserved + (selectedSpot.x / xSpan) * plotW;
          final y = plotH * (1 - (selectedSpot.y / maxY)) - 10;
          overlayLabels.add(
            Positioned(
              left: (x - 36).clamp(leftReserved, constraints.maxWidth - 72),
              top: (y - 28).clamp(0.0, plotH),
              width: 72,
              child: Text(
                '$timeLabel\n$amount',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          );
        }

        return wrapTrendChartWithYAxisUnit(
          context: context,
          unitLabel: yUnit,
          landscape: landscape,
          dense: dense,
          chart: Stack(
            fit: StackFit.expand,
            children: [
              LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: 0,
                  maxY: maxY,
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: ChartAxisGranularity.glassBottomTitles(
                        context: context,
                        landscape: landscape,
                        dense: dense,
                        showAtIndices: marks.where((i) => i <= maxX).toSet(),
                        labelForIndex: (i) => i == 23
                            ? ChartAxisGranularity.hourLabel(24)
                            : ChartAxisGranularity.hourLabel(i),
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 1),
                  ),
                  lineBarsData: [
                    if (spots.isNotEmpty)
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        color: accent,
                        barWidth: 2.4,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            final isSel = index == sel;
                            return FlDotCirclePainter(
                              radius: isSel ? 5 : 3.5,
                              color: accent,
                              strokeWidth: isSel ? 1.8 : 1.2,
                              strokeColor: Colors.white.withValues(alpha: 0.75),
                            );
                          },
                        ),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchSpotThreshold: 22,
                    // 选中态不画竖线，仅放大触点圆。
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((i) {
                        return TouchedSpotIndicatorData(
                          const FlLine(
                              color: Colors.transparent, strokeWidth: 0),
                          FlDotData(
                            show: true,
                            getDotPainter: (s, p, b, idx) => FlDotCirclePainter(
                              radius: 5.5,
                              color: accent,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 0,
                      getTooltipItems: (touchedSpots) => List.filled(
                        touchedSpots.length,
                        null, // ← 每个位置都返回 null = 不显示任何 tooltip 内容
                      ),
                    ),
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions) return;
                      final spot = response?.lineBarSpots?.firstOrNull;
                      if (spot == null) return;
                      final idx = spot.spotIndex;
                      if (idx < 0 || idx >= spots.length) return;
                      if (_selectedSpotIndex != idx) {
                        setState(() => _selectedSpotIndex = idx);
                      }
                    },
                  ),
                ),
              ),
              ...overlayLabels,
            ],
          ),
        );
      },
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

    // 更浅的时段底：偏白混合 + 低透明。
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

    // 轴线 / 刻度：事件色。
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

      // 偶数先下、奇数再上。
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
