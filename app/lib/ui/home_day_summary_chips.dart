import 'package:flutter/material.dart';

import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_record_metric.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'event_logo.dart';

/// 按日汇总 chip 行（logo + 品牌色）；供日期吸顶复用。
class HomeDaySummaryChips extends StatelessWidget {
  const HomeDaySummaryChips({
    super.key,
    required this.totals,
    required this.catalog,
    this.onChipTap,
    this.spacing = 6,
    this.runSpacing = 6,
  });

  final List<TodayEventTotal> totals;
  final List<EventDefinition> catalog;
  final void Function(TodayEventTotal total, EventDefinition? event)? onChipTap;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final t in totals)
          _DaySummaryChip(
            total: t,
            event: lookupEventById(catalog, t.eventId),
            onTap: onChipTap == null
                ? null
                : () => onChipTap!(
                      t,
                      lookupEventById(catalog, t.eventId),
                    ),
          ),
      ],
    );
  }
}

class _DaySummaryChip extends StatelessWidget {
  const _DaySummaryChip({
    required this.total,
    required this.event,
    this.onTap,
  });

  final TodayEventTotal total;
  final EventDefinition? event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final accent = resolveEventColor(context, event);
    final labelStyle = TextStyle(
      fontSize: 12,
      height: 1.2,
      color: AppColor.textOnSurface(context),
      fontWeight: FontWeight.w500,
    );
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.14),
          tokens?.pillBackground ?? accent.withValues(alpha: 0.12),
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.4),
              tokens?.pillBorder ?? accent.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EventLogo(definition: event, size: 14),
          const SizedBox(width: 4),
          Text(formatTodayTotalChipLabel(total), style: labelStyle),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: chip,
      ),
    );
  }
}

/// 估算吸顶高度（日期 + chip 折行），避免首帧 extent=0。
double estimateHomeDayStickyExtent({
  required int chipCount,
  required double maxWidth,
}) {
  const dateH = 28.0;
  const bottomPad = 6.0;
  if (chipCount <= 0) return dateH + bottomPad;
  const chipH = 28.0;
  const runSpacing = 6.0;
  const hPad = 24.0;
  const avgChipW = 96.0;
  final usable = (maxWidth - hPad).clamp(80.0, 4000.0);
  final perRow = (usable / avgChipW).floor().clamp(1, 20);
  final rows = ((chipCount + perRow - 1) / perRow).ceil();
  // +4 余量，减轻估短导致裁切。
  return dateH + 4 + rows * chipH + (rows - 1) * runSpacing + bottomPad + 4;
}
