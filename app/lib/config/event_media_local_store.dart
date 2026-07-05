import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pangbao_app/home_widget/home_widget_payload.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 同步关闭时 history 事件本地媒体映射与文件复制。
class EventMediaLocalStore {
  static const _keyPrefix = 'event_media_local_v1_';
  static const _mediaRoot = 'history_media';

  static Future<List<EventMediaLocalEntry>> loadEntries(String historyId) async {
    if (historyId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$historyId');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const [];
      final items = decoded['items'];
      if (items is! List) return const [];
      final out = <EventMediaLocalEntry>[];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final kind = item['kind'] as String? ?? '';
        final relativePath = item['relativePath'] as String? ?? '';
        final sort = (item['sort'] as num?)?.toInt() ?? 0;
        if (relativePath.isEmpty) continue;
        if (kind != 'image' && kind != 'video') continue;
        out.add(EventMediaLocalEntry(
          kind: kind,
          relativePath: relativePath,
          sort: sort,
        ));
      }
      out.sort((a, b) => a.sort.compareTo(b.sort));
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<File?> resolveFile(String relativePath) async {
    if (relativePath.isEmpty || kIsWeb) return null;
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/$relativePath');
    if (!await file.exists()) return null;
    return file;
  }

  static Future<void> saveEntries(String historyId, List<EventMediaLocalEntry> entries) async {
    if (historyId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (entries.isEmpty) {
      await _deleteHistoryMediaDir(historyId);
      await prefs.remove('$_keyPrefix$historyId');
      return;
    }
    final payload = {
      'items': entries
          .map((e) => {
                'kind': e.kind,
                'relativePath': e.relativePath,
                'sort': e.sort,
              })
          .toList(),
      'updatedAt': HomeWidgetRowPayload.isoUtc(DateTime.now()),
    };
    await prefs.setString('$_keyPrefix$historyId', jsonEncode(payload));
  }

  /// 将 [sourceFiles] 复制到 `documents/history_media/{historyId}/` 并更新映射。
  /// 已在本目录内的文件会保留（删除/重排时不会先删后拷导致 PathNotFound）。
  static Future<List<EventMediaLocalEntry>> persistLocalMedia({
    required String historyId,
    required List<({String kind, File file})> sourceFiles,
  }) async {
    if (historyId.isEmpty || kIsWeb) return const [];
    final docs = await getApplicationDocumentsDirectory();
    final mediaDirPath = '${docs.path}/$_mediaRoot/$historyId';
    final dir = Directory(mediaDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final keptSourcePaths = <String>{
      for (final item in sourceFiles)
        if (await item.file.exists()) _normalizePath(item.file.absolute.path),
    };

    final existing = await loadEntries(historyId);
    for (final e in existing) {
      final old = await resolveFile(e.relativePath);
      if (old == null || !await old.exists()) continue;
      if (keptSourcePaths.contains(_normalizePath(old.absolute.path))) continue;
      await old.delete();
    }

    final out = <EventMediaLocalEntry>[];
    for (var i = 0; i < sourceFiles.length; i++) {
      final item = sourceFiles[i];
      final source = item.file;
      if (!await source.exists()) continue;

      final normalizedSource = _normalizePath(source.absolute.path);
      if (_isUnderDirectory(normalizedSource, _normalizePath(mediaDirPath))) {
        out.add(EventMediaLocalEntry(
          kind: item.kind,
          relativePath: _relativePathFromDocs(docs.path, source),
          sort: i,
        ));
        continue;
      }

      final ext = _fileExtension(source.path);
      final name = '${item.kind}_$i${ext.isEmpty ? (item.kind == 'video' ? '.mp4' : '.jpg') : ext}';
      final relativePath = '$_mediaRoot/$historyId/$name';
      final dest = File('${docs.path}/$relativePath');
      await source.copy(dest.path);
      out.add(EventMediaLocalEntry(kind: item.kind, relativePath: relativePath, sort: i));
    }
    await saveEntries(historyId, out);
    return out;
  }

  static Future<void> _deleteHistoryMediaDir(String historyId) async {
    if (historyId.isEmpty || kIsWeb) return;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_mediaRoot/$historyId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// 删除 `history_media/` 下全部文件并清空所有映射键。
  static Future<void> clearAll() async {
    if (!kIsWeb) {
      final docs = await getApplicationDocumentsDirectory();
      final root = Directory('${docs.path}/$_mediaRoot');
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

class EventMediaLocalEntry {
  const EventMediaLocalEntry({
    required this.kind,
    required this.relativePath,
    required this.sort,
  });

  final String kind;
  final String relativePath;
  final int sort;

  bool get isVideo => kind == 'video';
  bool get isImage => kind == 'image';
}

String _fileExtension(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot >= path.length - 1) return '';
  return path.substring(dot);
}

String _normalizePath(String path) => path.replaceAll('\\', '/');

bool _isUnderDirectory(String filePath, String dirPath) {
  final dirWithSep = dirPath.endsWith('/') ? dirPath : '$dirPath/';
  return filePath == dirPath || filePath.startsWith(dirWithSep);
}

String _relativePathFromDocs(String docsPath, File file) {
  final prefix = _normalizePath('${Directory(docsPath).absolute.path}/');
  final abs = _normalizePath(file.absolute.path);
  if (abs.startsWith(prefix)) {
    return abs.substring(prefix.length);
  }
  return abs;
}
