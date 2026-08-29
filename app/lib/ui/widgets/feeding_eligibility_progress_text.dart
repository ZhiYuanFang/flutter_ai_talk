import 'package:flutter/material.dart';

import '../../data/feature_unlock_models.dart';

/// 喂养资格进度文案场景。
enum FeedingEligibilityProgressKind {
  /// 解锁广场 / 个人邀请码（ucg_entry）。
  ucgEntry,

  /// 激活值得留意（care_alert_entry）。
  careAlert,
}

/// 客户端自拼剩余天数文案，并放大 [UcgEligibility.remainingDays] 数字。
///
/// 不展示服务端 `message`（避免盖住可强调的数字）。
class FeedingEligibilityProgressText extends StatelessWidget {
  const FeedingEligibilityProgressText({
    super.key,
    required this.eligibility,
    required this.kind,
    this.textAlign = TextAlign.center,
    this.baseStyle,
    this.numberScale = 1.75,
  });

  final UcgEligibility eligibility;
  final FeedingEligibilityProgressKind kind;
  final TextAlign textAlign;
  final TextStyle? baseStyle;

  /// 相对正文的数字字号倍率。
  final double numberScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = baseStyle ??
        theme.textTheme.bodyMedium?.copyWith(height: 1.35) ??
        const TextStyle(fontSize: 14, height: 1.35);
    final baseSize = base.fontSize ?? 14;
    // 放大剩余天数：更大字号 + 加粗 + 主题色，一眼可读。
    final numberStyle = base.copyWith(
      fontSize: baseSize * numberScale,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.primary,
      height: 1.05,
    );
    final y = eligibility.remainingDays < 0 ? 0 : eligibility.remainingDays;

    final List<InlineSpan> children;
    switch (kind) {
      case FeedingEligibilityProgressKind.ucgEntry:
        children = [
          const TextSpan(text: '还需要连续喂养 '),
          TextSpan(text: '$y', style: numberStyle),
          const TextSpan(text: ' 天宝宝作息，\n解锁广场与真实带娃家庭分享经验'),
        ];
      case FeedingEligibilityProgressKind.careAlert:
        children = [
          const TextSpan(text: '还需连续记录 '),
          TextSpan(text: '$y', style: numberStyle),
          const TextSpan(text: ' 天宝宝作息，激活AI贴心提醒'),
        ];
    }

    return Text.rich(
      TextSpan(style: base, children: children),
      textAlign: textAlign,
    );
  }
}
