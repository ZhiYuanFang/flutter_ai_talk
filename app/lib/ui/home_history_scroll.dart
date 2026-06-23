import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_visual_tokens.dart';
import '../theme/theme_preset.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/history_line_format.dart';
import '../data/history_mapper.dart';
import '../data/home_history_list_entries.dart';
import '../data/models.dart';
import 'home_history_date_header.dart';
import 'home_history_day_timeline_links.dart';
import 'home_history_scroll_to_bottom_button.dart';
import 'home_history_timeline_tile.dart';

/// 历史按日记录卡片背景不透明度（按深浅主题区分）。
const kHistoryRecordsCardOpacityDark = 0.4;
const kHistoryRecordsCardOpacityLight = 0.99;

/// 主页历史区：按日分块 + 日期吸顶（顶部）+ 记录行仅 `HH:mm`；最新记录在底部。
class HomeHistoryScroll extends StatefulWidget {
  const HomeHistoryScroll({
    super.key,
    required this.itemsAsc,
    required this.eventCatalog,
    required this.onRecordTap,
    required this.onStopActiveTimer,
    this.stoppingRecordIds = const {},
    this.flyingRecordId,
    this.flyAnimationInProgress = false,
    this.onFollowLatestChanged,
    this.hasMore = false,
    this.loadingMore = false,
    this.onRefresh,
    this.onLoadMore,
  });

  /// 时间升序（旧→新）。
  final List<HistoryRecord> itemsAsc;
  final List<EventDefinition> eventCatalog;
  final void Function(HistoryRecord record) onRecordTap;
  final Future<bool> Function(HistoryRecord record) onStopActiveTimer;
  final Set<String> stoppingRecordIds;
  final String? flyingRecordId;
  final bool flyAnimationInProgress;
  final ValueChanged<bool>? onFollowLatestChanged;
  final bool hasMore;
  final bool loadingMore;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;

  @override
  State<HomeHistoryScroll> createState() => HomeHistoryScrollState();
}

class HomeHistoryScrollState extends State<HomeHistoryScroll> {
  final _controller = ScrollController();
  final _historyAreaKey = GlobalKey();
  final _tickNow = ValueNotifier<DateTime>(DateTime.now());
  final _showScrollToBottomButton = ValueNotifier<bool>(false);
  final Map<String, GlobalKey> _logoAnchorKeys = {};
  Timer? _activeTimingTick;
  Timer? _relativeAgoMinuteTick;
  bool _followLatest = true;
  bool _pendingFollowScroll = false;
  Offset? _lastHistoryAreaCenterGlobal;

  static const double followBottomThreshold = 96;
  static const double _bottomPullTriggerThreshold = 72;
  static const Duration _followScrollDuration = Duration(milliseconds: 220);

  double _bottomPullExtent = 0;
  bool _bottomRefreshing = false;

  bool get followLatest => _followLatest;

  Rect? get historyAreaGlobalBounds {
    final ctx = _historyAreaKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    final size = box.size;
    if (size.width < 8 || size.height < 8) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    final bounds = topLeft & size;
    if (!bounds.hasNaN && bounds.width >= 8 && bounds.height >= 8) {
      return bounds;
    }
    return null;
  }

  /// 历史区可视中心（global）；当前帧测不到时返回上次有效中心。
  Offset? get historyAreaCenterGlobal {
    final bounds = historyAreaGlobalBounds;
    if (bounds != null) {
      final center = bounds.center;
      _lastHistoryAreaCenterGlobal = center;
      return center;
    }
    return _lastHistoryAreaCenterGlobal;
  }

  GlobalKey? anchorKeyForRecord(String recordId) => _logoAnchorKeys[recordId];

  /// 飞行动画前滚到底并等待锚点进入历史区可视范围。
  Future<void> prepareFlyAnchorMeasure(String recordId) async {
    if (!mounted) return;
    scrollToBottom(force: true);
    for (var attempt = 0; attempt < 24; attempt++) {
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      if (_isFlyAnchorVisible(recordId) && isScrolledToBottom) return;
      if (attempt.isOdd) scrollToBottom(force: true);
    }
  }

  bool _isFlyAnchorVisible(String recordId) {
    final anchor = measureAnchorCenterForRecord(recordId);
    final bounds = historyAreaGlobalBounds;
    if (anchor == null || bounds == null) return false;
    return bounds.deflate(4).contains(anchor);
  }

  bool isFlyAnchorVisible(String recordId) => _isFlyAnchorVisible(recordId);

  /// 最新 record 对应 EventLogo 锚点的 global 中心；未布局时返回 null。
  Offset? measureAnchorCenterForRecord(String recordId) {
    final anchorKey = _logoAnchorKeys[recordId];
    final context = anchorKey?.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    if (box.size.width < 1 || box.size.height < 1) return null;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    if (!center.dx.isFinite || !center.dy.isFinite || center == Offset.zero) {
      return null;
    }
    return center;
  }

  bool get isScrolledToBottom {
    if (!_controller.hasClients) return false;
    final pos = _controller.position;
    if (!pos.maxScrollExtent.isFinite) return false;
    return pos.maxScrollExtent - pos.pixels <= 1;
  }

  bool get _isNearBottom {
    if (!_controller.hasClients) return _followLatest;
    final pos = _controller.position;
    if (!pos.maxScrollExtent.isFinite) return _followLatest;
    return pos.maxScrollExtent - pos.pixels <= followBottomThreshold;
  }

  /// 底部输入区高度变化后（如切换输入模式），跟底或近底时重锚至最新记录。
  void reanchorAfterViewportChange({bool animate = true}) {
    if (widget.itemsAsc.isEmpty) return;
    if (!_followLatest && !_isNearBottom) return;
    scrollToBottom(force: true, animate: animate);
  }

  static const double _loadMoreTopThreshold = 80;

  bool _isNearBottomMetrics(ScrollMetrics metrics) {
    if (!metrics.maxScrollExtent.isFinite) return false;
    return metrics.maxScrollExtent - metrics.pixels <= followBottomThreshold;
  }

  void _resetBottomPull() {
    if (_bottomPullExtent == 0) return;
    setState(() => _bottomPullExtent = 0);
  }

  void _addBottomPullExtent(double delta) {
    if (delta <= 0 || _bottomRefreshing) return;
    final next = (_bottomPullExtent + delta).clamp(0.0, _bottomPullTriggerThreshold * 1.5);
    if (next == _bottomPullExtent) return;
    setState(() => _bottomPullExtent = next);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (widget.onRefresh == null) return false;

    if (notification is ScrollStartNotification) {
      if (!_bottomRefreshing) {
        setState(() => _bottomPullExtent = 0);
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (_bottomRefreshing) return false;
      final metrics = notification.metrics;
      if (!_isNearBottomMetrics(metrics)) {
        if (_bottomPullExtent > 0) _resetBottomPull();
        return false;
      }
      if (notification.dragDetails == null) return false;
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0) {
        _addBottomPullExtent(delta);
      }
      return false;
    }

    if (notification is OverscrollNotification) {
      if (_bottomRefreshing) return false;
      if (!_isNearBottomMetrics(notification.metrics)) return false;
      if (notification.overscroll < 0) {
        _addBottomPullExtent(-notification.overscroll);
      }
      return false;
    }

    if (notification is ScrollEndNotification) {
      if (_bottomRefreshing) return false;
      final shouldRefresh = _bottomPullExtent >= _bottomPullTriggerThreshold &&
          _isNearBottomMetrics(notification.metrics);
      if (shouldRefresh) {
        unawaited(_handleBottomPullRefresh());
      } else {
        _resetBottomPull();
      }
      return false;
    }

    return false;
  }

  Future<void> _handleBottomPullRefresh() async {
    if (_bottomRefreshing || widget.onRefresh == null) return;
    setState(() {
      _bottomRefreshing = true;
      _bottomPullExtent = _bottomPullTriggerThreshold;
    });
    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) {
        setState(() {
          _bottomRefreshing = false;
          _bottomPullExtent = 0;
        });
        _pendingFollowScroll = true;
        scrollToBottom(force: true);
      }
    }
  }

  Future<void> _handleRefresh() async {
    final atTop = !_controller.hasClients || _controller.offset <= _loadMoreTopThreshold;
    if (atTop && widget.hasMore && widget.onLoadMore != null) {
      await _handleLoadMore();
      return;
    }
    await widget.onRefresh?.call();
  }

  Future<void> _handleLoadMore() async {
    if (widget.onLoadMore == null) return;
    double? beforeMax;
    double? beforePixels;
    if (_controller.hasClients) {
      beforeMax = _controller.position.maxScrollExtent;
      beforePixels = _controller.position.pixels;
    }
    await widget.onLoadMore!();
    if (beforeMax == null || beforePixels == null) return;
    final savedMax = beforeMax;
    final savedPixels = beforePixels;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final delta = _controller.position.maxScrollExtent - savedMax;
      if (delta > 0) {
        _controller.jumpTo(savedPixels + delta);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _syncPeriodicTicks();
    _pendingFollowScroll = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => scrollToBottom(force: true));
  }

  @override
  void didUpdateWidget(HomeHistoryScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPeriodicTicks();
    _pruneLogoAnchorKeys();
    _syncScrollToBottomButtonVisibility(itemCount: widget.itemsAsc.length);
    final lenChanged = oldWidget.itemsAsc.length != widget.itemsAsc.length;
    final lastChanged = oldWidget.itemsAsc.isEmpty != widget.itemsAsc.isEmpty ||
        (widget.itemsAsc.isNotEmpty &&
            oldWidget.itemsAsc.last.id != widget.itemsAsc.last.id);
    final prepended = lenChanged &&
        widget.itemsAsc.isNotEmpty &&
        oldWidget.itemsAsc.isNotEmpty &&
        widget.itemsAsc.last.id == oldWidget.itemsAsc.last.id &&
        widget.itemsAsc.first.id != oldWidget.itemsAsc.first.id;
    if ((lenChanged || lastChanged) && _followLatest && !prepended) {
      _pendingFollowScroll = true;
      SchedulerBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    }
  }

  void _pruneLogoAnchorKeys() {
    final liveIds = widget.itemsAsc.map((r) => r.id).toSet();
    _logoAnchorKeys.removeWhere((id, _) => !liveIds.contains(id));
  }

  void _syncScrollToBottomButtonVisibility({required int itemCount}) {
    final show = !_followLatest && itemCount > 0;
    if (_showScrollToBottomButton.value != show) {
      _showScrollToBottomButton.value = show;
    }
  }

  void _setFollowLatest(bool followLatest, {required int itemCount}) {
    if (_followLatest == followLatest) return;
    _followLatest = followLatest;
    _syncScrollToBottomButtonVisibility(itemCount: itemCount);
    widget.onFollowLatestChanged?.call(followLatest);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final nearBottom = pos.maxScrollExtent - pos.pixels <= followBottomThreshold;
    if (_followLatest != nearBottom) {
      _setFollowLatest(nearBottom, itemCount: widget.itemsAsc.length);
    }
  }

  void _syncPeriodicTicks() {
    if (widget.flyAnimationInProgress) {
      _activeTimingTick?.cancel();
      _activeTimingTick = null;
      _relativeAgoMinuteTick?.cancel();
      _relativeAgoMinuteTick = null;
      return;
    }
    final newestIdByKey = _computeNewestIdByEventKey(widget.itemsAsc);
    final hasActive = widget.itemsAsc.any(isActiveTimingRecord);
    final hasRelativeAgoBadge = widget.itemsAsc.any(
      (r) => _showRelativeAgoForRecord(r, newestIdByKey),
    );

    if (hasActive) {
      _relativeAgoMinuteTick?.cancel();
      _relativeAgoMinuteTick = null;
      if (_activeTimingTick == null) {
        _tickNow.value = DateTime.now();
        _activeTimingTick = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          _tickNow.value = DateTime.now();
          if (!widget.itemsAsc.any(isActiveTimingRecord)) {
            _syncPeriodicTicks();
          }
        });
      }
      return;
    }

    _activeTimingTick?.cancel();
    _activeTimingTick = null;

    if (hasRelativeAgoBadge) {
      if (_relativeAgoMinuteTick == null) {
        _tickNow.value = DateTime.now();
        _relativeAgoMinuteTick = Timer.periodic(const Duration(minutes: 1), (_) {
          if (!mounted) return;
          _tickNow.value = DateTime.now();
          final newest = _computeNewestIdByEventKey(widget.itemsAsc);
          if (!widget.itemsAsc.any((r) => _showRelativeAgoForRecord(r, newest))) {
            _relativeAgoMinuteTick?.cancel();
            _relativeAgoMinuteTick = null;
          }
        });
      }
    } else {
      _relativeAgoMinuteTick?.cancel();
      _relativeAgoMinuteTick = null;
    }
  }

  static Map<String, String> _computeNewestIdByEventKey(List<HistoryRecord> itemsAsc) {
    final newestIdByKey = <String, String>{};
    final newestInstantByKey = <String, DateTime>{};
    final newestIndexByKey = <String, int>{};

    for (var i = 0; i < itemsAsc.length; i++) {
      final record = itemsAsc[i];
      final key = historyRecordEventKey(record);
      final instant = historyHomeDisplayInstant(record);

      final prevInstant = newestInstantByKey[key];
      if (prevInstant == null) {
        newestInstantByKey[key] = instant;
        newestIndexByKey[key] = i;
        newestIdByKey[key] = record.id;
        continue;
      }

      if (instant.isAfter(prevInstant)) {
        newestInstantByKey[key] = instant;
        newestIndexByKey[key] = i;
        newestIdByKey[key] = record.id;
      } else if (instant.isAtSameMomentAs(prevInstant) && i > newestIndexByKey[key]!) {
        newestIndexByKey[key] = i;
        newestIdByKey[key] = record.id;
      }
    }
    return newestIdByKey;
  }

  static bool _showRelativeAgoForRecord(
    HistoryRecord record,
    Map<String, String> newestIdByKey,
  ) {
    if (isActiveTimingRecord(record)) return false;
    final key = historyRecordEventKey(record);
    return newestIdByKey[key] == record.id;
  }

  void scrollToBottom({bool animate = false, bool force = false}) {
    if (!force && !_followLatest && !_pendingFollowScroll) return;

    void tryScroll({bool withAnimation = false}) {
      if (!_controller.hasClients) return;
      final pos = _controller.position;
      final target = pos.maxScrollExtent;
      if (!target.isFinite) return;
      if ((pos.pixels - target).abs() < 1) {
        _pendingFollowScroll = false;
        if (force && !_followLatest) {
          _setFollowLatest(true, itemCount: widget.itemsAsc.length);
        }
        return;
      }
      if (withAnimation) {
        _controller.animateTo(
          target,
          duration: _followScrollDuration,
          curve: Curves.easeOutCubic,
        );
      } else {
        _controller.jumpTo(target);
      }
      _pendingFollowScroll = false;
      if (force) {
        _setFollowLatest(true, itemCount: widget.itemsAsc.length);
      }
    }

    tryScroll(withAnimation: animate && !force);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      tryScroll(withAnimation: animate);
    });
  }

  void _onScrollToBottomTap() {
    scrollToBottom(animate: true, force: true);
  }

  @override
  void dispose() {
    _activeTimingTick?.cancel();
    _relativeAgoMinuteTick?.cancel();
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _tickNow.dispose();
    _showScrollToBottomButton.dispose();
    super.dispose();
  }

  Color _dayRecordsCardColor(BuildContext context, AppVisualTokens? tokens) {
    if (tokens != null) return tokens.recordsCardColor;
    final scheme = Theme.of(context).colorScheme;
    return recordsCardColorForBundle(
      seedColor: scheme.primary,
      shellColor: Theme.of(context).scaffoldBackgroundColor,
      isDarkShell: Theme.of(context).brightness == Brightness.dark,
    );
  }

  GlobalKey _logoKeyFor(String recordId) {
    return _logoAnchorKeys.putIfAbsent(recordId, GlobalKey.new);
  }

  Widget _buildRecordTile({
    required HistoryRecord record,
    required HistoryHomeRowDisplay display,
    required int fromBottom,
    required Map<String, String> newestIdByKey,
  }) {
    final event = lookupEventForRecord(widget.eventCatalog, record);
    final hideLogo = widget.flyingRecordId == record.id;
    final showRelativeAgo = _showRelativeAgoForRecord(record, newestIdByKey);
    final displayInstant = historyHomeDisplayInstant(record);

    HomeHistoryTimelineTile tileFor(DateTime now) {
      return HomeHistoryTimelineTile(
        key: ValueKey<String>(record.id),
        display: display,
        fromBottom: fromBottom,
        event: event,
        logoAnchorKey: _logoKeyFor(record.id),
        hideLogoDuringFly: hideLogo,
        onTap: () => widget.onRecordTap(record),
        onStop: display.isActiveTiming && !isPendingHistoryId(record.id)
            ? () => widget.onStopActiveTimer(record)
            : null,
        stopInProgress: widget.stoppingRecordIds.contains(record.id),
        showRelativeAgo: showRelativeAgo,
        relativeAgoLabel: showRelativeAgo
            ? formatHistoryRelativeAgo(displayInstant, now)
            : null,
        activeElapsedLabel: display.isActiveTiming
            ? formatActiveTimerElapsed(now.difference(activeTimingStartAt(record)))
            : null,
      );
    }

    if (!display.isActiveTiming && !showRelativeAgo) {
      return tileFor(DateTime.now());
    }

    return ValueListenableBuilder<DateTime>(
      valueListenable: _tickNow,
      builder: (context, now, _) => tileFor(now),
    );
  }

  Widget? _buildDayRecordsCard(
    BuildContext context,
    HomeHistoryDayGroup group,
    Color cardFill,
    int total,
    int recordIndexStart,
    Map<String, String> newestIdByKey,
  ) {
    var recordIndex = recordIndexStart;
    const cardHorizontalPadding = EdgeInsets.symmetric(horizontal: 12);
    final cardRadius = Theme.of(context).extension<AppVisualTokens>()?.surfaceRadius ?? 14;

    final tiles = <Widget>[];
    final dotColors = <Color>[];
    final dotRadii = <double>[];
    final rowSlotHeights = <double>[];
    for (final record in group.recordsOldestFirst) {
      final fromBottom = total - 1 - recordIndex;
      recordIndex++;
      final display = historyHomeRowDisplay(record);
      final event = lookupEventForRecord(widget.eventCatalog, record);
      final showRelativeAgo = _showRelativeAgoForRecord(record, newestIdByKey);
      dotColors.add(resolveEventColor(context, event));
      dotRadii.add(HomeHistoryTimelineTile.dotRadiusForFromBottom(fromBottom));
      rowSlotHeights.add(
        HomeHistoryTimelineTile.slotHeightFor(showRelativeAgo: showRelativeAgo),
      );
      tiles.add(
        _buildRecordTile(
          record: record,
          display: display,
          fromBottom: fromBottom,
          newestIdByKey: newestIdByKey,
        ),
      );
    }

    if (tiles.isEmpty) return null;

    final linksHeight =
        rowSlotHeights.fold<double>(0, (sum, h) => sum + h);

    const cardInnerPadding = EdgeInsets.all(8);

    return Padding(
      padding: cardHorizontalPadding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardFill,
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: Padding(
            padding: cardInnerPadding,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (dotColors.length >= 2)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: linksHeight,
                    child: HomeHistoryDayTimelineLinks(
                      dotColors: dotColors,
                      dotRadii: dotRadii,
                      rowSlotHeights: rowSlotHeights,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: tiles,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 日块：旧→新（今天在列表底部）；`reverse: true` 时 pinned 会贴底而非吸顶，故用正向滚动。
    final groups = buildHomeHistoryDayGroups(widget.itemsAsc).reversed.toList();
    final total = widget.itemsAsc.length;
    final newestIdByKey = _computeNewestIdByEventKey(widget.itemsAsc);
    var recordIndex = 0;

    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final isDarkShell = tokens?.isDarkShell ?? (Theme.of(context).brightness == Brightness.dark);
    final cardOpacity = isDarkShell ? kHistoryRecordsCardOpacityDark : kHistoryRecordsCardOpacityLight;
    final cardBgFill = _dayRecordsCardColor(context, tokens).withValues(alpha: cardOpacity);

    final daySlivers = <Widget>[];
    for (final g in groups) {
      final recordsCard = _buildDayRecordsCard(
        context,
        g,
        cardBgFill,
        total,
        recordIndex,
        newestIdByKey,
      );
      final groupSlivers = <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: HomeHistoryDateHeaderDelegate(label: g.dayLabel),
        ),
        if (recordsCard != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: recordsCard,
            ),
          ),
      ];
      daySlivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          sliver: SliverMainAxisGroup(
            slivers: groupSlivers,
          ),
        ),
      );
      recordIndex += g.recordsOldestFirst.length;
    }

    final bottomPullFooter = _buildBottomPullFooter(context);

    return Stack(
      key: _historyAreaKey,
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: CustomScrollView(
              controller: _controller,
              cacheExtent: 360,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: [
                if (widget.loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                  sliver: SliverMainAxisGroup(slivers: daySlivers),
                ),
                bottomPullFooter,
              ],
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _showScrollToBottomButton,
          builder: (context, show, _) {
            return Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: IgnorePointer(
                ignoring: !show,
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: RepaintBoundary(
                    child: Center(
                      child: HomeHistoryScrollToBottomButton(onPressed: _onScrollToBottomTap),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomPullFooter(BuildContext context) {
    if (!_bottomRefreshing && _bottomPullExtent <= 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final fg = tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
    final height = _bottomRefreshing
        ? 48.0
        : _bottomPullExtent.clamp(28.0, _bottomPullTriggerThreshold * 1.2);

    final String label;
    if (_bottomRefreshing) {
      label = '正在更新…';
    } else if (_bottomPullExtent >= _bottomPullTriggerThreshold) {
      label = '松开刷新';
    } else {
      label = '上拉刷新';
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: height,
        child: Center(
          child: _bottomRefreshing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.55)),
                    ),
                  ],
                )
              : Text(
                  label,
                  style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.55)),
                ),
        ),
      ),
    );
  }
}
