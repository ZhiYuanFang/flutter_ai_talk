import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/history_record_metric.dart';
import '../data/models.dart';
import 'event_logo.dart';
import 'home_history_edit_glass_panel.dart';
import 'trend_day_detail_chart.dart';
import 'widgets/app_glass_overlay.dart';

/// 按日汇总 chip：玻璃 Sheet + 单日 [TrendDayDetailChart]（本地快照）。
Future<void> showHomeDaySummaryChartSheet(
  BuildContext context, {
  required DateTime dayLocal,
  required TodayEventTotal total,
  required EventDefinition? event,
  required List<HistoryRecord> historyItems,
}) {
  final size = MediaQuery.sizeOf(context);
  final landscape = size.width > size.height;
  final maxHeightFraction = landscape ? 0.92 : 0.58;
  final accent = resolveEventColor(context, event);
  return showGlassAdaptiveBottomSheet<void>(
    context: context,
    eventAccent: accent,
    maxHeightFraction: maxHeightFraction,
    horizontalPadding: 0,
    wrapInGlassPanel: false,
    scrollable: false,
    bodyBuilder: (ctx) => _HomeDaySummaryChartSheetBody(
      dayLocal: dayLocal,
      total: total,
      event: event,
      historyItems: historyItems,
    ),
  );
}

class _HomeDaySummaryChartSheetBody extends StatelessWidget {
  const _HomeDaySummaryChartSheetBody({
    required this.dayLocal,
    required this.total,
    required this.event,
    required this.historyItems,
  });

  final DateTime dayLocal;
  final TodayEventTotal total;
  final EventDefinition? event;
  final List<HistoryRecord> historyItems;

  @override
  Widget build(BuildContext context) {
    final accent = resolveEventColor(context, event);
    final glassText = historyEditGlassTextColor(context);
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final maxH = landscape ? size.height * 0.92 : size.height * 0.58;
    final logoSize = landscape ? 24.0 : 40.0;
    final glassPadding = landscape
        ? const EdgeInsets.fromLTRB(14, 10, 14, 8)
        : null;
    final nowLocal = DateTime.now().toLocal();
    final dayTitle = formatHistoryDaySectionLabel(dayLocal, nowLocal);
    final raw = trendPointsForHomeDayEvent(
      items: historyItems,
      dayLocal: dayLocal,
      eventId: total.eventId,
    );

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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: EventLogo(definition: event, size: logoSize),
                      ),
                      const SizedBox(height: 8),
                      // 事件名 · 日文案（日更小、同行居中）。
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: total.eventName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: glassText,
                              ),
                            ),
                            TextSpan(
                              text: ' · ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: glassText.withValues(alpha: 0.75),
                              ),
                            ),
                            TextSpan(
                              text: dayTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: glassText.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TrendDayDetailChart(
                          dayLocal: dayLocal,
                          rawForDay: raw,
                          accentColor: accent,
                          eventType: event?.parsedEventType,
                          unit: total.unit.isEmpty ? event?.unit : total.unit,
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
