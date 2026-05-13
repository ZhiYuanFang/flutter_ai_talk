import 'package:flutter/foundation.dart';

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
        'birthDate': birthDate.toIso8601String(),
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
