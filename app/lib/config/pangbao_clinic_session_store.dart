import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kKeyPrefix = 'pangbao_clinic_session_v1_';

/// 本地会话条目类型：普通问答 / tip 注入 / 截断横线。
enum PangbaoClinicEntryKind { qa, tip, divider }

/// 胖宝陪伴已完成轮次（本地缓存，按 deviceNo 隔离）。
class PangbaoClinicTurn {
  const PangbaoClinicTurn({
    required this.question,
    required this.answer,
    this.thinking,
    this.kind = PangbaoClinicEntryKind.qa,
    this.at,
  });

  final String question;
  final String answer;
  final String? thinking;
  final PangbaoClinicEntryKind kind;

  /// 本地消息时间（提问/ tip 注入时刻）；旧数据可空。
  final DateTime? at;

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
        if (thinking != null && thinking!.isNotEmpty) 'thinking': thinking,
        if (kind != PangbaoClinicEntryKind.qa) 'kind': kind.name,
        if (at != null) 'at': at!.toIso8601String(),
      };

  factory PangbaoClinicTurn.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind'] as String?;
    final kind = switch (kindRaw) {
      'tip' => PangbaoClinicEntryKind.tip,
      'divider' => PangbaoClinicEntryKind.divider,
      _ => PangbaoClinicEntryKind.qa,
    };
    return PangbaoClinicTurn(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      thinking: json['thinking'] as String?,
      kind: kind,
      at: _parseAt(json['at']),
    );
  }

  /// 纯线截断分隔项。
  factory PangbaoClinicTurn.divider() => const PangbaoClinicTurn(
        question: '',
        answer: '',
        kind: PangbaoClinicEntryKind.divider,
      );

  /// tip 注入助手内容（无用户问句）。
  factory PangbaoClinicTurn.tip({
    required String answer,
    String? thinking,
    DateTime? at,
  }) =>
      PangbaoClinicTurn(
        question: '',
        answer: answer,
        thinking: thinking,
        kind: PangbaoClinicEntryKind.tip,
        at: at,
      );
}

DateTime? _parseAt(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// 胖宝陪伴失败轮次（inline error，无成功 answer）。
class PangbaoClinicFailedTurn {
  const PangbaoClinicFailedTurn({
    required this.question,
    required this.errorMessage,
    this.thinking,
  });

  final String question;
  final String errorMessage;
  final String? thinking;

  Map<String, dynamic> toJson() => {
        'question': question,
        'errorMessage': errorMessage,
        if (thinking != null && thinking!.isNotEmpty) 'thinking': thinking,
      };

  factory PangbaoClinicFailedTurn.fromJson(Map<String, dynamic> json) {
    return PangbaoClinicFailedTurn(
      question: json['question'] as String? ?? '',
      errorMessage: json['errorMessage'] as String? ?? '',
      thinking: json['thinking'] as String?,
    );
  }
}

class PangbaoClinicSessionSnapshot {
  const PangbaoClinicSessionSnapshot({
    this.completed = const [],
    this.failed = const [],
  });

  final List<PangbaoClinicTurn> completed;
  final List<PangbaoClinicFailedTurn> failed;

  bool get isEmpty => completed.isEmpty && failed.isEmpty;
}

class PangbaoClinicSessionStore {
  PangbaoClinicSessionStore._();

  static String _key(String deviceNo) => '$_kKeyPrefix$deviceNo';

  static Future<PangbaoClinicSessionSnapshot> loadSnapshot(String deviceNo) async {
    if (deviceNo.isEmpty) return const PangbaoClinicSessionSnapshot();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(deviceNo));
    if (raw == null || raw.isEmpty) return const PangbaoClinicSessionSnapshot();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return PangbaoClinicSessionSnapshot(
          completed: [
            for (final e in decoded)
              if (e is Map<String, dynamic>) PangbaoClinicTurn.fromJson(e),
          ],
        );
      }
      if (decoded is Map<String, dynamic>) {
        final completedRaw = decoded['completed'];
        final failedRaw = decoded['failed'];
        return PangbaoClinicSessionSnapshot(
          completed: completedRaw is List
              ? [
                  for (final e in completedRaw)
                    if (e is Map<String, dynamic>) PangbaoClinicTurn.fromJson(e),
                ]
              : const [],
          failed: failedRaw is List
              ? [
                  for (final e in failedRaw)
                    if (e is Map<String, dynamic>) PangbaoClinicFailedTurn.fromJson(e),
                ]
              : const [],
        );
      }
    } catch (_) {}
    return const PangbaoClinicSessionSnapshot();
  }

  /// 兼容旧 API：仅 completed 列表。
  static Future<List<PangbaoClinicTurn>> load(String deviceNo) async {
    final snap = await loadSnapshot(deviceNo);
    return snap.completed;
  }

  static Future<void> saveSnapshot(String deviceNo, PangbaoClinicSessionSnapshot snapshot) async {
    if (deviceNo.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (snapshot.isEmpty) {
      await prefs.remove(_key(deviceNo));
      return;
    }
    await prefs.setString(
      _key(deviceNo),
      jsonEncode({
        'completed': snapshot.completed.map((t) => t.toJson()).toList(),
        'failed': snapshot.failed.map((t) => t.toJson()).toList(),
      }),
    );
  }

  /// 清空指定 device 的本地陪伴会话。
  static Future<void> clear(String deviceNo) async {
    if (deviceNo.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(deviceNo));
  }

  /// 兼容旧 API：仅写 completed。
  static Future<void> save(String deviceNo, List<PangbaoClinicTurn> turns) async {
    final existing = await loadSnapshot(deviceNo);
    await saveSnapshot(
      deviceNo,
      PangbaoClinicSessionSnapshot(completed: turns, failed: existing.failed),
    );
  }
}
