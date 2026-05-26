import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_definition.dart';
import '../data/history_hourly_dual_day.dart';
import '../data/history_record_metric.dart';
import '../data/models.dart';
import '../providers/repositories.dart';
import 'event_logo.dart';
import 'home_event_hourly_trend_chart.dart';
import 'home_history_edit_glass_panel.dart';

/// 今日 chip 点击：玻璃态 Sheet，今/昨小时双折线（先本地后 API）。
Future<void> showHomeEventHourlyTrendSheet(
  BuildContext context, {
  required TodayEventTotal total,
  required EventDefinition? event,
  required List<HistoryRecord> historyItems,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final landscape = size.width > size.height;
      final maxSheetH = size.height * (landscape ? 0.92 : 0.58);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetH),
          child: _HomeEventHourlyTrendSheetBody(
            total: total,
            event: event,
            historyItems: historyItems,
            ref: ref,
          ),
        ),
      );
    },
  );
}

class _HomeEventHourlyTrendSheetBody extends ConsumerStatefulWidget {
  const _HomeEventHourlyTrendSheetBody({
    required this.total,
    required this.event,
    required this.historyItems,
    required this.ref,
  });

  final TodayEventTotal total;
  final EventDefinition? event;
  final List<HistoryRecord> historyItems;
  final WidgetRef ref;

  @override
  ConsumerState<_HomeEventHourlyTrendSheetBody> createState() =>
      _HomeEventHourlyTrendSheetBodyState();
}

class _HomeEventHourlyTrendSheetBodyState extends ConsumerState<_HomeEventHourlyTrendSheetBody> {
  late HourlyDualDaySeries _series;
  var _apiRefreshing = false;

  @override
  void initState() {
    super.initState();
    _series = aggregateHourlyDualDayFromHistory(
      widget.historyItems,
      widget.total.eventId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshFromApi());
  }

  Future<void> _refreshFromApi() async {
    if (!mounted) return;
    setState(() => _apiRefreshing = true);
    final remote = await ref.read(trendsRepositoryProvider).loadPieceHourlyDualDay(
          widget.total.eventId,
        );
    if (!mounted) return;
    setState(() {
      _apiRefreshing = false;
      _series = remote;
    });
  }

  String get _yAxisHint =>
      widget.total.isDurationHours ? '纵轴：小时 (h)' : '纵轴：次数';

  double _sheetMaxHeight(Size size, bool landscape) {
    if (landscape) {
      return size.height * 0.92;
    }
    return size.height * 0.58;
  }

  @override
  Widget build(BuildContext context) {
    final accent = resolveEventColor(context, widget.event);
    final yesterdayColor = HomeEventHourlyTrendChart.yesterdaySeriesColor(accent);
    final glassText = historyEditGlassTextColor(context);
    final glassLabel = historyEditGlassLabelColor(context);
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final maxH = _sheetMaxHeight(size, landscape);
    final logoSize = landscape ? 24.0 : 40.0;
    final glassPadding = landscape
        ? const EdgeInsets.fromLTRB(14, 10, 14, 8)
        : null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: landscape ? 2 : 8,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sheetH = constraints.maxHeight.isFinite
                ? constraints.maxHeight.clamp(0.0, maxH)
                : maxH;
            return SizedBox(
              height: sheetH,
              child: Material(
                type: MaterialType.transparency,
                child: HistoryEditGlassPanel(
                  eventAccent: accent,
                  contentPadding: glassPadding,
                  onClose: () => Navigator.of(context).pop(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (landscape)
                        _LandscapeTrendHeader(
                          event: widget.event,
                          eventName: widget.total.eventName,
                          logoSize: logoSize,
                          accent: accent,
                          yesterdayColor: yesterdayColor,
                          glassText: glassText,
                          glassLabel: glassLabel,
                          yAxisHint: _yAxisHint,
                          apiRefreshing: _apiRefreshing,
                        )
                      else ...[
                        Center(child: EventLogo(definition: widget.event, size: logoSize)),
                        const SizedBox(height: 8),
                        Text(
                          widget.total.eventName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: glassText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegendDot(color: accent, label: '今日'),
                            const SizedBox(width: 20),
                            _LegendDot(
                              color: yesterdayColor,
                              label: '昨日',
                            ),
                            if (_apiRefreshing) ...[
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: glassLabel,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: HomeEventHourlyTrendChart(
                          series: _series,
                          accentColor: accent,
                          yAxisHint: _yAxisHint,
                          compactHeader: landscape,
                          denseAxes: landscape && sheetH < 280,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 横屏：Logo、事件名、图例、纵轴说明与加载指示单行排布，压低占用高度。
class _LandscapeTrendHeader extends StatelessWidget {
  const _LandscapeTrendHeader({
    required this.event,
    required this.eventName,
    required this.logoSize,
    required this.accent,
    required this.yesterdayColor,
    required this.glassText,
    required this.glassLabel,
    required this.yAxisHint,
    required this.apiRefreshing,
  });

  final EventDefinition? event;
  final String eventName;
  final double logoSize;
  final Color accent;
  final Color yesterdayColor;
  final Color glassText;
  final Color glassLabel;
  final String yAxisHint;
  final bool apiRefreshing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        EventLogo(definition: event, size: logoSize),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            eventName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: glassText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _LegendDot(color: accent, label: '今日', compact: true),
        const SizedBox(width: 8),
        _LegendDot(
          color: yesterdayColor,
          label: '昨日',
          compact: true,
        ),
        if (apiRefreshing) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: glassLabel,
            ),
          ),
        ],
        const SizedBox(width: 8),
        Flexible(
          flex: 1,
          child: Text(
            yAxisHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              color: glassLabel,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.compact = false,
  });

  final Color color;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dot = compact ? 7.0 : 10.0;
    final fontSize = compact ? 10.0 : 12.0;
    final gap = compact ? 4.0 : 6.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: gap),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.1,
            color: historyEditGlassTextColor(context),
          ),
        ),
      ],
    );
  }
}
