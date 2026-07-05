import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';

import '../data/event_catalog_paths.dart';
import '../data/event_definition.dart';
import 'home_widget_constants.dart';

/// 小组件可读 logo 目录：Android 用 temp；iOS 用 App Group（Extension 沙箱可读）。
Future<Directory> widgetLogoCacheDirectory() async {
  if (!kIsWeb && Platform.isIOS) {
    final provider = PathProviderFoundation();
    final groupPath = await provider.getContainerPath(
      appGroupIdentifier: HomeWidgetConstants.appGroupId,
    );
    if (groupPath != null && groupPath.isNotEmpty) {
      final dir = Directory('$groupPath/home_widget_logos');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }
  final cache = await getTemporaryDirectory();
  final dir = Directory('${cache.path}/home_widget_logos');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// 将事件 logo 拷到 cache，供 Android/iOS 小组件读取本地文件。
Future<String?> widgetLogoFileForEvent(EventDefinition? def) async {
  if (kIsWeb || def == null) return null;
  final local = def.localLogoPath?.trim();
  if (local == null || local.isEmpty) return null;
  final src = File(local);
  if (!await src.exists()) return null;

  final dir = await widgetLogoCacheDirectory();
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
