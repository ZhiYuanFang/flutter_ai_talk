import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../data/event_catalog_paths.dart';
import '../data/event_definition.dart';

/// 将事件 logo 拷到 cache，供 Android/iOS 小组件读取本地文件。
Future<String?> widgetLogoFileForEvent(EventDefinition? def) async {
  if (kIsWeb || def == null) return null;
  final local = def.localLogoPath?.trim();
  if (local == null || local.isEmpty) return null;
  final src = File(local);
  if (!await src.exists()) return null;

  final cache = await getTemporaryDirectory();
  final dir = Directory('${cache.path}/home_widget_logos');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final ext = logoFileExtensionFromUrl(def.logoUrl ?? local);
  final dest = File('${dir.path}/${def.id}.$ext');
  try {
    final srcMod = await src.lastModified();
    if (!await dest.exists() || srcMod.isAfter(await dest.lastModified())) {
      await src.copy(dest.path);
    }
    return dest.path;
  } catch (_) {
    return null;
  }
}
