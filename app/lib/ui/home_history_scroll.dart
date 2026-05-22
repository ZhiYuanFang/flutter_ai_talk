import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/home_history_list_entries.dart';
import '../data/models.dart';
import 'home_history_date_header.dart';
import 'home_history_timeline_tile.dart';

/// 主页历史区：按日分块 + 日期吸顶（顶部）+ 记录行仅 `HH:mm`；最新记录在底部。
class HomeHistoryScroll extends StatefulWidget {
  const HomeHistoryScroll({
    super.key,
    required this.itemsAsc,
    required this.eventCatalog,
    required this.onRecordTap,
  });

  /// 时间升序（旧→新）。
  final List<HistoryRecord> itemsAsc;
  final List<EventDefinition> eventCatalog;
  final void Function(HistoryRecord record) onRecordTap;

  @override
  State<HomeHistoryScroll> createState() => _HomeHistoryScrollState();
}

class _HomeHistoryScrollState extends State<HomeHistoryScroll> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(HomeHistoryScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lenChanged = oldWidget.itemsAsc.length != widget.itemsAsc.length;
    final lastChanged = oldWidget.itemsAsc.isEmpty != widget.itemsAsc.isEmpty ||
        (widget.itemsAsc.isNotEmpty &&
            oldWidget.itemsAsc.last.id != widget.itemsAsc.last.id);
    if (lenChanged || lastChanged) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    void tryJump() {
      if (!_controller.hasClients) return;
      final pos = _controller.position;
      pos.jumpTo(pos.maxScrollExtent);
    }

    tryJump();
    // 列表高度可能在首帧后才确定，再滚一次以保证贴底。
    SchedulerBinding.instance.addPostFrameCallback((_) => tryJump());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 日块：旧→新（今天在列表底部）；`reverse: true` 时 pinned 会贴底而非吸顶，故用正向滚动。
    final groups = buildHomeHistoryDayGroups(widget.itemsAsc).reversed.toList();
    final total = widget.itemsAsc.length;
    var recordIndex = 0;

    const recordHorizontalPadding = EdgeInsets.symmetric(horizontal: 12);

    return CustomScrollView(
      controller: _controller,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 2, bottom: 6),
          sliver: SliverMainAxisGroup(
            slivers: [
              for (final g in groups)
                SliverMainAxisGroup(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: HomeHistoryDateHeaderDelegate(label: g.dayLabel),
                    ),
                    SliverPadding(
                      padding: recordHorizontalPadding,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final records = g.recordsOldestFirst;
                            final record = records[i];
                            final fromBottom = total - 1 - recordIndex;
                            recordIndex++;
                            return HomeHistoryTimelineTile(
                              display: historyHomeRowDisplay(record),
                              fromBottom: fromBottom,
                              event: lookupEventForRecord(widget.eventCatalog, record),
                              onTap: () => widget.onRecordTap(record),
                            );
                          },
                          childCount: g.recordsOldestFirst.length,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
