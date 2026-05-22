import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import 'event_catalog_paths.dart';
import 'event_definition.dart';

const _catalogFileName = 'catalog_v1.json';

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
        if (e is Map<String, dynamic>) {
          out.add(EventDefinition.fromJson(e));
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
    try {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(resolved));
        final response = await request.close();
        if (response.statusCode != 200) return null;
        final bytes = await response.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
        await dest.writeAsBytes(bytes);
        return dest.path;
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }

  static Future<List<EventDefinition>> applyLogoDownloads(List<EventDefinition> remote) async {
    if (!eventCatalogSupportsLocalFiles) return remote;
    final local = await loadFromDisk();
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
      final path = await downloadLogo(e.id, url);
      out.add(path == null ? e : e.copyWith(localLogoPath: path));
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
    if (e.name != o.name || e.colorRaw != o.colorRaw || e.logoUrl != o.logoUrl) {
      return false;
    }
  }
  return true;
}

List<EventDefinition> parseEventOptionsList(List<dynamic> list) {
  final out = <EventDefinition>[];
  for (final e in list) {
    if (e is! Map<String, dynamic>) continue;
    final def = EventDefinition.fromOptionsMap(e);
    if (def.id.isEmpty) continue;
    final logo = def.logoUrl;
    out.add(EventDefinition(
      id: def.id,
      name: def.name,
      logoUrl: logo == null ? null : resolveEventLogoUrl(logo),
      colorRaw: def.colorRaw,
    ));
  }
  return out;
}
