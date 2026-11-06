import 'package:flutter/material.dart';

import '../data/event_definition.dart';
import '../data/history_record_metric.dart';
import '../theme/app_visual_tokens.dart';
import 'home_day_summary_chips.dart';

/// 按日吸顶：日期 + 汇总 chip（默认一行，可展开）+ 测高回写 extent。
class HomeHistoryDateHeader extends StatefulWidget {
  const HomeHistoryDateHeader({
    super.key,
    required this.label,
    this.totals = const [],
    this.catalog = const [],
    this.expanded = false,
    this.onToggleExpand,
    this.onChipTap,
    this.onMetrics,
  });

  final String label;
  final List<TodayEventTotal> totals;
  final List<EventDefinition> catalog;
  final bool expanded;
  final VoidCallback? onToggleExpand;
  final void Function(TodayEventTotal total, EventDefinition? event)? onChipTap;
  /// 当前展示态实测高度 + 是否需要折叠控件。
  final void Function({required double extent, required bool needsFold})?
      onMetrics;

  static const double labelHeight = 28;
  static const double labelHorizontalPadding = 12;
  static const double bottomPadding = 6;
  /// 收起态 chip 区最大高度（一行）。
  static const double oneRowChipMaxHeight = 28;
  static const double chipsTopGap = 4;

  /// 无 chip 时仅日期行高度。
  static double extentDateOnly() => labelHeight + bottomPadding;

  /// 由实测全高 chip 推算当前展示态 extent（不依赖吸顶裁切约束）。
  /// 收起态固定一行槽位，避免 chip 实高略超测高导致 Column 溢 1–2px。
  static double extentFromFullChipsHeight({
    required double fullChipsHeight,
    required bool expanded,
  }) {
    final chipH = expanded
        ? fullChipsHeight
        : oneRowChipMaxHeight;
    // +2：文本缩放 / InkWell 偶发舍入余量。
    return labelHeight + chipsTopGap + chipH + bottomPadding + 2;
  }

  @override
  State<HomeHistoryDateHeader> createState() => _HomeHistoryDateHeaderState();
}

class _HomeHistoryDateHeaderState extends State<HomeHistoryDateHeader> {
  final _fullChipsKey = GlobalKey();
  var _needsFold = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  void didUpdateWidget(HomeHistoryDateHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totals != widget.totals ||
        oldWidget.expanded != widget.expanded ||
        oldWidget.label != widget.label) {
      WidgetsBinding.instance.addPostFrameCallback(_measure);
    }
  }

  void _measure(Duration _) {
    if (!mounted) return;
    if (widget.totals.isEmpty) {
      if (_needsFold) setState(() => _needsFold = false);
      widget.onMetrics?.call(
        extent: HomeHistoryDateHeader.extentDateOnly(),
        needsFold: false,
      );
      return;
    }
    final fullBox =
        _fullChipsKey.currentContext?.findRenderObject() as RenderBox?;
    if (fullBox == null || !fullBox.hasSize) return;
    final fullH = fullBox.size.height;
    final needsFold = fullH > HomeHistoryDateHeader.oneRowChipMaxHeight + 1;
    final extent = HomeHistoryDateHeader.extentFromFullChipsHeight(
      fullChipsHeight: fullH,
      expanded: widget.expanded,
    );
    if (needsFold != _needsFold) {
      setState(() => _needsFold = needsFold);
    }
    widget.onMetrics?.call(extent: extent, needsFold: needsFold);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final bg = tokens?.shellColor ?? Theme.of(context).scaffoldBackgroundColor;
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.primary;
    final showToggle = _needsFold && widget.onToggleExpand != null;

    Widget? buildChips() {
      if (widget.totals.isEmpty) return null;
      return HomeDaySummaryChips(
        totals: widget.totals,
        catalog: widget.catalog,
        onChipTap: widget.onChipTap,
      );
    }

    final measureChips = buildChips();
    final visibleChips = buildChips();

    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          HomeHistoryDateHeader.labelHorizontalPadding,
          0,
          HomeHistoryDateHeader.labelHorizontalPadding,
          HomeHistoryDateHeader.bottomPadding,
        ),
        // Stack：测高芯片不进 Column，避免占位/约束干扰。
        child: Stack(
          children: [
            if (measureChips != null)
              Offstage(
                offstage: true,
                child: KeyedSubtree(key: _fullChipsKey, child: measureChips),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: HomeHistoryDateHeader.labelHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.label,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: fg,
                                  ),
                        ),
                      ),
                      if (showToggle)
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: widget.onToggleExpand,
                          child: Text(widget.expanded ? '收起' : '展开'),
                        ),
                    ],
                  ),
                ),
                if (visibleChips != null) ...[
                  const SizedBox(height: HomeHistoryDateHeader.chipsTopGap),
                  // 收起：固定一行槽 + 裁切，高度与 extent 公式一致。
                  if (!widget.expanded)
                    SizedBox(
                      height: HomeHistoryDateHeader.oneRowChipMaxHeight,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: visibleChips,
                        ),
                      ),
                    )
                  else
                    visibleChips,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeHistoryDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  HomeHistoryDateHeaderDelegate({
    required this.label,
    required this.extent,
    this.totals = const [],
    this.catalog = const [],
    this.expanded = false,
    this.onToggleExpand,
    this.onChipTap,
    this.onMetrics,
  });

  final String label;
  final double extent;
  final List<TodayEventTotal> totals;
  final List<EventDefinition> catalog;
  final bool expanded;
  final VoidCallback? onToggleExpand;
  final void Function(TodayEventTotal total, EventDefinition? event)? onChipTap;
  final void Function({required double extent, required bool needsFold})?
      onMetrics;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: extent,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          child: HomeHistoryDateHeader(
            key: ValueKey<String>('sticky-$label'),
            label: label,
            totals: totals,
            catalog: catalog,
            expanded: expanded,
            onToggleExpand: onToggleExpand,
            onChipTap: onChipTap,
            onMetrics: onMetrics,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant HomeHistoryDateHeaderDelegate oldDelegate) {
    return oldDelegate.label != label ||
        oldDelegate.extent != extent ||
        oldDelegate.totals != totals ||
        oldDelegate.catalog != catalog ||
        oldDelegate.expanded != expanded ||
        oldDelegate.onToggleExpand != onToggleExpand ||
        oldDelegate.onChipTap != onChipTap ||
        oldDelegate.onMetrics != onMetrics;
  }
}
