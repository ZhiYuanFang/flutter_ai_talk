import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const kHomeWidgetPayloadKey = 'widgetPayload';
const kWidgetHistoryDepthReadyKey = 'widgetHistoryDepthReady';

class HomeWidgetHeaderPayload {
  const HomeWidgetHeaderPayload({
    required this.nickname,
    required this.birthDate,
    required this.displayLine,
  });

  final String nickname;
  final String birthDate;
  final String displayLine;

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'birthDate': birthDate,
        'displayLine': displayLine,
      };

  static HomeWidgetHeaderPayload? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return HomeWidgetHeaderPayload(
      nickname: map['nickname'] as String? ?? '',
      birthDate: map['birthDate'] as String? ?? '',
      displayLine: map['displayLine'] as String? ?? '',
    );
  }
}

class HomeWidgetVisualPayload {
  const HomeWidgetVisualPayload({
    this.shellGradientStart = '#B8DFF2',
    this.shellGradientEnd = '#E8F4FC',
    this.glassFillTop = '#F7FCFF',
    this.glassFillBottom = '#EEF6FB',
    this.borderColor = '#FFFFFFD1',
    this.textPrimary = '#3D454C',
    this.textSecondary = '#7A8690',
    this.cornerRadius = 18,
    this.rowRadius = 12,
    this.shellOpacity = 0.7,
    this.isDarkShell = false,
  });

  final String shellGradientStart;
  final String shellGradientEnd;
  final String glassFillTop;
  final String glassFillBottom;
  final String borderColor;
  final String textPrimary;
  final String textSecondary;
  final int cornerRadius;
  final int rowRadius;
  final double shellOpacity;
  final bool isDarkShell;

  Map<String, dynamic> toJson() => {
        'shellGradientStart': shellGradientStart,
        'shellGradientEnd': shellGradientEnd,
        'glassFillTop': glassFillTop,
        'glassFillBottom': glassFillBottom,
        'borderColor': borderColor,
        'textPrimary': textPrimary,
        'textSecondary': textSecondary,
        'cornerRadius': cornerRadius,
        'rowRadius': rowRadius,
        'shellOpacity': shellOpacity,
        'isDarkShell': isDarkShell,
      };

  static HomeWidgetVisualPayload fromJson(Object? raw) {
    if (raw is! Map) return const HomeWidgetVisualPayload();
    final map = Map<String, dynamic>.from(raw);
    return HomeWidgetVisualPayload(
      shellGradientStart: map['shellGradientStart'] as String? ?? '#B8DFF2',
      shellGradientEnd: map['shellGradientEnd'] as String? ?? '#E8F4FC',
      glassFillTop: map['glassFillTop'] as String? ?? '#F7FCFF',
      glassFillBottom: map['glassFillBottom'] as String? ?? '#EEF6FB',
      borderColor: map['borderColor'] as String? ?? '#FFFFFFD1',
      textPrimary: map['textPrimary'] as String? ?? '#3D454C',
      textSecondary: map['textSecondary'] as String? ?? '#7A8690',
      cornerRadius: (map['cornerRadius'] as num?)?.toInt() ?? 18,
      rowRadius: (map['rowRadius'] as num?)?.toInt() ?? 12,
      shellOpacity: (map['shellOpacity'] as num?)?.toDouble() ?? 0.7,
      isDarkShell: map['isDarkShell'] as bool? ?? false,
    );
  }
}

class HomeWidgetRowPayload {
  const HomeWidgetRowPayload({
    required this.kind,
    required this.eventId,
    required this.name,
    this.startAt,
    this.nextAt,
    this.lastAt,
    this.status,
    this.color = '#5BA3E8',
    this.logoFile,
  });

  final String kind;
  final String eventId;
  final String name;
  final String? startAt;
  final String? nextAt;
  final String? lastAt;
  final String? status;
  final String color;
  final String? logoFile;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'eventId': eventId,
        'name': name,
        if (startAt != null) 'startAt': startAt,
        if (nextAt != null) 'nextAt': nextAt,
        if (lastAt != null) 'lastAt': lastAt,
        if (status != null) 'status': status,
        'color': color,
        if (logoFile != null) 'logoFile': logoFile,
      };

  static HomeWidgetRowPayload? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return HomeWidgetRowPayload(
      kind: map['kind'] as String? ?? '',
      eventId: map['eventId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      startAt: map['startAt'] as String?,
      nextAt: map['nextAt'] as String?,
      lastAt: map['lastAt'] as String?,
      status: map['status'] as String?,
      color: map['color'] as String? ?? '#5BA3E8',
      logoFile: map['logoFile'] as String?,
    );
  }
}

class HomeWidgetTipPayload {
  const HomeWidgetTipPayload({
    required this.text,
    required this.fetchedAt,
  });

  final String text;
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() => {
        'text': text,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  static HomeWidgetTipPayload? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final text = map['text'] as String? ?? '';
    if (text.isEmpty) return null;
    return HomeWidgetTipPayload(
      text: text,
      fetchedAt: DateTime.tryParse(map['fetchedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class HomeWidgetSparklinePayload {
  const HomeWidgetSparklinePayload({
    required this.eventId,
    required this.color,
    required this.unit,
    required this.points,
  });

  final String eventId;
  final String color;
  final String unit;
  final List<double> points;

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'color': color,
        'unit': unit,
        'points': points,
      };

  static HomeWidgetSparklinePayload? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final ptsRaw = map['points'];
    final pts = <double>[];
    if (ptsRaw is List) {
      for (final e in ptsRaw) {
        if (e is num) pts.add(e.toDouble());
      }
    }
    if (pts.isEmpty) return null;
    return HomeWidgetSparklinePayload(
      eventId: map['eventId'] as String? ?? '',
      color: map['color'] as String? ?? '#5BA3E8',
      unit: map['unit'] as String? ?? 'count',
      points: pts,
    );
  }
}

class HomeWidgetPayload {
  const HomeWidgetPayload({
    required this.state,
    this.message,
    this.widgetKind = 'medium',
    this.header,
    this.visual = const HomeWidgetVisualPayload(),
    this.hero,
    this.recentLast = const [],
    this.tip,
    this.rows = const [],
    this.sparkline,
    required this.updatedAt,
  });

  final String state;
  final String? message;
  final String widgetKind;
  final HomeWidgetHeaderPayload? header;
  final HomeWidgetVisualPayload visual;
  final HomeWidgetRowPayload? hero;
  final List<HomeWidgetRowPayload> recentLast;
  final HomeWidgetTipPayload? tip;
  final List<HomeWidgetRowPayload> rows;
  final HomeWidgetSparklinePayload? sparkline;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'state': state,
        if (message != null) 'message': message,
        'widgetKind': widgetKind,
        if (header != null) 'header': header!.toJson(),
        'visual': visual.toJson(),
        if (hero != null) 'hero': hero!.toJson(),
        'recentLast': recentLast.map((e) => e.toJson()).toList(),
        if (tip != null) 'tip': tip!.toJson(),
        'rows': rows.map((e) => e.toJson()).toList(),
        if (sparkline != null) 'sparkline': sparkline!.toJson(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  static HomeWidgetPayload? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final rowsRaw = map['rows'];
      final rows = <HomeWidgetRowPayload>[];
      if (rowsRaw is List) {
        for (final e in rowsRaw) {
          final row = HomeWidgetRowPayload.fromJson(e);
          if (row != null) rows.add(row);
        }
      }
      final recentRaw = map['recentLast'];
      final recentLast = <HomeWidgetRowPayload>[];
      if (recentRaw is List) {
        for (final e in recentRaw) {
          final row = HomeWidgetRowPayload.fromJson(e);
          if (row != null) recentLast.add(row);
        }
      }
      return HomeWidgetPayload(
        state: map['state'] as String? ?? 'empty',
        message: map['message'] as String?,
        widgetKind: map['widgetKind'] as String? ?? 'medium',
        header: HomeWidgetHeaderPayload.fromJson(map['header']),
        visual: HomeWidgetVisualPayload.fromJson(map['visual']),
        hero: HomeWidgetRowPayload.fromJson(map['hero']),
        recentLast: recentLast,
        tip: HomeWidgetTipPayload.fromJson(map['tip']),
        rows: rows,
        sparkline: HomeWidgetSparklinePayload.fromJson(map['sparkline']),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

Future<bool> readWidgetHistoryDepthReady() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kWidgetHistoryDepthReadyKey) ?? false;
}

Future<void> setWidgetHistoryDepthReady(bool ready) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kWidgetHistoryDepthReadyKey, ready);
}

Future<void> clearWidgetHistoryDepthReady() async {
  await setWidgetHistoryDepthReady(false);
}
