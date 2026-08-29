// UCG 原力积分流水模型（对齐 go `UcgForceLedgerRes`）。

/// GET `/ucg/app/api/force/ledger` 单项。
class UcgForceLedgerItem {
  const UcgForceLedgerItem({
    required this.id,
    required this.reason,
    required this.delta,
    required this.createdAt,
    this.ref = '',
  });

  final int id;
  final String reason;
  final int delta;
  final int createdAt;
  final String ref;

  factory UcgForceLedgerItem.fromJson(Map<String, dynamic> json) {
    return UcgForceLedgerItem(
      id: _asInt(json['id']),
      reason: (json['reason'] ?? '').toString(),
      delta: _asInt(json['delta']),
      createdAt: _asInt(json['createdAt']),
      ref: (json['ref'] ?? '').toString(),
    );
  }

  /// 流水原因展示文案。
  String get reasonLabel {
    switch (reason.trim()) {
      case 'debate_self_vote':
        return '辩论自投';
      case 'invite_acquisition':
        return '邀请获客';
      default:
        final r = reason.trim();
        return r.isEmpty ? '积分变动' : r;
    }
  }
}

/// GET `/ucg/app/api/force/ledger` 响应。
class UcgForceLedgerPage {
  const UcgForceLedgerPage({
    required this.forceValue,
    required this.list,
  });

  final int forceValue;
  final List<UcgForceLedgerItem> list;

  factory UcgForceLedgerPage.fromJson(Map<String, dynamic> json) {
    final raw = json['list'];
    final items = <UcgForceLedgerItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          items.add(UcgForceLedgerItem.fromJson(e));
        } else if (e is Map) {
          items.add(UcgForceLedgerItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return UcgForceLedgerPage(
      forceValue: _asInt(json['forceValue']),
      list: items,
    );
  }
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}
