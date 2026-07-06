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
import '../theme/app_theme_scope.dart';
import '../theme/custom_background_persist.dart';
import 'home_widget_constants.dart';
import 'home_widget_payload.dart';
import 'widget_history_depth.dart';
import 'widget_row_builder.dart';
import 'widget_row_enrich.dart';
import 'widget_theme_visual.dart';
import 'widget_tip_cache.dart';

export 'format_widget_relative_time.dart';
export 'home_widget_constants.dart';
export 'home_widget_payload.dart';
export 'widget_row_builder.dart';

Future<void> initHomeWidgetBridge() async {
  if (kIsWeb) return;
  try {
    await HomeWidget.setAppGroupId(HomeWidgetConstants.appGroupId);
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

  HomeWidgetRowPayload? hero;
  var recentLast = <HomeWidgetRowPayload>[];
  if (loggedIn && state == 'ready') {
    hero = buildWidgetHero(predictions: predictions, now: t);
    // Exclude hero from recent list so native widget can fill up to 3 recent slots.
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

  final history = ref.read(homeHistoryProvider).items;
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
    final preds = predictAllUpcoming(
      history: history,
      catalog: catalog,
      now: DateTime.now(),
      birthDate: baby?.birthDate ?? DateTime.now(),
      activeEventKeys: activeKeys,
    );
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
  if (state == 'ready') {
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
    await syncHomeWidgetFromRef(ref);
    return;
  }
  final depthReady = await readWidgetHistoryDepthReady();
  if (!depthReady) {
    await syncHomeWidgetFromRef(
      ref,
      forceState: 'loading',
      forceMessage: HomeWidgetConstants.loadingMessage,
    );
    await ensureWidgetHistoryDepth(ref);
  }
  await syncHomeWidgetFromRef(ref);
}

Future<void>? _widgetSyncInFlight;
var _widgetSyncRerun = false;

/// 历史变更后推送小组件（single-flight，合并连续触发）。
Future<void> scheduleHomeWidgetSync(dynamic ref) {
  if (kIsWeb) return Future.value();
  if (!ref.read(sessionProvider).isLoggedIn) return Future.value();

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
  await pushHomeWidgetPayload(
    HomeWidgetPayload(
      state: 'empty',
      message: HomeWidgetConstants.emptyMessage,
      updatedAt: DateTime.now(),
    ),
  );
}
