import 'package:flutter/material.dart';

import '../../data/feature_unlock_models.dart';

/// 喂养资格进度文案场景。
enum FeedingEligibilityProgressKind {
  /// 解锁广场 / 个人邀请码（ucg_entry）。
  ucgEntry,
}

/// 客户端自拼进度文案：已累计 X/N + 还需 Y 天；放大数字。
///
/// 不展示服务端 `message`（进度数字以字段为准）。
class FeedingEligibilityProgressText extends StatelessWidget {
  const FeedingEligibilityProgressText({
    super.key,
    required this.eligibility,
    required this.kind,
    this.textAlign = TextAlign.center,
    this.baseStyle,
    this.numberScale = 1.75,
    this.accent,
  });

  final UcgEligibility eligibility;
  final FeedingEligibilityProgressKind kind;
  final TextAlign textAlign;
  final TextStyle? baseStyle;

  /// 相对正文的数字字号倍率。
  final double numberScale;

  /// 强调色；空则回退 [ColorScheme.primary]。
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emphasis = accent ?? theme.colorScheme.primary;
    final base = (baseStyle ??
            theme.textTheme.bodyMedium?.copyWith(height: 1.35) ??
            const TextStyle(fontSize: 14, height: 1.35))
        .copyWith(
      color: accent != null
          ? accent!.withValues(alpha: 0.9)
          : (baseStyle?.color ?? theme.colorScheme.onSurface),
    );
    final baseSize = base.fontSize ?? 14;
    // 放大天数数字：更大字号 + 加粗 + 强调色。
    final numberStyle = base.copyWith(
      fontSize: baseSize * numberScale,
      fontWeight: FontWeight.w800,
      color: emphasis,
      height: 1.05,
    );
    final numberSmallStyle = base.copyWith(
      fontSize: baseSize * 1,
      fontWeight: FontWeight.w400,
      color: emphasis,
      height: 1.05,
    );
    final x = eligibility.effectiveDays < 0 ? 0 : eligibility.effectiveDays;
    final n = eligibility.requiredDays < 0 ? 0 : eligibility.requiredDays;

    // 目前仅 ucgEntry；保留 kind 便于日后扩展。
    final remainingLine = <InlineSpan>[
      const TextSpan(text: '需连续记录 '),
      TextSpan(text: '$x', style: numberSmallStyle),
      const TextSpan(text: ' / '),
      TextSpan(text: '$n', style: numberStyle),
      const TextSpan(text: ' 天宝宝作息，\n解锁广场与真实带娃家庭分享经验'),
    ];
    assert(kind == FeedingEligibilityProgressKind.ucgEntry);

    return Text.rich(
      TextSpan(
        style: base,
        children: remainingLine,
      ),
      textAlign: textAlign,
    );
  }
}
