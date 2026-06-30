import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import 'event_catalog_paths.dart';
import 'event_definition.dart';

const _catalogFileName = 'catalog_v1.json';

/// 跟踪进行中的 logo `HttpClient`，供 `cancelLogoDownloads` 强制关闭释放连接槽。
final Set<HttpClient> _activeLogoDownloadClients = {};

/// 强制关闭所有进行中的 logo 下载 HTTP 连接（同步，不等待 body）。
void abortActiveLogoDownloads() {
  for (final client in _activeLogoDownloadClients.toList()) {
    try {
      client.close(force: true);
    } catch (_) {}
  }
  _activeLogoDownloadClients.clear();
}

/// 事件目录与 logo 文件的本地持久化（非 Web 写文件；Web 仅内存）。
class EventCatalogStore {
  static Future<Directory?> _rootDir() async {
    if (kIsWeb) return null;
    final doc = await getApplicationDocumentsDirectory();
    final root = Directory('${doc.path}/event_catalog');
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  static Future<Directory?> _logosDir() async {
    final root = await _rootDir();
    if (root == null) return null;
    final logos = Directory('${root.path}/logos');
    if (!await logos.exists()) {
      await logos.create(recursive: true);
    }
    return logos;
  }

  static Future<File?> _catalogFile() async {
    final root = await _rootDir();
    if (root == null) return null;
    return File('${root.path}/$_catalogFileName');
  }

  static Future<List<EventDefinition>> loadFromDisk() async {
    final file = await _catalogFile();
    if (file == null || !await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      final out = <EventDefinition>[];
      for (final e in decoded) {
        if (e is Map) {
          out.add(EventDefinition.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveToDisk(List<EventDefinition> items) async {
    final file = await _catalogFile();
    if (file == null) return;
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await file.writeAsString(encoded);
  }

  static Future<void> deleteLogoFile(String? localPath) async {
    if (!eventCatalogSupportsLocalFiles || localPath == null) return;
    try {
      final f = File(localPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static Future<void> pruneLogoFiles(Set<String> keepLocalPaths) async {
    final logos = await _logosDir();
    if (logos == null) return;
    await for (final entity in logos.list()) {
      if (entity is! File) continue;
      if (!keepLocalPaths.contains(entity.path)) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  static Future<String?> downloadLogo(String eventId, String logoUrl) async {
    if (!eventCatalogSupportsLocalFiles) return null;
    final logos = await _logosDir();
    if (logos == null) return null;
    final resolved = resolveEventLogoUrl(logoUrl);
    if (resolved == null) return null;
    final stem = safeEventLogoFileStem(eventId);
    final ext = logoFileExtensionFromUrl(resolved);
    final dest = File('${logos.path}/$stem.$ext');
    HttpClient? client;
    try {
      client = HttpClient();
      _activeLogoDownloadClients.add(client);
      final request = await client.getUrl(Uri.parse(resolved));
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final bytes = await response.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
      await dest.writeAsBytes(bytes);
      return dest.path;
    } catch (_) {
      return null;
    } finally {
      if (client != null) {
        _activeLogoDownloadClients.remove(client);
        client.close();
      }
    }
  }

  /// 将 [local] 中仍有效的 `localLogoPath` 合并进 [remote]（同 id 且 logoUrl 未变）。
  static Future<List<EventDefinition>> mergeLocalLogoPaths(
    List<EventDefinition> remote,
    List<EventDefinition> local,
  ) async {
    if (!eventCatalogSupportsLocalFiles) return remote;
    final prevById = {for (final e in local) e.id: e};
    final out = <EventDefinition>[];
    for (final e in remote) {
      final url = e.logoUrl;
      if (url == null || url.isEmpty) {
        out.add(e.copyWith(clearLocalLogoPath: true));
        continue;
      }
      final prev = prevById[e.id];
      if (prev?.logoUrl == url &&
          prev?.localLogoPath != null &&
          await File(prev!.localLogoPath!).exists()) {
        out.add(e.copyWith(localLogoPath: prev.localLogoPath));
        continue;
      }
      out.add(e);
    }
    return out;
  }

  /// 单事件 logo：复用磁盘路径或下载；供后台并发池调用。
  static Future<EventDefinition> downloadLogoIfNeeded(
    EventDefinition event,
    Map<String, EventDefinition> prevById,
  ) async {
    if (!eventCatalogSupportsLocalFiles) return event;
    final url = event.logoUrl;
    if (url == null || url.isEmpty) {
      return event.copyWith(clearLocalLogoPath: true);
    }
    final prev = prevById[event.id];
    if (prev?.logoUrl == url &&
        prev?.localLogoPath != null &&
        await File(prev!.localLogoPath!).exists()) {
      return event.copyWith(localLogoPath: prev.localLogoPath);
    }
    final localPath = event.localLogoPath;
    if (localPath != null &&
        localPath.isNotEmpty &&
        await File(localPath).exists()) {
      return event;
    }
    final path = await downloadLogo(event.id, url);
    return path == null ? event : event.copyWith(localLogoPath: path);
  }

  static Future<List<EventDefinition>> applyLogoDownloads(List<EventDefinition> remote) async {
    if (!eventCatalogSupportsLocalFiles) return remote;
    final local = await loadFromDisk();
    final prevById = {for (final e in local) e.id: e};
    final out = <EventDefinition>[];
    for (final e in remote) {
      out.add(await downloadLogoIfNeeded(e, prevById));
      prevById[e.id] = out.last;
    }
    return out;
  }
}

bool catalogSnapshotsEqual(List<EventDefinition> a, List<EventDefinition> b) {
  if (a.length != b.length) return false;
  final mapB = {for (final e in b) e.id: e};
  for (final e in a) {
    final o = mapB[e.id];
    if (o == null) return false;
    if (e.name != o.name ||
        e.colorRaw != o.colorRaw ||
        e.logoUrl != o.logoUrl ||
        e.eventType != o.eventType ||
        e.extraNames != o.extraNames ||
        e.parentId != o.parentId) {
      return false;
    }
  }
  return true;
}

List<EventDefinition> parseEventOptionsList(List<dynamic> list) {
  final out = <EventDefinition>[];
  for (final e in list) {
    if (e is! Map) continue;
    final def = EventDefinition.fromOptionsMap(Map<String, dynamic>.from(e));
    if (def.id.isEmpty) continue;
    final logo = def.logoUrl;
    out.add(EventDefinition(
      id: def.id,
      name: def.name,
      logoUrl: logo == null ? null : resolveEventLogoUrl(logo),
      colorRaw: def.colorRaw,
      eventType: def.eventType,
      extraNames: def.extraNames,
      parentId: def.parentId,
    ));
  }
  return out;
}
