import 'package:flutter/foundation.dart';

/// 小贴士展示状态枚举
///
/// 业务含义：首页小贴士面板根据该状态决定渲染样式。
/// - [idle]：初始态或关闭后，隐藏
/// - [streaming]：正在接收 SSE，有内容时展示纯文本
/// - [done]：接收完成，展示 Markdown
/// - [closing]：保留枚举兼容；当前关闭直接回 idle
enum TipDisplayState {
  idle, // 无内容，不展示
  streaming, // 正在接收 SSE
  done, // 接收完成
  closing, // 已弃用路径（关闭直接 idle）
}

/// 小贴士用户反馈枚举
enum TipFeedback {
  none, // 未反馈
  up, // 认同
  down, // 不认同
}

/// 小贴士内容数据模型
///
/// 由 TipNotifier 持有，HomeTipPanel 监听渲染。
@immutable
class TipContent {
  /// 当前展示状态
  final TipDisplayState displayState;

  /// 思考过程累积文本
  final String thinking;

  /// 回答内容累积文本（优先展示）
  final String answer;

  /// Go SSE done 的 answerId（feedback 用）
  final String? answerId;

  /// 用户反馈状态
  final TipFeedback feedback;

  /// 反馈提交中
  final bool feedbackSubmitting;

  /// 是否已注入陪伴会话
  final bool consumedForCompanion;

  /// 呈现代数：startStreaming 时 +1，驱动弹性入场再播
  final int presentationGeneration;

  const TipContent({
    this.displayState = TipDisplayState.idle,
    this.thinking = '',
    this.answer = '',
    this.answerId,
    this.feedback = TipFeedback.none,
    this.feedbackSubmitting = false,
    this.consumedForCompanion = false,
    this.presentationGeneration = 0,
  });

  /// 有思考或答案文本且非 idle 才展示（空 streaming 不占位）
  bool get shouldShow {
    if (displayState == TipDisplayState.idle) return false;
    return thinking.trim().isNotEmpty || answer.trim().isNotEmpty;
  }

  /// 可注入陪伴：done、未消费、有可展示文本
  bool get canInjectToCompanion {
    if (displayState != TipDisplayState.done) return false;
    if (consumedForCompanion) return false;
    final text = answer.isNotEmpty ? answer : thinking;
    return text.trim().isNotEmpty;
  }

  /// 注入用展示文本（优先 answer）
  String get injectText {
    final a = answer.trim();
    if (a.isNotEmpty) return a;
    return thinking.trim();
  }

  TipContent copyWith({
    TipDisplayState? displayState,
    String? thinking,
    String? answer,
    String? answerId,
    TipFeedback? feedback,
    bool? feedbackSubmitting,
    bool? consumedForCompanion,
    int? presentationGeneration,
  }) {
    return TipContent(
      displayState: displayState ?? this.displayState,
      thinking: thinking ?? this.thinking,
      answer: answer ?? this.answer,
      answerId: answerId ?? this.answerId,
      feedback: feedback ?? this.feedback,
      feedbackSubmitting: feedbackSubmitting ?? this.feedbackSubmitting,
      consumedForCompanion: consumedForCompanion ?? this.consumedForCompanion,
      presentationGeneration:
          presentationGeneration ?? this.presentationGeneration,
    );
  }
}
