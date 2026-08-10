import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';

import '../api/app_debug_log.dart';
import '../data/baby_age.dart';
import '../data/event_catalog_store.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../data/models.dart';
import '../providers/home_history_notifier.dart';
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

  final activeKeys = collectActiveTimingRows(history, catalog: catalog)
      .map((e) => e.eventId)
      .where((e) => e.isNotEmpty)
      .toSet();
  final birth = baby?.birthDate ?? DateTime(t.year, 1, 1);
  final predictions = loggedIn
      ? predictAllUpcoming(
          history: history,
          catalog: catalog,
          now: t,
          birthDate: birth,
          activeEventKeys: activeKeys,
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
  /// 热路径传入避免在 homeHistory 更新栈内 read 自依赖。
  List<HistoryRecord>? historyOverride,
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

  // 有 override 不再 read homeHistoryProvider（WS/setItems 同步栈内会自依赖）
  final history =
      historyOverride ?? ref.read(homeHistoryProvider).items;
  List<EventDefinition> catalog = const [];
  try {
    catalog = await EventCatalogStore.loadFromDisk();
  } catch (e) {
    AppDebugLog.homeWidget('catalog disk err=$e');
  }

  BabyProfile? baby;
  try {
    baby = await ref.read(settingsRepositoryProvider).loadBaby();
  } catch (e) {
    AppDebugLog.homeWidget('baby load err=$e');
  }

  var state = forceState ?? 'ready';
  String? message = forceMessage;
  if (state == 'ready') {
    final active = collectActiveTimingRows(history, catalog: catalog);
    final activeKeys = active.map((e) => e.eventId).toSet();
    var preds = predictAllUpcoming(
      history: history,
      catalog: catalog,
      now: DateTime.now(),
      birthDate: baby?.birthDate ?? DateTime.now(),
      activeEventKeys: activeKeys,
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
      tip = await resolveWidgetTip(
        feed: ref.read(feedRepositoryProvider),
        now: DateTime.now(),
      );
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
/// 合并连续触发时保留最新 history 快照。
List<HistoryRecord>? _pendingHistoryOverride;

/// 历史变更后推送小组件（single-flight，合并连续触发）。
/// [history]：调用方已持有的列表快照；热路径（homeHistory 更新内）必须传入。
Future<void> scheduleHomeWidgetSync(
  dynamic ref, {
  List<HistoryRecord>? history,
}) {
  if (kIsWeb) return Future.value();
  if (!ref.read(sessionProvider).isLoggedIn) return Future.value();

  if (history != null) {
    _pendingHistoryOverride = List<HistoryRecord>.from(history);
  }

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
    final override = _pendingHistoryOverride;
    _pendingHistoryOverride = null;
    await syncHomeWidgetFromRef(ref, historyOverride: override);
  } while (_widgetSyncRerun);
}

Future<void> onHomeHistoryChangedForWidget(
  dynamic ref, {
  List<HistoryRecord>? history,
}) {
  return scheduleHomeWidgetSync(ref, history: history);
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
