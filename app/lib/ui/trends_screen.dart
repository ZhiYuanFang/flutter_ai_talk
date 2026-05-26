import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/trends_date_range_store.dart';
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
import 'widgets/app_glass_overlay.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  static final _rangeFmt = DateFormat('MM-dd');

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedKey;
  TrendSeries? _series;
  var _loadingSeries = false;
  var _seriesLoadSeq = 0;

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
      _startDate = range.start;
      _endDate = range.end;
      await ref.read(eventCatalogProvider.notifier).loadFromDisk();
      _syncSelection();
      if (mounted) setState(() {});
      unawaited(ref.read(eventCatalogProvider.notifier).refreshFromRemote());
    });
  }

  /// 随目录更新选中项；仅当选中 [eventId] 变化时由调用方触发拉数。
  void _syncSelection() {
    final catalog = ref.read(eventCatalogProvider);
    final leaves = leafEvents(catalog, requireValidEventType: true);
    if (leaves.isEmpty) {
      _selectedKey = null;
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

  Future<void> _loadSeriesForSelection() async {
    final key = _selectedKey;
    final start = _startDate;
    final end = _endDate;
    if (key == null || start == null || end == null) {
      if (mounted) setState(() => _series = null);
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
    await _loadSeriesForSelection();
  }

  Widget _capsuleLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: historyEditGlassShellLabelColor(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needLoginMask = !ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final catalog = ref.watch(eventCatalogProvider);
    ref.listen<List<EventDefinition>>(eventCatalogProvider, (prev, next) {
      if (prev == next) return;
      final before = _selectedKey;
      _syncSelection();
      if (_selectedKey != before) {
        _scheduleSeriesLoadIfReady();
      }
    });
    final selectedEvent = _selectedEvent(catalog);
    final accent = resolveEventColor(context, selectedEvent);
    final shellText = historyEditGlassShellTextColor(context);
    final shellMuted = historyEditGlassShellLabelColor(context);
    final rangeReady = _startDate != null && _endDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('趋势中心'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: catalog.isEmpty
                ? Text(
                    '暂无事件目录，请稍后再试或检查网络',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _capsuleLabel(context, '选择事件'),
                            HistoryEditGlassTapField(
                              onShell: true,
                              onTap: () => unawaited(_openEventPicker(catalog)),
                              minHeight: 48,
                              child: Row(
                                children: [
                                  if (selectedEvent != null) ...[
                                    EventLogo(definition: selectedEvent, size: 24),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: Text(
                                      selectedEvent?.name ?? '选择事件',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: shellText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more,
                                    color: shellMuted,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _capsuleLabel(context, '日期范围'),
                            HistoryEditGlassTapField(
                              onShell: true,
                              enabled: rangeReady,
                              onTap: () => unawaited(_openDateRangePicker()),
                              minHeight: 48,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _rangeLabel(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: shellText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: shellMuted,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: !rangeReady
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
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
