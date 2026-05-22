import 'package:flutter/material.dart';

/// 事件目录项（与 `GET /device/history/api/event/options` 列表项对应）。
@immutable
class EventDefinition {
  const EventDefinition({
    required this.id,
    required this.name,
    this.logoUrl,
    this.colorRaw,
    this.localLogoPath,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? colorRaw;
  final String? localLogoPath;

  Color? get parsedColor => tryParseEventColor(colorRaw);

  EventDefinition copyWith({
    String? name,
    String? logoUrl,
    String? colorRaw,
    String? localLogoPath,
    bool clearLocalLogoPath = false,
  }) {
    return EventDefinition(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      colorRaw: colorRaw ?? this.colorRaw,
      localLogoPath: clearLocalLogoPath ? null : (localLogoPath ?? this.localLogoPath),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (colorRaw != null) 'colorRaw': colorRaw,
        if (localLogoPath != null) 'localLogoPath': localLogoPath,
      };

  static EventDefinition fromJson(Map<String, dynamic> j) {
    return EventDefinition(
      id: j['id']?.toString() ?? '',
      name: j['name'] as String? ?? '事件',
      logoUrl: j['logoUrl'] as String?,
      colorRaw: j['colorRaw'] as String?,
      localLogoPath: j['localLogoPath'] as String?,
    );
  }

  static EventDefinition fromOptionsMap(Map<String, dynamic> j) {
    final idRaw = j['id'];
    final id = idRaw == null ? '' : idRaw.toString();
    final name = j['name'] as String? ?? '事件';
    final logo = _trimOrNull(j['logo'] as String?);
    final color = _trimOrNull(j['color'] as String?);
    return EventDefinition(
      id: id,
      name: name,
      logoUrl: logo,
      colorRaw: color,
    );
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
