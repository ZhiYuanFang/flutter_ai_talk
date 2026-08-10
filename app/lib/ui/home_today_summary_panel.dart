import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_record_metric.dart';
import '../providers/event_catalog_notifier.dart';
import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';
import 'event_logo.dart';

/// 主页历史区上方：今日各事件总额；超过两行可折叠，点击展开。
/// 本变更仅展示；[onChipTap] 默认不接今昨小时 Sheet。
class HomeTodaySummaryPanel extends ConsumerStatefulWidget {
  const HomeTodaySummaryPanel({
    super.key,
    required this.totals,
    this.onChipTap,
  });

  final List<TodayEventTotal> totals;
  final void Function(TodayEventTotal total, EventDefinition? event)? onChipTap;

  @override
  ConsumerState<HomeTodaySummaryPanel> createState() =>
      _HomeTodaySummaryPanelState();
}

class _HomeTodaySummaryPanelState
    extends ConsumerState<HomeTodaySummaryPanel> {
  static const _twoRowMaxHeight = 60.0;
  static const _chipSpacing = 6.0;
  static const _chipRunSpacing = 6.0;

  final _measureKey = GlobalKey();
  var _expanded = false;
  var _needsFold = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureWrap);
  }

  @override
  void didUpdateWidget(HomeTodaySummaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totals != widget.totals) {
      WidgetsBinding.instance.addPostFrameCallback(_measureWrap);
    }
  }

  void _measureWrap(Duration _) {
    if (!mounted) return;
    final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final needs = box.size.height > _twoRowMaxHeight + 1;
    if (needs != _needsFold) {
      setState(() => _needsFold = needs);
    }
  }

  Widget _buildChips(List<EventDefinition> catalog) {
    return Wrap(
      spacing: _chipSpacing,
      runSpacing: _chipRunSpacing,
      children: [
        for (final t in widget.totals)
          _TodayChip(
            total: t,
            event: lookupEventById(catalog, t.eventId),
            onTap: widget.onChipTap == null
                ? null
                : () => widget.onChipTap!(
                      t,
                      lookupEventById(catalog, t.eventId),
                    ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totals.isEmpty) {
      return const SizedBox.shrink();
    }

    final catalog = ref.watch(eventCatalogProvider).items;
    final chips = _buildChips(catalog);
    final visibleChips = _expanded
        ? chips
        : ClipRect(
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _twoRowMaxHeight),
                child: chips,
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '今日汇总',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColor.textPrimary(context),
                    ),
              ),
              if (_needsFold) ...[
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? '收起' : '展开'),
                ),
              ],
            ],
          ),
          Stack(
            children: [
              Offstage(
                child: KeyedSubtree(key: _measureKey, child: chips),
              ),
              visibleChips,
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip({
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
