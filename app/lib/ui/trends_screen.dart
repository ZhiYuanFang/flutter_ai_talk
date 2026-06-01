import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/trends_date_range_store.dart';
import '../config/trends_selected_event_store.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/models.dart';
import '../data/trend_series_bucket.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import 'event_logo.dart';
import 'home_history_edit_glass_panel.dart';
import 'trend_glass_bar_chart.dart';
import 'trends_date_range_glass_sheet.dart';
import 'trends_event_logo_fly_overlay.dart';
import 'widgets/app_glass_overlay.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  static final _rangeFmt = DateFormat('MM-dd');
  static const _headerLogoSize = 52.0;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedKey;
  TrendSeries? _series;
  var _loadingSeries = false;
  var _seriesLoadSeq = 0;
  var _selectionReady = false;
  var _barAnimationToken = 0;
  var _holdIntroBarsAtZero = false;
  var _suppressIntroEmptyState = false;
  final GlobalKey _headerLogoKey = GlobalKey();
  double _flyBaseLogoSize = _headerLogoSize;
  EventDefinition? _flyingEvent;
  Offset? _flyTargetCenter;
  var _flySession = 0;
  Completer<void>? _flyCompleter;

  TrendBucketMode get _bucketMode {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) return TrendBucketMode.daily;
    return trendBucketModeForDates(start, end);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final memory = await TrendsDateRangeStore.loadValid();
      final range = memory ?? TrendsDateRangeLogic.defaultRange();
      final rememberedKey = await TrendsSelectedEventStore.load();
      _startDate = range.start;
      _endDate = range.end;
      await ref.read(eventCatalogProvider.notifier).loadFromDisk();
      _syncSelection(preferredKey: rememberedKey);
      _selectionReady = true;
      final selected = _selectedKey;
      if (selected != null && selected != rememberedKey) {
        unawaited(TrendsSelectedEventStore.save(selected));
      }
      _holdIntroBarsAtZero = true;
      _suppressIntroEmptyState = true;
      if (mounted) setState(() {});
      final selectedEvent = _selectedEvent(ref.read(eventCatalogProvider));
      await _loadSeriesWithIntroAnimation(selectedEvent);
      unawaited(ref.read(eventCatalogProvider.notifier).refreshFromRemote());
    });
  }

  /// 随目录更新选中项；仅当选中 [eventId] 变化时由调用方触发拉数。
  void _syncSelection({String? preferredKey}) {
    final catalog = ref.read(eventCatalogProvider);
    final leaves = leafEvents(catalog, requireValidEventType: true);
    if (leaves.isEmpty) {
      _selectedKey = null;
      return;
    }
    final preferredValid =
        preferredKey != null && leaves.any((e) => e.id == preferredKey);
    if (preferredValid) {
      _selectedKey = preferredKey;
      return;
    }
    final currentValid =
        _selectedKey != null && leaves.any((e) => e.id == _selectedKey);
    if (_selectedKey == null || !currentValid) {
      _selectedKey = leaves.first.id;
    }
  }

  void _scheduleSeriesLoadIfReady() {
    if (_selectedKey != null && _startDate != null && _endDate != null) {
      unawaited(_loadSeriesForSelection());
    }
  }

  Future<void> _loadSeriesWithIntroAnimation(EventDefinition? selectedEvent) async {
    final key = _selectedKey;
    final start = _startDate;
    final end = _endDate;
    if (key == null || start == null || end == null) {
      if (mounted) {
        setState(() {
          _series = null;
          _holdIntroBarsAtZero = false;
          _suppressIntroEmptyState = false;
        });
      }
      return;
    }
    final seq = ++_seriesLoadSeq;
    final repo = ref.read(trendsRepositoryProvider);
    final future = repo.loadSeries(key, start, end);
    unawaited(_playEventLogoFlyAnimation(selectedEvent));
    final s = await future;
    if (!mounted || seq != _seriesLoadSeq) return;
    setState(() {
      _series = s;
      _loadingSeries = false;
      _barAnimationToken++;
      _holdIntroBarsAtZero = false;
      _suppressIntroEmptyState = false;
    });
  }

  Future<void> _loadSeriesForSelection() async {
    final key = _selectedKey;
    final start = _startDate;
    final end = _endDate;
    if (key == null || start == null || end == null) {
      if (mounted) {
        setState(() {
          _series = null;
          _holdIntroBarsAtZero = false;
        });
      }
      return;
    }
    final seq = ++_seriesLoadSeq;
    setState(() => _loadingSeries = true);
    final repo = ref.read(trendsRepositoryProvider);
    final s = await repo.loadSeries(key, start, end);
    if (!mounted || seq != _seriesLoadSeq) return;
    setState(() {
      _series = s;
      _loadingSeries = false;
      _holdIntroBarsAtZero = false;
    });
  }

  EventDefinition? _selectedEvent(List<EventDefinition> catalog) {
    final key = _selectedKey;
    if (key == null) return null;
    return lookupEventById(catalog, key);
  }

  String _rangeLabel() {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) return '选择日期';
    return '${_rangeFmt.format(start)} — ${_rangeFmt.format(end)}';
  }

  Future<void> _openDateRangePicker() async {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) return;
    final selectedEvent = _selectedEvent(ref.read(eventCatalogProvider));
    final accent = resolveEventColor(context, selectedEvent);
    final picked = await showTrendsDateRangeGlassSheet(
      context,
      initialStart: start,
      initialEnd: end,
      eventAccent: accent,
    );
    if (picked == null || !mounted) return;
    final newStart = picked.start;
    final newEnd = picked.end;
    await TrendsDateRangeStore.save(picked);
    setState(() {
      _startDate = newStart;
      _endDate = newEnd;
    });
    await _loadSeriesForSelection();
  }

  Future<void> _openEventPicker(List<EventDefinition> catalog) async {
    final pickerItems = leafEvents(catalog, requireValidEventType: true);
    if (pickerItems.isEmpty) return;
    final accent = resolveEventColor(context, pickerItems.first);
    final picked = await showGlassAdaptiveBottomSheet<String>(
      context: context,
      eventAccent: accent,
      scrollable: false,
      bodyBuilder: (ctx) {
        final glassText = historyEditGlassTextColor(ctx);
        final scheme = Theme.of(ctx).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '选择事件',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: glassText),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.18)),
            Expanded(
              child: ListView.builder(
                itemCount: pickerItems.length,
                itemBuilder: (context, index) {
                  final e = pickerItems[index];
                  final selected = e.id == _selectedKey;
                  return ListTile(
                    selected: selected,
                    leading: EventLogo(definition: e, size: 28),
                    title: Text(e.name, style: TextStyle(color: glassText)),
                    trailing: selected
                        ? Icon(Icons.check, color: scheme.primary)
                        : null,
                    onTap: () => Navigator.pop(ctx, e.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
    if (picked == null || picked == _selectedKey) return;
    setState(() => _selectedKey = picked);
    await TrendsSelectedEventStore.save(picked);
    final selectedEvent = lookupEventById(catalog, picked);
    final key = _selectedKey;
    final start = _startDate;
    final end = _endDate;
    if (key == null || start == null || end == null) {
      await _playEventLogoFlyAnimation(selectedEvent);
      return;
    }
    final seq = ++_seriesLoadSeq;
    final repo = ref.read(trendsRepositoryProvider);
    final future = repo.loadSeries(key, start, end);
    unawaited(_playEventLogoFlyAnimation(selectedEvent));
    final s = await future;
    if (!mounted || seq != _seriesLoadSeq) return;
    setState(() {
      _series = s;
      _barAnimationToken++;
      _holdIntroBarsAtZero = false;
    });
  }

  Offset? _resolveHeaderLogoCenter() {
    final ctx = _headerLogoKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  double? _resolveHeaderLogoSize() {
    final ctx = _headerLogoKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final size = box.size.shortestSide;
    if (!size.isFinite || size <= 0) return null;
    return size;
  }

  Future<void> _playEventLogoFlyAnimation(EventDefinition? event) async {
    if (!mounted || event == null) return;
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final safeTop = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final fallbackEnd = Offset(width / 2, safeTop + 92);
    final end = _resolveHeaderLogoCenter() ?? fallbackEnd;
    final baseLogoSize = _resolveHeaderLogoSize() ?? _headerLogoSize;
    final completer = Completer<void>();
    setState(() {
      _flySession++;
      _flyCompleter = completer;
      _flyBaseLogoSize = baseLogoSize;
      _flyingEvent = event;
      _flyTargetCenter = end;
    });
    await completer.future;
  }

  void _onFlyOverlayComplete(int session) {
    if (session != _flySession) return;
    _flyCompleter?.complete();
    _flyCompleter = null;
    if (!mounted) return;
    setState(() {
      _flyingEvent = null;
      _flyTargetCenter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final needLoginMask = !ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final catalog = ref.watch(eventCatalogProvider);
    ref.listen<List<EventDefinition>>(eventCatalogProvider, (prev, next) {
      if (prev == next) return;
      if (!_selectionReady) return;
      final before = _selectedKey;
      _syncSelection();
      if (_selectedKey != before) {
        final selected = _selectedKey;
        if (selected != null) {
          unawaited(TrendsSelectedEventStore.save(selected));
        }
        _scheduleSeriesLoadIfReady();
      }
    });
    final selectedEvent = _selectedEvent(catalog);
    final accent = resolveEventColor(context, selectedEvent);
    final rangeReady = _startDate != null && _endDate != null;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          catalog.isEmpty
              ? Center(
                  child: Text(
                    '暂无事件目录，请稍后再试或检查网络',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                )
              : !rangeReady
                  ? const Center(child: CircularProgressIndicator())
                  : _loadingSeries
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            TrendGlassBarChart(
                              series: _series,
                              bucketMode: _bucketMode,
                              accentColor: accent,
                              chartTitle: TrendGlassBarChart.chartTitleForEvent(
                                selectedEvent?.name,
                              ),
                              dateRangeLabel: _rangeLabel(),
                              headerTopOffset: MediaQuery.paddingOf(context).top + 8,
                              barAnimationToken: _barAnimationToken,
                              holdAtZeroBeforeAnimation: _holdIntroBarsAtZero,
                              suppressEmptyState: _suppressIntroEmptyState,
                              headerLogo: selectedEvent == null
                                  ? null
                                  : Opacity(
                                      opacity: _flyingEvent != null ? 0 : 1,
                                      child: EventLogo(
                                        key: _headerLogoKey,
                                        definition: selectedEvent,
                                        size: _headerLogoSize,
                                      ),
                                    ),
                              onTitleTap: () => unawaited(_openEventPicker(catalog)),
                              onDateRangeTap: () => unawaited(_openDateRangePicker()),
                            ),
                            if (needLoginMask)
                              ColoredBox(
                                color: Colors.black45,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '请登录',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton(
                                        onPressed: () => context.push('/login'),
                                        child: const Text('请登录'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_flyingEvent != null && _flyTargetCenter != null)
                              Positioned.fill(
                                child: RepaintBoundary(
                                  child: TrendsEventLogoFlyOverlay(
                                    key: ValueKey<int>(_flySession),
                                    event: _flyingEvent!,
                                    targetGlobalCenter: _flyTargetCenter!,
                                    baseLogoSize: _flyBaseLogoSize,
                                    onComplete: () => _onFlyOverlayComplete(_flySession),
                                  ),
                                ),
                              ),
                          ],
                        ),
          Positioned(
            left: 8,
            top: MediaQuery.paddingOf(context).top + 4,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: '返回',
            ),
          ),
        ],
      ),
    );
  }
}
