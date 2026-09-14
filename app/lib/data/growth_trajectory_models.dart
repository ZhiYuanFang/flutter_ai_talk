/// 成长轨迹预测 DTO（对齐 Go `/device/api/growth-trajectory/*` 与 CONTRACT）。
library;

/// GET latest 结果。
class GrowthTrajectoryLatest {
  const GrowthTrajectoryLatest({
    this.resultMarkdown,
    this.updatedAt = 0,
    this.sessionId = '',
    this.usedToday = 0,
    this.dailyLimit = 5,
  });

  final String? resultMarkdown;
  final int updatedAt;
  final String sessionId;
  final int usedToday;
  final int dailyLimit;

  bool get hasResult => (resultMarkdown ?? '').trim().isNotEmpty;

  factory GrowthTrajectoryLatest.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const GrowthTrajectoryLatest();
    }
    final md = json['resultMarkdown'];
    return GrowthTrajectoryLatest(
      resultMarkdown: md == null ? null : md.toString(),
      updatedAt: _asInt(json['updatedAt']),
      sessionId: (json['sessionId'] ?? '').toString(),
      usedToday: _asInt(json['usedToday']),
      dailyLimit: _asInt(json['dailyLimit']).clamp(1, 9999),
    );
  }
}

/// SSE question 载荷。
class GrowthTrajectoryQuestion {
  const GrowthTrajectoryQuestion({
    required this.id,
    required this.prompt,
    required this.format,
    this.choices = const [],
    this.sessionId = '',
  });

  final String id;
  final String prompt;

  /// `choice` | `free_text`
  final String format;
  final List<String> choices;
  final String sessionId;

  bool get isChoice => format == 'choice';

  /// choice 固定取前两个（契约要求恰好 2）。
  List<String> get twoChoices {
    if (choices.length >= 2) return [choices[0], choices[1]];
    if (choices.length == 1) return [choices[0], '其他'];
    return const ['是', '否'];
  }

  factory GrowthTrajectoryQuestion.fromJson(Map<String, dynamic> json) {
    final raw = json['choices'];
    final list = <String>[];
    if (raw is List) {
      for (final e in raw) {
        list.add(e.toString());
      }
    }
    return GrowthTrajectoryQuestion(
      id: (json['id'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      format: (json['format'] ?? 'free_text').toString(),
      choices: list,
      sessionId: (json['sessionId'] ?? '').toString(),
    );
  }
}

/// SSE 流事件。
sealed class GrowthTrajectoryStreamEvent {
  const GrowthTrajectoryStreamEvent();
}

class GrowthTrajectoryThinkingDelta extends GrowthTrajectoryStreamEvent {
  const GrowthTrajectoryThinkingDelta(this.content);
  final String content;
}

class GrowthTrajectoryQuestionEvent extends GrowthTrajectoryStreamEvent {
  const GrowthTrajectoryQuestionEvent(this.question);
  final GrowthTrajectoryQuestion question;
}

class GrowthTrajectoryResultEvent extends GrowthTrajectoryStreamEvent {
  const GrowthTrajectoryResultEvent({
    required this.markdown,
    this.sessionId = '',
    this.usedToday,
    this.dailyLimit,
  });
  final String markdown;
  final String sessionId;
  final int? usedToday;
  final int? dailyLimit;
}

class GrowthTrajectoryErrorEvent extends GrowthTrajectoryStreamEvent {
  const GrowthTrajectoryErrorEvent({
    required this.code,
    required this.message,
  });
  final String code;
  final String message;
}

class GrowthTrajectoryDoneEvent extends GrowthTrajectoryStreamEvent {
  const GrowthTrajectoryDoneEvent();
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}
