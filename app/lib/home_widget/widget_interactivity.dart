import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_debug_log.dart';
import '../data/event_catalog_store.dart';
import '../data/event_next_predictor.dart';
import '../data/home_history_store.dart';
import '../data/models.dart';
import '../theme/custom_background_persist.dart';
import 'home_widget_constants.dart';
import 'home_widget_sync.dart';
import 'widget_hero_skip_store.dart';
import 'widget_theme_visual.dart';
import 'widget_tip_cache.dart';

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

/// 写入 skip 并用磁盘历史重建小组件（不依赖前台 Riverpod / 不拉 tip 网络）。
Future<void> applyWidgetHeroSkipAndRefresh(String eventId) async {
  final prefs = await SharedPreferences.getInstance();
  final dn = prefs.getString('pangbao_device_no_v1')?.trim() ?? '';
  if (dn.isEmpty) {
    AppDebugLog.homeWidget('skip refresh abort: no deviceNo');
    return;
  }

  final historySnap = await HomeHistoryStore.loadSnapshot(dn);
  final history = historySnap.items;
  final catalog = await EventCatalogStore.loadFromDisk();
  final now = DateTime.now();
  BabyProfile? baby = await _loadBabyFromPrefs(dn);
  final birth = baby?.birthDate ?? DateTime(now.year, 1, 1);
  final activeKeys = collectActiveTimingRows(history, catalog: catalog)
      .map((e) => e.eventId)
      .where((e) => e.isNotEmpty)
      .toSet();
  final predictions = predictAllUpcoming(
    history: history,
    catalog: catalog,
    now: now,
    birthDate: birth,
    activeEventKeys: activeKeys,
  );

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

  final visual = await _visualFromLastPayloadOrDefault();
  HomeWidgetTipPayload? tip;
  final tipText = prefs.getString(kWidgetTipTextKey)?.trim() ?? '';
  if (tipText.isNotEmpty) {
    tip = HomeWidgetTipPayload(text: tipText, fetchedAt: now);
  }

  final payload = await buildHomeWidgetPayload(
    loggedIn: true,
    baby: baby,
    history: history,
    catalog: catalog,
    state: 'ready',
    visual: visual,
    tip: tip,
    now: now,
  );
  // 全被 skip 时补文案
  if (payload.hero == null &&
      payload.recentLast.isEmpty &&
      history.isNotEmpty) {
    await pushHomeWidgetPayload(
      HomeWidgetPayload(
        state: 'ready',
        message: HomeWidgetConstants.noPredictionMessage,
        widgetKind: payload.widgetKind,
        header: payload.header,
        visual: visual,
        tip: tip,
        updatedAt: now,
      ),
    );
    return;
  }
  await pushHomeWidgetPayload(payload);
}

Future<BabyProfile?> _loadBabyFromPrefs(String deviceNo) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('pangbao_baby_profile_$deviceNo');
  if (raw == null || raw.isEmpty) return null;
  try {
    return BabyProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (e) {
    AppDebugLog.homeWidget('skip baby prefs err=$e');
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
  } catch (_) {}
  return buildHomeWidgetVisual(
    sex: BabySex.unknown,
    prefs: const ThemePreferences(),
  );
}
