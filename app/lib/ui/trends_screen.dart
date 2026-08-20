import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/trends_date_range_store.dart';
import '../config/trends_selected_event_store.dart';
import '../data/event_catalog_state.dart';
import '../data/event_catalog_tree.dart';
import '../data/event_branding.dart';
import '../data/event_definition.dart';
import '../data/models.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../theme/app_color.dart';
import 'event_logo.dart';
import 'home_history_edit_glass_panel.dart';
import 'trend_day_detail_chart.dart';
import 'trend_n_day_bar_chart.dart';
import 'trends_date_range_glass_sheet.dart';
import 'trends_event_logo_fly_overlay.dart';
import 'widgets/app_glass_overlay.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  static final _dayTitleFmt = DateFormat('MM-dd');
  static const _chromeLogoSize = 28.0;

  TrendsRangePreset _preset = TrendsRangePreset.days7;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _selectedDay;
  String? _selectedKey;
  TrendPieceBundle? _bundle;
  var _loadingSeries = false;
  var _seriesLoadSeq = 0;
  var _selectionReady = false;
  var _barAnimationToken = 0;
  var _holdIntroBarsAtZero = false;
  final GlobalKey _chromeLogoKey = GlobalKey();
  double _flyBaseLogoSize = _chromeLogoSize;
  EventDefinition? _flyingEvent;
  Offset? _flyTargetCenter;
  var _flySession = 0;
  Completer<void>? _flyCompleter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 默认近7日，不恢复上次范围。
      _applyPreset(TrendsRangePreset.days7, resetSelectedIfNeeded: true);
      final rememberedKey = await TrendsSelectedEventStore.load();
      await ref.read(eventCatalogProvider.notifier).loadFromDisk();
      _syncSelection(preferredKey: rememberedKey);
      _selectionReady = true;
      final selected = _selectedKey;
      if (selected != null && selected != rememberedKey) {
        unawaited(TrendsSelectedEventStore.save(selected));
      }
      _holdIntroBarsAtZero = true;
      if (mounted) setState(() {});
      final selectedEvent = _selectedEvent(ref.read(eventCatalogProvider).items);
      await _loadBundleWithIntroAnimation(selectedEvent);
      unawaited(ref.read(eventCatalogProvider.notifier).refreshFromRemote());
    });
  }

  void _applyPreset(TrendsRangePreset preset, {required bool resetSelectedIfNeeded}) {
    final range = TrendsDateRangeLogic.rangeForPreset(preset);
    _preset = preset;
    _startDate = range.start;
    _endDate = range.end;
    final today = TrendsDateRangeLogic.dateOnly(DateTime.now());
    final sel = _selectedDay;
    if (sel == null ||
        resetSelectedIfNeeded ||
        !TrendsDateRangeLogic.dayInRange(sel, range.start, range.end)) {
      _selectedDay = today;
    }
  }

  /// 随目录更新选中项；仅当选中 [eventId] 变化时由调用方触发拉数。
  void _syncSelection({String? preferredKey}) {
    final catalog = ref.read(eventCatalogProvider).items;
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

  void _scheduleBundleLoadIfReady() {
    if (_selectedKey != null && _startDate != null && _endDate != null) {
      unawaited(_loadBundleForSelection());
    }
  }

  Future<void> _loadBundleWithIntroAnimation(EventDefinition? selectedEvent) async {
    final key = _selectedKey;
    final start = _startDate;
    final end = _endDate;
    if (key == null || start == null || end == null) {
      if (mounted) {
        setState(() {
          _bundle = null;
          _holdIntroBarsAtZero = false;
        });
      }
      return;
    }
    final seq = ++_seriesLoadSeq;
    final repo = ref.read(trendsRepositoryProvider);
    final future = repo.loadPieceBundle(key, start, end);
    unawaited(_playEventLogoFlyAnimation(selectedEvent));
    final s = await future;
    if (!mounted || seq != _seriesLoadSeq) return;
    setState(() {
      _bundle = s;
      _loadingSeries = false;
      _barAnimationToken++;
      _holdIntroBarsAtZero = false;
    });
  }

  Future<void> _loadBundleForSelection() async {
    final key = _selectedKey;
    final start = _startDate;
    final end = _endDate;
    if (key == null || start == null || end == null) {
      if (mounted) {
        setState(() {
          _bundle = null;
          _holdIntroBarsAtZero = false;
        });
      }
      return;
    }
    final seq = ++_seriesLoadSeq;
    setState(() => _loadingSeries = true);
    final repo = ref.read(trendsRepositoryProvider);
    final s = await repo.loadPieceBundle(key, start, end);
    if (!mounted || seq != _seriesLoadSeq) return;
    setState(() {
      _bundle = s;
      _loadingSeries = false;
      _holdIntroBarsAtZero = false;
    });
  }

  EventDefinition? _selectedEvent(List<EventDefinition> catalog) {
    final key = _selectedKey;
    if (key == null) return null;
    return lookupEventById(catalog, key);
  }

  List<TrendPoint> _rawForSelectedDay() {
    final day = _selectedDay;
    final raw = _bundle?.raw ?? const <TrendPoint>[];
    if (day == null) return const [];
    final key = TrendsDateRangeLogic.dateOnly(day);
    return raw.where((p) {
      final l = p.t.toLocal();
      return DateTime(l.year, l.month, l.day) == key;
    }).toList();
  }

  Future<void> _openRangePresetPicker() async {
    final selectedEvent = _selectedEvent(ref.read(eventCatalogProvider).items);
    final accent = resolveEventColor(context, selectedEvent);
    final picked = await showTrendsRangePresetGlassSheet(
      context,
      initial: _preset,
      eventAccent: accent,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _applyPreset(picked, resetSelectedIfNeeded: false);
    });
    await _loadBundleForSelection();
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
    final future = repo.loadPieceBundle(key, start, end);
    unawaited(_playEventLogoFlyAnimation(selectedEvent));
    final s = await future;
    if (!mounted || seq != _seriesLoadSeq) return;
    setState(() {
      _bundle = s;
      _barAnimationToken++;
      _holdIntroBarsAtZero = false;
    });
  }

  Offset? _resolveChromeLogoCenter() {
    final ctx = _chromeLogoKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  double? _resolveChromeLogoSize() {
    final ctx = _chromeLogoKey.currentContext;
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
    final fallbackEnd = Offset(28, safeTop + 28);
    final end = _resolveChromeLogoCenter() ?? fallbackEnd;
    final baseLogoSize = _resolveChromeLogoSize() ?? _chromeLogoSize;
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

  Widget _chartTitleRow({
    required EventDefinition? event,
    required Color accent,
    required String title,
    String? subtitle,
    bool showLogoBesideTitle = true,
    double logoSize = 18,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLogoBesideTitle && event != null) ...[
              EventLogo(definition: event, size: logoSize),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (event != null) ...[
                EventLogo(definition: event, size: 12),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: accent.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDualCharts({
    required EventDefinition? selectedEvent,
    required Color accent,
    required bool landscape,
  }) {
    final day = _selectedDay ?? TrendsDateRangeLogic.dateOnly(DateTime.now());
    final nDayTitle =
        '${selectedEvent?.name ?? ''}近${_preset.dayCount}日总量趋势图';
    final dayMain = _dayTitleFmt.format(day);
    final daySub = '${selectedEvent?.name ?? ''}24小时内趋势图';
    final rawDay = _rawForSelectedDay();

    final nDayPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chartTitleRow(event: selectedEvent, accent: accent, title: nDayTitle),
        const SizedBox(height: 6),
        Expanded(
          child: TrendNDayBarChart(
            daily: _bundle?.daily ?? const [],
            raw: _bundle?.raw ?? const [],
            accentColor: accent,
            eventType: selectedEvent?.parsedEventType,
            unit: selectedEvent?.unit,
            selectedDay: day,
            onSelectDay: (d) {
              setState(() {
                _selectedDay = TrendsDateRangeLogic.dateOnly(d);
              });
            },
            barAnimationToken: _barAnimationToken,
            holdAtZeroBeforeAnimation: _holdIntroBarsAtZero,
          ),
        ),
      ],
    );

    final dayPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chartTitleRow(
          event: selectedEvent,
          accent: accent,
          title: dayMain,
          subtitle: daySub,
          showLogoBesideTitle: false,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: TrendDayDetailChart(
            dayLocal: day,
            rawForDay: rawDay,
            accentColor: accent,
            eventType: selectedEvent?.parsedEventType,
            unit: selectedEvent?.unit,
          ),
        ),
      ],
    );

    if (landscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: nDayPane),
          const SizedBox(width: 10),
          Expanded(child: dayPane),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: nDayPane),
        const SizedBox(height: 10),
        Expanded(child: dayPane),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final needLoginMask = !ref.watch(sessionProvider.select((s) => s.isLoggedIn));
    final catalogState = ref.watch(eventCatalogProvider);
    final catalog = catalogState.items;
    ref.listen<EventCatalogState>(eventCatalogProvider, (prev, next) {
      if (prev == next) return;
      if (!_selectionReady) return;
      final before = _selectedKey;
      _syncSelection();
      if (_selectedKey != before) {
        final selected = _selectedKey;
        if (selected != null) {
          unawaited(TrendsSelectedEventStore.save(selected));
        }
        _scheduleBundleLoadIfReady();
      }
    });
    final selectedEvent = _selectedEvent(catalog);
    final accent = resolveEventColor(context, selectedEvent);
    final rangeReady = _startDate != null && _endDate != null;
    final catalogLoading = catalogState.isRefreshing ||
        (!catalogState.remoteLoadAttempted && catalog.isEmpty);
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          catalog.isEmpty
              ? Center(
                  child: catalogLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '暂无事件目录，请稍后再试或检查网络',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                          textAlign: TextAlign.center,
                        ),
                )
              : !rangeReady
                  ? const Center(child: CircularProgressIndicator())
                  : _loadingSeries && _bundle == null
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            HistoryEditGlassPanel(
                              eventAccent: accent,
                              borderRadius: 0,
                              contentPadding: EdgeInsets.fromLTRB(
                                8,
                                topPad + 8,
                                16,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 选择行：返回 + logo/事件名 + 范围 chip，纵向居中。
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () => context.pop(),
                                        icon: Icon(
                                          Icons.arrow_back,
                                          color: accent,
                                        ),
                                        tooltip: '返回',
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () =>
                                              unawaited(_openEventPicker(catalog)),
                                          child: Row(
                                            children: [
                                              if (selectedEvent != null)
                                                Opacity(
                                                  opacity:
                                                      _flyingEvent != null ? 0 : 1,
                                                  child: EventLogo(
                                                    key: _chromeLogoKey,
                                                    definition: selectedEvent,
                                                    size: _chromeLogoSize,
                                                  ),
                                                ),
                                              if (selectedEvent != null)
                                                const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  selectedEvent?.name ?? '选择事件',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                    color: accent,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.expand_more,
                                                color: accent,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            unawaited(_openRangePresetPicker()),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            color: accent.withValues(alpha: 0.10),
                                            border: Border.all(
                                              color: accent,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _preset.label,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: accent,
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Icon(
                                                  Icons.expand_more,
                                                  size: 18,
                                                  color: accent,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: _buildDualCharts(
                                      selectedEvent: selectedEvent,
                                      accent: accent,
                                      landscape: landscape,
                                    ),
                                  ),
                                ],
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
                            if (_flyingEvent != null && _flyTargetCenter != null)
                              Positioned.fill(
                                child: RepaintBoundary(
                                  child: TrendsEventLogoFlyOverlay(
                                    key: ValueKey<int>(_flySession),
                                    event: _flyingEvent!,
                                    targetGlobalCenter: _flyTargetCenter!,
                                    baseLogoSize: _flyBaseLogoSize,
                                    onComplete: () =>
                                        _onFlyOverlayComplete(_flySession),
                                  ),
                                ),
                              ),
                          ],
                        ),
          // 目录/加载态无选择行时，保留可退出的返回键。
          if (catalog.isEmpty || !rangeReady || (_loadingSeries && _bundle == null))
            Positioned(
              left: 8,
              top: topPad + 4,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColor.textPrimary(context),
                ),
                tooltip: '返回',
              ),
            ),
        ],
      ),
    );
  }
}
