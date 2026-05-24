import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// 主页历史调试日志（静态方法，避免 Hot Reload 顶层符号丢失）。
abstract final class HomeHistoryLog {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[HomeHistory] ${DateTime.now().toIso8601String()} $message');
    }
  }
}

const _historyFileSuffix = '_v1.json';

bool get homeHistorySupportsLocalFiles => !kIsWeb;

String safeHomeHistoryFileStem(String deviceNo) {
  final stem = deviceNo.replaceAll(RegExp(r'[^\w.-]'), '_');
  return stem.isEmpty ? 'device' : stem;
}

/// 主页历史列表本地持久化（按 deviceNo 分文件；Web 不写盘）。
class HomeHistoryStore {
  static Future<Directory?> _rootDir() async {
    if (!homeHistorySupportsLocalFiles) return null;
    final doc = await getApplicationDocumentsDirectory();
    final root = Directory('${doc.path}/home_history');
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  static Future<File?> _historyFile(String deviceNo) async {
    if (deviceNo.isEmpty) return null;
    final root = await _rootDir();
    if (root == null) return null;
    return File('${root.path}/history_${safeHomeHistoryFileStem(deviceNo)}$_historyFileSuffix');
  }

  /// 读取缓存；`_items` 升序（旧→新）。
  static Future<List<HistoryRecord>> load(String deviceNo) async {
    final sw = Stopwatch()..start();
    HomeHistoryLog.d('cache load start deviceNo=$deviceNo');
    if (!homeHistorySupportsLocalFiles) {
      HomeHistoryLog.d('cache load skip: Web platform');
      return const [];
    }
    final file = await _historyFile(deviceNo);
    if (file == null) {
      HomeHistoryLog.d('cache load miss: no file path');
      return const [];
    }
    final path = file.path;
    if (!await file.exists()) {
      HomeHistoryLog.d('cache load miss: file not exists path=$path');
      return const [];
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        HomeHistoryLog.d('cache load error: root is not List path=$path');
        return const [];
      }
      final out = <HistoryRecord>[];
      for (final e in decoded) {
        if (e is Map) {
          final r = HistoryRecord.fromJson(Map<String, dynamic>.from(e));
          if (r.id.isNotEmpty) out.add(r);
        }
      }
      sw.stop();
      HomeHistoryLog.d(
        'cache load ok count=${out.length} elapsed=${sw.elapsedMilliseconds}ms path=$path',
      );
      return out;
    } catch (e) {
      sw.stop();
      HomeHistoryLog.d('cache load error: $e path=$path elapsed=${sw.elapsedMilliseconds}ms');
      return const [];
    }
  }

  static Future<void> save(String deviceNo, List<HistoryRecord> items) async {
    final file = await _historyFile(deviceNo);
    if (file == null) {
      HomeHistoryLog.d('cache save skip: no file path deviceNo=$deviceNo');
      return;
    }
    try {
      final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded);
      HomeHistoryLog.d('cache save ok count=${items.length} path=${file.path}');
    } catch (e) {
      HomeHistoryLog.d('cache save error: $e deviceNo=$deviceNo');
    }
  }
}

const _snapshotPayloadKeys = ['startTime', 'endTime', 'eventNumber', 'remark', 'eventId'];

bool _payloadFieldEqual(Object? a, Object? b) {
  if (a == b) return true;
  if (a is num && b is num) return a == b;
  return a?.toString() == b?.toString();
}

bool _recordSnapshotEqual(HistoryRecord a, HistoryRecord b) {
  if (a.id != b.id) return false;
  if (a.eventName != b.eventName) return false;
  if (a.action != b.action) return false;
  for (final key in _snapshotPayloadKeys) {
    if (!_payloadFieldEqual(a.rawPayload[key], b.rawPayload[key])) return false;
  }
  return true;
}

/// 比较主页 `_items` 顺序快照（升序）。
bool historySnapshotsEqual(List<HistoryRecord> a, List<HistoryRecord> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_recordSnapshotEqual(a[i], b[i])) return false;
  }
  return true;
}

/// API 返回（新→旧）转 `_items` 升序。
List<HistoryRecord> historyListToHomeAsc(List<HistoryRecord> apiDesc) {
  return apiDesc.reversed.toList();
}
