import 'package:flutter/foundation.dart';
import 'package:pangbao_app/home_widget/home_widget_payload.dart';

enum BabySex { male, female, unknown }

@immutable
class BabyProfile {
  const BabyProfile({
    required this.id,
    required this.nickname,
    required this.sex,
    required this.birthDate,
  });

  final String id;
  final String nickname;
  final BabySex sex;
  final DateTime birthDate;

  BabyProfile copyWith({
    String? id,
    String? nickname,
    BabySex? sex,
    DateTime? birthDate,
  }) {
    return BabyProfile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'sex': sex.name,
        'birthDate': HomeWidgetRowPayload.isoUtc(birthDate),
      };

  static BabyProfile fromJson(Map<String, dynamic> j) {
    final sexName = j['sex'] as String? ?? 'unknown';
    final sex = switch (sexName) {
      'male' => BabySex.male,
      'female' => BabySex.female,
      _ => BabySex.unknown,
    };
    return BabyProfile(
      id: j['id']! as String,
      nickname: j['nickname']! as String,
      sex: sex,
      birthDate: DateTime.parse(j['birthDate']! as String),
    );
  }
}

/// 列表主文案：`{事件名}:{动作}`（缺省由 [formatHistoryLine] 占位）。
@immutable
class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.createdAt,
    required this.eventName,
    required this.action,
    required this.rawPayload,
  });

  final String id;
  final DateTime createdAt;
  final String eventName;
  final String action;
  final Map<String, Object?> rawPayload;

  String get displayLine => formatHistoryLine(eventName, action);

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': HomeWidgetRowPayload.isoUtc(createdAt),
        'eventName': eventName,
        'action': action,
        'rawPayload': rawPayload,
      };

  static HistoryRecord fromJson(Map<String, dynamic> j) {
    final payloadRaw = j['rawPayload'];
    final payload = payloadRaw is Map
        ? payloadRaw.map((key, value) => MapEntry(key.toString(), value as Object?))
        : <String, Object?>{};
    return HistoryRecord(
      id: j['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      eventName: j['eventName'] as String? ?? '',
      action: j['action'] as String? ?? '',
      rawPayload: Map<String, Object?>.from(payload),
    );
  }
}

String formatHistoryLine(String eventName, String action) {
  final e = eventName.trim().isEmpty ? '未知事件' : eventName.trim();
  final a = action.trim().isEmpty ? '未命名动作' : action.trim();
  return '$e:$a';
}

@immutable
class SseHistoryPayload {
  const SseHistoryPayload({this.record, this.removedRecordId})
      : assert(
          (record != null && removedRecordId == null) ||
              (record == null && removedRecordId != null),
          'Exactly one of record or removedRecordId',
        );

  final HistoryRecord? record;
  final String? removedRecordId;
}

@immutable
class TrendCatalogItem {
  const TrendCatalogItem({required this.eventKey, required this.title});

  final String eventKey;
  final String title;
}

@immutable
class TrendPoint {
  const TrendPoint({required this.t, required this.value});

  final DateTime t;
  final double value;
}

@immutable
class TrendSeries {
  const TrendSeries({required this.eventKey, required this.points});

  final String eventKey;
  final List<TrendPoint> points;
}

/// 一次 piece 拉取：原始发生点 + 按日聚合桶（供近 N 日图与某日过滤）。
@immutable
class TrendPieceBundle {
  const TrendPieceBundle({
    required this.eventKey,
    required this.raw,
    required this.daily,
  });

  final String eventKey;
  /// 单条 piece 映射的发生点（含具体时刻）。
  final List<TrendPoint> raw;
  /// 区间内按自然日分桶（缺失日补 0）。
  final List<TrendPoint> daily;

  static TrendPieceBundle empty(String eventKey) => TrendPieceBundle(
        eventKey: eventKey,
        raw: const [],
        daily: const [],
      );
}

@immutable
class VersionInfo {
  const VersionInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.androidApkUrl,
    required this.forceUpdate,
  });

  final String latestVersion;
  final String releaseNotes;
  final String androidApkUrl;
  final bool forceUpdate;
}
