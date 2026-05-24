import 'package:flutter/material.dart';

import '../api/gateway_json.dart';

/// 事件目录 `eventType` 合法值。
enum EventCatalogEventType { number, time, one }

/// 解析 options 中的 `eventType`；非法或缺失返回 `null`。
EventCatalogEventType? parseEventCatalogEventType(String? raw) {
  if (raw == null) return null;
  switch (raw.trim().toLowerCase()) {
    case 'number':
      return EventCatalogEventType.number;
    case 'time':
      return EventCatalogEventType.time;
    case 'one':
      return EventCatalogEventType.one;
    default:
      return null;
  }
}

/// 事件目录项（与 `GET /device/history/api/event/options` 列表项对应）。
@immutable
class EventDefinition {
  const EventDefinition({
    required this.id,
    required this.name,
    this.logoUrl,
    this.colorRaw,
    this.localLogoPath,
    this.eventType,
    this.extraNames,
    this.parentId,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? colorRaw;
  final String? localLogoPath;
  /// options 原始 `eventType` 字符串（`number` / `time` / `one`）。
  final String? eventType;
  final String? extraNames;
  /// 父类 ID；`null` 表示一级目录。
  final String? parentId;

  Color? get parsedColor => tryParseEventColor(colorRaw);

  EventCatalogEventType? get parsedEventType => parseEventCatalogEventType(eventType);

  bool get hasValidEventType => parsedEventType != null;

  EventDefinition copyWith({
    String? name,
    String? logoUrl,
    String? colorRaw,
    String? localLogoPath,
    String? eventType,
    String? extraNames,
    String? parentId,
    bool clearLocalLogoPath = false,
    bool clearParentId = false,
  }) {
    return EventDefinition(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      colorRaw: colorRaw ?? this.colorRaw,
      localLogoPath: clearLocalLogoPath ? null : (localLogoPath ?? this.localLogoPath),
      eventType: eventType ?? this.eventType,
      extraNames: extraNames ?? this.extraNames,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (colorRaw != null) 'colorRaw': colorRaw,
        if (localLogoPath != null) 'localLogoPath': localLogoPath,
        if (eventType != null) 'eventType': eventType,
        if (extraNames != null) 'extraNames': extraNames,
        if (parentId != null) 'parentId': parentId,
      };

  static EventDefinition fromJson(Map<String, dynamic> j) {
    return EventDefinition(
      id: _normalizeCatalogId(j['id']),
      name: j['name'] as String? ?? '事件',
      logoUrl: j['logoUrl'] as String?,
      colorRaw: j['colorRaw'] as String?,
      localLogoPath: j['localLogoPath'] as String?,
      eventType: _trimOrNull(readGatewayStr(j, 'eventType', 'event_type')),
      extraNames: _trimOrNull(readGatewayStr(j, 'extraNames', 'extra_names')),
      parentId: _normalizeParentId(_readOptionsField(j, 'parentId', 'parent_id')),
    );
  }

  static Object? _readOptionsField(Map<String, dynamic> j, String camel, String snake) {
    if (j.containsKey(camel)) return j[camel];
    if (j.containsKey(snake)) return j[snake];
    return null;
  }

  static String? _readLogo(Map<String, dynamic> j) {
    return _trimOrNull(readGatewayStr(j, 'logo', 'logo_url')) ??
        _trimOrNull(j['logoUrl'] as String?);
  }

  static EventDefinition fromOptionsMap(Map<String, dynamic> j) {
    final id = _normalizeCatalogId(j['id']);
    final name = j['name'] as String? ?? '事件';
    final logo = _readLogo(j);
    final color = _trimOrNull(j['color'] as String?);
    final type = _trimOrNull(readGatewayStr(j, 'eventType', 'event_type'));
    final extras = _trimOrNull(readGatewayStr(j, 'extraNames', 'extra_names'));
    return EventDefinition(
      id: id,
      name: name,
      logoUrl: logo,
      colorRaw: color,
      eventType: type,
      extraNames: extras,
      parentId: _normalizeParentId(_readOptionsField(j, 'parentId', 'parent_id')),
    );
  }

  static String? _normalizeParentId(Object? raw) {
    if (raw == null) return null;
    if (raw is num && raw == 0) return null;
    final s = raw.toString().trim();
    if (s.isEmpty || s == '0') return null;
    final n = int.tryParse(s);
    if (n != null && n == 0) return null;
    if (n != null) return n.toString();
    return s;
  }

  static String _normalizeCatalogId(Object? raw) {
    if (raw == null) return '';
    final s = raw.toString().trim();
    if (s.isEmpty) return '';
    final n = int.tryParse(s);
    if (n != null) return n.toString();
    return s;
  }

  static String? _trimOrNull(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }
}

/// 解析品牌色；失败返回 null。
Color? tryParseEventColor(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('#')) s = s.substring(1);
  if (s.startsWith('0x') || s.startsWith('0X')) {
    final v = int.tryParse(s.substring(2), radix: 16);
    if (v == null) return null;
    return Color(v);
  }
  if (s.length == 3) {
    final r = int.tryParse('${s[0]}${s[0]}', radix: 16);
    final g = int.tryParse('${s[1]}${s[1]}', radix: 16);
    final b = int.tryParse('${s[2]}${s[2]}', radix: 16);
    if (r == null || g == null || b == null) return null;
    return Color.fromARGB(255, r, g, b);
  }
  if (s.length == 6) {
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }
  if (s.length == 8) {
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(v);
  }
  return null;
}

/// 无有效品牌色时使用 [ColorScheme.primary]。
Color resolveEventColor(BuildContext context, EventDefinition? definition) {
  return definition?.parsedColor ?? Theme.of(context).colorScheme.primary;
}
