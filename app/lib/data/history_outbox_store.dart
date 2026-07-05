import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'home_history_store.dart';

const _outboxFileSuffix = '_updates_v1.json';
const _addsFileSuffix = '_adds_v1.json';

/// UPDATE outbox 队列项（FIFO）。
class HistoryOutboxUpdateEntry {
  const HistoryOutboxUpdateEntry({
    required this.recordId,
    required this.body,
    required this.enqueuedAtMs,
  });

  final String recordId;
  final Map<String, dynamic> body;
  final int enqueuedAtMs;

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'body': body,
        'enqueuedAtMs': enqueuedAtMs,
      };

  static HistoryOutboxUpdateEntry fromJson(Map<String, dynamic> json) {
    final bodyRaw = json['body'];
    return HistoryOutboxUpdateEntry(
      recordId: json['recordId']?.toString() ?? '',
      body: bodyRaw is Map ? Map<String, dynamic>.from(bodyRaw) : const {},
      enqueuedAtMs: json['enqueuedAtMs'] is num ? (json['enqueuedAtMs'] as num).toInt() : 0,
    );
  }
}

/// ADD outbox 队列项（FIFO）。用于持久化 button-path 产生的未送达的新增事件。
class HistoryOutboxAddEntry {
  const HistoryOutboxAddEntry({
    required this.pendingId,
    required this.body,
    required this.enqueuedAtMs,
  });

  final String pendingId;
  final Map<String, dynamic> body;
  final int enqueuedAtMs;

  Map<String, dynamic> toJson() => {
        'pendingId': pendingId,
        'body': body,
        'enqueuedAtMs': enqueuedAtMs,
      };

  static HistoryOutboxAddEntry fromJson(Map<String, dynamic> json) {
    final bodyRaw = json['body'];
    return HistoryOutboxAddEntry(
      pendingId: json['pendingId']?.toString() ?? '',
      body: bodyRaw is Map ? Map<String, dynamic>.from(bodyRaw) : const {},
      enqueuedAtMs: json['enqueuedAtMs'] is num ? (json['enqueuedAtMs'] as num).toInt() : 0,
    );
  }
}

/// 历史 UPDATE outbox 本地持久化（按 deviceNo 分文件；Web 不写盘）。
class HistoryOutboxStore {
  static Future<Directory?> _rootDir() async {
    if (!homeHistorySupportsLocalFiles) return null;
    final doc = await getApplicationDocumentsDirectory();
    final root = Directory('${doc.path}/home_history_outbox');
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  static Future<File?> _outboxFile(String deviceNo) async {
    if (deviceNo.isEmpty) return null;
    final root = await _rootDir();
    if (root == null) return null;
    return File('${root.path}/outbox_${safeHomeHistoryFileStem(deviceNo)}$_outboxFileSuffix');
  }

  static Future<File?> _addsFile(String deviceNo) async {
    if (deviceNo.isEmpty) return null;
    final root = await _rootDir();
    if (root == null) return null;
    return File('${root.path}/outbox_${safeHomeHistoryFileStem(deviceNo)}$_addsFileSuffix');
  }

  static Future<List<HistoryOutboxUpdateEntry>> load(String deviceNo) async {
    if (!homeHistorySupportsLocalFiles || deviceNo.isEmpty) return const [];
    final file = await _outboxFile(deviceNo);
    if (file == null || !await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      final out = <HistoryOutboxUpdateEntry>[];
      for (final e in decoded) {
        if (e is Map) {
          final entry = HistoryOutboxUpdateEntry.fromJson(Map<String, dynamic>.from(e));
          if (entry.recordId.isNotEmpty && entry.body.isNotEmpty) {
            out.add(entry);
          }
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _save(String deviceNo, List<HistoryOutboxUpdateEntry> entries) async {
    final file = await _outboxFile(deviceNo);
    if (file == null) return;
    try {
      await file.writeAsString(jsonEncode(entries.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<List<HistoryOutboxAddEntry>> _loadAdds(String deviceNo) async {
    if (!homeHistorySupportsLocalFiles || deviceNo.isEmpty) return const [];
    final file = await _addsFile(deviceNo);
    if (file == null || !await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      final out = <HistoryOutboxAddEntry>[];
      for (final e in decoded) {
        if (e is Map) {
          final entry = HistoryOutboxAddEntry.fromJson(Map<String, dynamic>.from(e));
          if (entry.pendingId.isNotEmpty && entry.body.isNotEmpty) {
            out.add(entry);
          }
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _saveAdds(String deviceNo, List<HistoryOutboxAddEntry> entries) async {
    final file = await _addsFile(deviceNo);
    if (file == null) return;
    try {
      await file.writeAsString(jsonEncode(entries.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> enqueueUpdate({
    required String deviceNo,
    required String recordId,
    required Map<String, dynamic> body,
  }) async {
    if (deviceNo.isEmpty || recordId.isEmpty) return;
    final list = await load(deviceNo);
    list.add(
      HistoryOutboxUpdateEntry(
        recordId: recordId,
        body: Map<String, dynamic>.from(body),
        enqueuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _save(deviceNo, list);
  }

  /// 将一个 pending add 入队到持久化 ADD outbox（FIFO）。
  static Future<void> enqueueAdd({
    required String deviceNo,
    required String pendingId,
    required Map<String, dynamic> body,
  }) async {
    if (deviceNo.isEmpty || pendingId.isEmpty) return;
    final list = await _loadAdds(deviceNo);
    list.add(
      HistoryOutboxAddEntry(
        pendingId: pendingId,
        body: Map<String, dynamic>.from(body),
        enqueuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _saveAdds(deviceNo, list);
  }

  static Future<HistoryOutboxUpdateEntry?> peek(String deviceNo) async {
    final list = await load(deviceNo);
    if (list.isEmpty) return null;
    return list.first;
  }

  /// 读取 ADD outbox 队首条目（不移除）。
  static Future<HistoryOutboxAddEntry?> peekAdd(String deviceNo) async {
    final list = await _loadAdds(deviceNo);
    if (list.isEmpty) return null;
    return list.first;
  }

  static Future<void> removeHead(String deviceNo) async {
    final list = await load(deviceNo);
    if (list.isEmpty) return;
    list.removeAt(0);
    if (list.isEmpty) {
      await clearForDevice(deviceNo);
      return;
    }
    await _save(deviceNo, list);
  }

  /// 从 ADD outbox 弹出队首条目。
  static Future<void> removeHeadAdd(String deviceNo) async {
    final list = await _loadAdds(deviceNo);
    if (list.isEmpty) return;
    list.removeAt(0);
    if (list.isEmpty) {
      try {
        final file = await _addsFile(deviceNo);
        if (file != null && await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      return;
    }
    await _saveAdds(deviceNo, list);
  }

  static Future<void> clearForDevice(String deviceNo) async {
    if (!homeHistorySupportsLocalFiles || deviceNo.isEmpty) return;
    try {
      final file = await _outboxFile(deviceNo);
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// 清空指定设备号的 ADD outbox 文件。
  static Future<void> clearAddsForDevice(String deviceNo) async {
    if (!homeHistorySupportsLocalFiles || deviceNo.isEmpty) return;
    try {
      final file = await _addsFile(deviceNo);
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    if (!homeHistorySupportsLocalFiles) return;
    try {
      final root = await _rootDir();
      if (root != null && await root.exists()) {
        await root.delete(recursive: true);
      }
    } catch (_) {}
  }
}
