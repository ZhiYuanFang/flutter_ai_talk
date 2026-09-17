import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';
import '../data/event_catalog_store.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../data/models.dart';
import '../theme/custom_background_persist.dart';
import 'home_widget_sync.dart';
import 'widget_hero_skip_store.dart';
import 'widget_prediction_snapshot.dart';
import 'widget_row_enrich.dart';
import 'widget_theme_visual.dart';

/// 交互 URI：pangbao-widget://skip?eventId=
const kWidgetSkipUriScheme = 'pangbao-widget';
const kWidgetSkipUriHost = 'skip';

String widgetSkipUriForEventId(String eventId) =>
    '$kWidgetSkipUriScheme://$kWidgetSkipUriHost?eventId=${Uri.encodeQueryComponent(eventId)}';

/// 注册小组件交互回调（须在 setAppGroupId 之后）。
Future<void> registerHomeWidgetInteractivity() async {
  if (kIsWeb) return;
  try {
    await HomeWidget.registerInteractivityCallback(homeWidgetInteractiveCallback);
    AppDebugLog.homeWidget('interactivity registered');
  } catch (e) {
    AppDebugLog.homeWidget('interactivity register err=$e');
  }
}

/// home_widget 后台入口：解析 skip URI 并重推 payload。
@pragma('vm:entry-point')
Future<void> homeWidgetInteractiveCallback(Uri? uri) async {
  if (kIsWeb) return;
  try {
    await HomeWidget.setAppGroupId(HomeWidgetConstants.appGroupId);
    if (uri == null) return;
    // 期望 pangbao-widget://skip?eventId=
    if (uri.scheme != kWidgetSkipUriScheme || uri.host != kWidgetSkipUriHost) {
      AppDebugLog.homeWidget('interactivity ignore uri=$uri');
      return;
    }
    final eventId = uri.queryParameters['eventId']?.trim() ?? '';
    if (eventId.isEmpty) {
      AppDebugLog.homeWidget('interactivity skip missing eventId uri=$uri');
      return;
    }
    AppDebugLog.homeWidget('interactivity skip eventId=$eventId');
    await applyWidgetHeroSkipAndRefresh(eventId);
  } catch (e) {
    AppDebugLog.homeWidget('interactivity err=$e');
  }
}

/// 写入 skip 并用预测结果快照重建小组件（不依赖 Riverpod / 不用喂养分页重算）。
Future<void> applyWidgetHeroSkipAndRefresh(String eventId) async {
  final prefs = await SharedPreferences.getInstance();
  final dn = prefs.getString('pangbao_device_no_v1')?.trim() ?? '';
  if (dn.isEmpty) {
    AppDebugLog.homeWidget('skip refresh abort: no deviceNo');
    return;
  }

  final now = DateTime.now();
  final snapshotPreds = await WidgetPredictionSnapshotStore.loadPredictions();
  final prevPayload = await _loadLastPayload();
  final visual = prevPayload?.visual ?? await _visualFromLastPayloadOrDefault();
  final header = prevPayload?.header;
  final catalog = await EventCatalogStore.loadFromDisk();

  if (snapshotPreds.isNotEmpty) {
    await _skipRebuildFromSnapshot(
      eventId: eventId,
      predictions: snapshotPreds,
      now: now,
      visual: visual,
      header: header,
      catalog: catalog,
    );
    return;
  }

  // 快照缺失：用上一份 ready payload 晋升，保 large 槽位
  AppDebugLog.homeWidget('skip degrade: no prediction snapshot');
  await _skipRebuildFromPrevPayload(
    eventId: eventId,
    prev: prevPayload,
    now: now,
    visual: visual,
    catalog: catalog,
  );
}

Future<void> _skipRebuildFromSnapshot({
  required String eventId,
  required List<EventNextPrediction> predictions,
  required DateTime now,
  required HomeWidgetVisualPayload visual,
  required HomeWidgetHeaderPayload? header,
  required List<EventDefinition> catalog,
}) async {
  var baseline = now;
  for (final p in predictions) {
    if (p.eventId == eventId) {
      baseline = p.lastAt;
      break;
    }
  }
  await WidgetHeroSkipStore.skipEvent(
    eventId: eventId,
    baselineLastAt: baseline,
  );

  final skipped = await WidgetHeroSkipStore.reconcileAndActiveIds(predictions);
  final heroPredictions =
      filterPredictionsExcludingSkipped(predictions, skipped);
  var hero = buildWidgetHero(predictions: heroPredictions, now: now);
  final heroEventId = hero?.eventId;
  final predsForRecent = heroEventId != null
      ? predictions.where((p) => p.eventId != heroEventId).toList()
      : predictions;
  var recentLast = buildWidgetRecentLast(predictions: predsForRecent, count: 6);

  if (hero != null) {
    hero = await enrichWidgetRow(hero, catalog);
  }
  if (recentLast.isNotEmpty) {
    recentLast = await enrichWidgetRows(recentLast, catalog);
  }

  if (hero == null && recentLast.isEmpty) {
    await pushHomeWidgetPayload(
      HomeWidgetPayload(
        state: 'ready',
        message: HomeWidgetConstants.noPredictionMessage,
        widgetKind: 'large',
        header: header,
        visual: visual,
        tip: null,
        updatedAt: now,
      ),
    );
    return;
  }

  await pushHomeWidgetPayload(
    HomeWidgetPayload(
      state: 'ready',
      widgetKind: 'large',
      header: header,
      visual: visual,
      hero: hero,
      recentLast: recentLast,
      tip: null,
      updatedAt: now,
    ),
  );
}

Future<void> _skipRebuildFromPrevPayload({
  required String eventId,
  required HomeWidgetPayload? prev,
  required DateTime now,
  required HomeWidgetVisualPayload visual,
  required List<EventDefinition> catalog,
}) async {
  if (prev == null || prev.state != 'ready') {
    AppDebugLog.homeWidget('skip degrade abort: no ready payload');
    await WidgetHeroSkipStore.skipEvent(
      eventId: eventId,
      baselineLastAt: now,
    );
    return;
  }

  // 基线：优先 previous recent 同 id 的 lastAt，否则 now
  var baseline = now;
  for (final r in prev.recentLast) {
    if (r.eventId == eventId && r.lastAt != null) {
      final parsed = DateTime.tryParse(r.lastAt!);
      if (parsed != null) baseline = parsed;
      break;
    }
  }
  await WidgetHeroSkipStore.skipEvent(
    eventId: eventId,
    baselineLastAt: baseline,
  );

  final skipped = await WidgetHeroSkipStore.loadMap();
  final activeSkipIds = skipped.keys.toSet();

  // 从 recentLast 晋升下一条未 skip 的为 hero；其余 recent 保持（槽位不塌）
  HomeWidgetRowPayload? newHero;
  final remaining = <HomeWidgetRowPayload>[];
  for (final r in prev.recentLast) {
    if (newHero == null &&
        r.eventId != eventId &&
        !activeSkipIds.contains(r.eventId)) {
      newHero = HomeWidgetRowPayload(
        kind: 'predict',
        eventId: r.eventId,
        name: r.name,
        nextAt: r.nextAt ?? r.lastAt,
        status: 'upcoming',
        color: r.color,
        logoFile: r.logoFile,
      );
      continue;
    }
    remaining.add(r);
  }

  var hero = newHero;
  var recentLast = remaining.take(6).toList();
  if (hero != null) {
    hero = await enrichWidgetRow(hero, catalog);
  }
  if (recentLast.isNotEmpty) {
    recentLast = await enrichWidgetRows(recentLast, catalog);
  }

  if (hero == null && recentLast.isEmpty) {
    await pushHomeWidgetPayload(
      HomeWidgetPayload(
        state: 'ready',
        message: HomeWidgetConstants.noPredictionMessage,
        widgetKind: 'large',
        header: prev.header,
        visual: visual,
        tip: null,
        updatedAt: now,
      ),
    );
    return;
  }

  await pushHomeWidgetPayload(
    HomeWidgetPayload(
      state: 'ready',
      widgetKind: 'large',
      header: prev.header,
      visual: visual,
      hero: hero,
      recentLast: recentLast,
      tip: null,
      updatedAt: now,
    ),
  );
}

Future<HomeWidgetPayload?> _loadLastPayload() async {
  try {
    final raw = await HomeWidget.getWidgetData<String>(
      HomeWidgetConstants.payloadKey,
    );
    if (raw == null || raw.isEmpty) return null;
    return HomeWidgetPayload.parse(raw);
  } catch (e) {
    AppDebugLog.homeWidget('skip load payload err=$e');
    return null;
  }
}

Future<HomeWidgetVisualPayload> _visualFromLastPayloadOrDefault() async {
  try {
    final raw = await HomeWidget.getWidgetData<String>(
      HomeWidgetConstants.payloadKey,
    );
    if (raw != null && raw.isNotEmpty) {
      final prev = HomeWidgetPayload.parse(raw);
      if (prev != null) return prev.visual;
    }
  } catch (e) {
    AppDebugLog.homeWidget('skip visual load err=$e');
  }
  return buildHomeWidgetVisual(
    sex: BabySex.unknown,
    prefs: const ThemePreferences(),
  );
}
