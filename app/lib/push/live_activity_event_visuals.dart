import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:home_widget/home_widget.dart';

import '../api/app_debug_log.dart';
import '../data/event_definition.dart';
import '../data/event_next_predictor.dart';
import '../home_widget/home_widget_constants.dart';
import '../home_widget/widget_logo_cache.dart';

/// 将事件目录色、可选本地名与 App Group logo 写入 `laEventVisuals`，供 Live Activity Extension 按 eventId 查找。
Future<void> syncLiveActivityEventVisuals(
  List<EventDefinition> catalog,
) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
  if (catalog.isEmpty) return;
  try {
    await HomeWidget.setAppGroupId(HomeWidgetConstants.appGroupId);
    final map = <String, Map<String, String>>{};
    for (final def in catalog) {
      final id = def.id.trim();
      if (id.isEmpty) continue;
      final absLogo = await widgetLogoFileForEvent(def);
      final rel = _logoRelPath(absLogo);
      // Island 用本地短名；锁屏仍吃推送 title/eventName
      final localName = def.name.trim();
      map[id] = {
        'color': colorHexFromEvent(def),
        if (localName.isNotEmpty) 'name': localName,
        if (rel != null) 'logoFile': rel,
      };
    }
    final json = jsonEncode(map);
    final saved = await HomeWidget.saveWidgetData<String>(
      HomeWidgetConstants.laEventVisualsKey,
      json,
    );
    AppDebugLog.liveActivity(
      'laEventVisuals saved=${saved == true} count=${map.length}',
    );
  } catch (e) {
    AppDebugLog.liveActivity('laEventVisuals err=$e');
  }
}

/// 绝对路径 → Extension 可用的相对路径 `home_widget_logos/...`。
String? _logoRelPath(String? abs) {
  if (abs == null || abs.isEmpty) return null;
  final norm = abs.replaceAll('\\', '/');
  const marker = 'home_widget_logos/';
  final i = norm.indexOf(marker);
  if (i >= 0) return norm.substring(i);
  // 兜底：仅文件名时仍尝试约定目录
  final name = File(abs).uri.pathSegments.isEmpty
      ? null
      : File(abs).uri.pathSegments.last;
  if (name == null || name.isEmpty) return null;
  return '$marker$name';
}
