import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../api/app_debug_log.dart';
import '../data/baby_age.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../data/models.dart';
import '../data/smart_prediction_rows.dart';
import '../providers/event_catalog_notifier.dart';
import '../providers/forecast_toggle_provider.dart';
import '../providers/home_history_notifier.dart';
import '../providers/prediction_care_alert_provider.dart';
import '../providers/prediction_range_history_provider.dart';
import '../providers/prediction_recall_provider.dart';
import '../data/prediction_care_alert.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';
import '../providers/widget_tip_display_epoch_provider.dart';
import '../theme/app_theme_scope.dart';
import '../theme/custom_background_persist.dart';
import 'home_widget_constants.dart';
import 'home_widget_payload.dart';
import 'widget_history_depth.dart';
import 'widget_row_builder.dart';
import 'widget_row_enrich.dart';
import 'widget_theme_visual.dart';
import 'widget_hero_skip_store.dart';
import 'widget_interactivity.dart';
import 'widget_tip_cache.dart';

export 'format_widget_relative_time.dart';
export 'home_widget_constants.dart';
export 'home_widget_payload.dart';
export 'widget_row_builder.dart';

/// widget sync 读 provider 须走 container，避免 notifier 写入栈内 ref.read 自依赖断言。
///
/// 支持 [ProviderContainer]、[Ref]（Notifier 内）、以及 [WidgetRef]
///（实现上是 [ConsumerStatefulElement] 等 [BuildContext]，经 [ProviderScope.containerOf] 取容器；
/// **不能** `as Ref`，也 **没有** `container` getter）。
ProviderContainer _widgetSyncContainer(dynamic ref) {
  if (ref is ProviderContainer) return ref;
  if (ref is Ref) return ref.container;
  if (ref is BuildContext) {
    return ProviderScope.containerOf(ref, listen: false);
  }
  throw ArgumentError(
    'home_widget sync 需要 ProviderContainer、Ref 或 WidgetRef(BuildContext)，'
    '实际为 ${ref.runtimeType}',
  );
}

/// 与智能预测页同源的 widget 预测输入（7 日 range ∪ 种子、内存 catalog、推演关集合）。
({
  List<HistoryRecord> history,
  List<EventDefinition> catalog,
  Set<String> disabledForecastIds,
  Set<String> activeEventKeys,
}) resolveWidgetPredictionInputs(dynamic ref) {
  final container = _widgetSyncContainer(ref);
  final history = container.read(predictionHistoryWithRecallSeedsProvider);
  final catalog = container.read(eventCatalogProvider).items;
  final disabled =
      container.read(forecastDisabledIdsProvider).asData?.value ??
      const <String>{};
  final rangeItems = container.read(predictionRangeHistoryProvider).items;
  final homeItems = container.read(homeHistoryProvider).items;
  final activeKeys = <String>{
    ...collectActiveTimingRows(rangeItems, catalog: catalog)
        .map((e) => e.eventId),
    ...collectActiveTimingRows(homeItems, catalog: catalog)
        .map((e) => e.eventId),
  }.where((e) => e.isNotEmpty).toSet();
  return (
    history: history,
    catalog: catalog,
    disabledForecastIds: disabled,
    activeEventKeys: activeKeys,
  );
}

List<HistoryRecord> _historyForEnabledForecast({
  required List<HistoryRecord> history,
  required List<EventDefinition> catalog,
  required Set<String> disabledForecastIds,
}) {
  if (disabledForecastIds.isEmpty) return history;
  final byKey = groupHistoryByRootEvent(history: history, catalog: catalog);
  return [
    for (final e in byKey.entries)
      if (!disabledForecastIds.contains(e.key)) ...e.value,
  ];
}

Future<void> initHomeWidgetBridge() async {
  if (kIsWeb) return;
  try {
    await HomeWidget.setAppGroupId(HomeWidgetConstants.appGroupId);
    await registerHomeWidgetInteractivity();
    AppDebugLog.homeWidget('init appGroup=${HomeWidgetConstants.appGroupId}');
  } catch (e) {
    AppDebugLog.homeWidget('init err=$e');
  }
}

Future<HomeWidgetPayload> buildHomeWidgetPayload({
  required bool loggedIn,
  required BabyProfile? baby,
  required List<HistoryRecord> history,
  required List<EventDefinition> catalog,
  required String state,
  required HomeWidgetVisualPayload visual,
  String? message,
  HomeWidgetTipPayload? tip,
  DateTime? now,
  Set<String> disabledForecastIds = const {},
  Set<String>? activeEventKeysOverride,
}) async {
  final t = now ?? DateTime.now();
  HomeWidgetHeaderPayload? header;
  if (loggedIn && baby != null) {
    header = HomeWidgetHeaderPayload(
      nickname: baby.nickname,
      birthDate: HomeWidgetRowPayload.isoDateUtc(baby.birthDate),
      displayLine: formatWidgetHeaderLine(baby, t),
    );
  }

  final activeKeys = activeEventKeysOverride ??
      collectActiveTimingRows(history, catalog: catalog)
          .map((e) => e.eventId)
          .where((e) => e.isNotEmpty)
          .toSet();
  final enabledActiveKeys = {
    for (final k in activeKeys)
      if (!disabledForecastIds.contains(k)) k,
  };
  final enabledHistory = _historyForEnabledForecast(
    history: history,
    catalog: catalog,
    disabledForecastIds: disabledForecastIds,
  );
  final birth = baby?.birthDate ?? DateTime(t.year, 1, 1);
  final predictions = loggedIn
      ? predictAllUpcoming(
          history: enabledHistory,
          catalog: catalog,
          now: t,
          birthDate: birth,
          activeEventKeys: enabledActiveKeys,
        )
      : <EventNextPrediction>[];
  // S1：解除已有新记录的 skip；仅 hero 排除 skip，后续留意仍保留
  var heroPredictions = predictions;
  if (loggedIn && predictions.isNotEmpty) {
    final skipped = await WidgetHeroSkipStore.reconcileAndActiveIds(predictions);
    heroPredictions = filterPredictionsExcludingSkipped(predictions, skipped);
  }

  HomeWidgetRowPayload? hero;
  var recentLast = <HomeWidgetRowPayload>[];
  if (loggedIn && state == 'ready') {
    hero = buildWidgetHero(predictions: heroPredictions, now: t);
    // 后续留意用全量预测（含已 skip）；native large 再排除当前 hero id
    recentLast = buildWidgetRecentLast(predictions: predictions, count: 4);
    if (hero != null) {
      hero = await enrichWidgetRow(hero, catalog);
    }
    if (recentLast.isNotEmpty) {
      recentLast = await enrichWidgetRows(recentLast, catalog);
    }
  }

  return HomeWidgetPayload(
    state: state,
    message: message,
    widgetKind: 'large',
    header: header,
    visual: visual,
    hero: hero,
    recentLast: recentLast,
    tip: tip,
    rows: const [],
    updatedAt: t,
  );
}

Future<void> syncHomeWidgetFromRef(dynamic ref, {
  String? forceState,
  String? forceMessage,
  /// 冷启先出预测：跳过慢 tip chat，稍后单独 sync。
  bool skipTip = false,
}) async {
  if (kIsWeb) return;
  final visual = buildHomeWidgetVisualFromRef(ref);
  final loggedIn = ref.read(sessionProvider).isLoggedIn;
  if (!loggedIn) {
    await pushHomeWidgetPayload(
      HomeWidgetPayload(
        state: 'empty',
        message: HomeWidgetConstants.emptyMessage,
        visual: visual,
        updatedAt: DateTime.now(),
      ),
    );
    return;
  }

  final inputs = resolveWidgetPredictionInputs(ref);
  final history = inputs.history;
  final catalog = inputs.catalog;
  final disabledForecastIds = inputs.disabledForecastIds;
  final activeEventKeys = inputs.activeEventKeys;

  BabyProfile? baby;
  try {
    baby = await ref.read(settingsRepositoryProvider).loadBaby();
  } catch (e) {
    AppDebugLog.homeWidget('baby load err=$e');
  }

  var state = forceState ?? 'ready';
  String? message = forceMessage;
  if (state == 'ready') {
    final enabledHistory = _historyForEnabledForecast(
      history: history,
      catalog: catalog,
      disabledForecastIds: disabledForecastIds,
    );
    final enabledActiveKeys = {
      for (final k in activeEventKeys)
        if (!disabledForecastIds.contains(k)) k,
    };
    var preds = predictAllUpcoming(
      history: enabledHistory,
      catalog: catalog,
      now: DateTime.now(),
      birthDate: baby?.birthDate ?? DateTime.now(),
      activeEventKeys: enabledActiveKeys,
    );
    final skipped = await WidgetHeroSkipStore.reconcileAndActiveIds(preds);
    preds = filterPredictionsExcludingSkipped(preds, skipped);
    if (preds.isEmpty) {
      if (history.isEmpty) {
        state = 'empty';
        message = HomeWidgetConstants.emptyMessage;
      } else {
        state = 'ready';
        message = HomeWidgetConstants.noPredictionMessage;
      }
    }
  }

  HomeWidgetTipPayload? tip;
  if (state == 'ready' && !skipTip) {
    try {
      final now = DateTime.now();
      String? derived;
      var careReady = false;
      final gate = ref.read(predictionCareAlertFetchAllowedProvider);
      if (gate) {
        var st = ref.read(predictionCareAlertStateProvider);
        if (!st.ready && !st.loading && !st.failed) {
          await ref
              .read(predictionCareAlertStateProvider.notifier)
              .ensureLoaded();
          st = ref.read(predictionCareAlertStateProvider);
        }
        careReady = st.ready && !st.failed && !st.loading;
        if (careReady) {
          final items = ref.read(predictionCareAlertProvider);
          derived = deriveWidgetTipTextFromCareAlert(items);
        }
      }
      if (derived != null && derived.trim().isNotEmpty) {
        tip = await persistWidgetTipSnapshot(derivedText: derived, now: now);
      } else if (gate && careReady) {
        // 留意已 ready 且列表/摘要为空：清除 tip
        tip = await persistWidgetTipSnapshot(derivedText: null, now: now);
      } else {
        // 门闸未过或留意未 ready：保留 prefs 快照推 widget
        tip = await loadWidgetTipSnapshotFromPrefs(now: now);
      }
    } catch (e) {
      AppDebugLog.homeWidget('tip err=$e');
    }
  }

  final payload = await buildHomeWidgetPayload(
    loggedIn: true,
    baby: baby,
    history: history,
    catalog: catalog,
    state: state,
    visual: visual,
    message: message,
    tip: tip,
    disabledForecastIds: disabledForecastIds,
    activeEventKeysOverride: activeEventKeys,
  );
  await pushHomeWidgetPayload(payload);
  final tipBody = tip?.text.trim() ?? '';
  if (tipBody.isNotEmpty) {
    bumpWidgetTipDisplayEpoch(ref);
  }
}

Future<void> pushHomeWidgetPayload(HomeWidgetPayload payload) async {
  if (kIsWeb) return;
  try {
    final saved = await HomeWidget.saveWidgetData<String>(
      HomeWidgetConstants.payloadKey,
      payload.toJsonString(),
    );
    if (saved != true) {
      AppDebugLog.homeWidget('push saveWidgetData failed saved=$saved');
      return;
    }
    for (final name in [
      HomeWidgetConstants.androidSmallName,
      HomeWidgetConstants.androidMediumName,
      HomeWidgetConstants.androidLargeName,
    ]) {
      await HomeWidget.updateWidget(androidName: name, iOSName: HomeWidgetConstants.iOSWidgetName);
    }
    AppDebugLog.homeWidget(
      'push state=${payload.state} hero=${payload.hero != null} recent=${payload.recentLast.length} tip=${payload.tip != null}',
    );
  } catch (e) {
    AppDebugLog.homeWidget('push err=$e');
  }
}

Future<void> ensureWidgetReadyFromRef(dynamic ref) async {
  if (kIsWeb) return;
  if (!ref.read(sessionProvider).isLoggedIn) {
    await syncHomeWidgetFromRef(ref, skipTip: true);
    return;
  }
  // 内存 range 每次冷启都要 ensure；不得因 prefs depthReady 跳过（否则 loading 空窗）
  await syncHomeWidgetFromRef(
    ref,
    forceState: 'loading',
    forceMessage: HomeWidgetConstants.loadingMessage,
    skipTip: true,
  );
  await ensureWidgetHistoryDepth(ref);
  // 先推预测 payload（无 tip）；tip chat 可能 30s+，后台补推
  await syncHomeWidgetFromRef(ref, skipTip: true);
  unawaited(scheduleHomeWidgetSync(ref));
}

Future<void>? _widgetSyncInFlight;
var _widgetSyncRerun = false;

/// 历史/range/资料变更后推送小组件（single-flight，合并连续触发）。
/// 预测输入在 sync 内读 `predictionHistoryWithRecallSeedsProvider`，勿传 home 分页快照。
///
/// 须延迟到下一 event-loop turn：notifier 写入栈内 ref.read 同源 provider 会断言失败。
Future<void> scheduleHomeWidgetSync(dynamic ref) {
  if (kIsWeb) return Future.value();
  if (!ref.read(sessionProvider).isLoggedIn) return Future.value();

  return Future<void>(() => _scheduleHomeWidgetSyncNow(ref));
}

Future<void> _scheduleHomeWidgetSyncNow(dynamic ref) {
  if (_widgetSyncInFlight != null) {
    _widgetSyncRerun = true;
    return _widgetSyncInFlight!;
  }

  return _widgetSyncInFlight = _runWidgetSyncLoop(ref).whenComplete(() {
    _widgetSyncInFlight = null;
  });
}

Future<void> _runWidgetSyncLoop(dynamic ref) async {
  do {
    _widgetSyncRerun = false;
    await syncHomeWidgetFromRef(ref);
  } while (_widgetSyncRerun);
}

Future<void> onHomeHistoryChangedForWidget(dynamic ref) {
  return scheduleHomeWidgetSync(ref);
}

/// 生效主题 visual 变化时推送小组件。
Future<void> scheduleHomeWidgetSyncIfThemeChanged(
  dynamic ref,
  ThemePreferences? previous,
  ThemePreferences next,
) async {
  if (kIsWeb) return;
  if (!ref.read(sessionProvider).isLoggedIn) return;
  final sex = ref.read(babySexProvider);
  if (!themeVisualChanged(previous, next, sex)) return;
  await scheduleHomeWidgetSync(ref);
}

Future<void> onLogoutClearHomeWidget() async {
  if (kIsWeb) return;
  await clearWidgetHistoryDepthReady();
  await clearWidgetTipCache();
  await WidgetHeroSkipStore.clearAll();
  await pushHomeWidgetPayload(
    HomeWidgetPayload(
      state: 'empty',
      message: HomeWidgetConstants.emptyMessage,
      updatedAt: DateTime.now(),
    ),
  );
}
