import 'package:flutter/material.dart';

import '../../../theme/app_theme_scope.dart';
import '../../../theme/app_visual_tokens.dart';

/// Feed / 分享用假玻璃视觉 token（无 BackdropFilter）。
abstract final class UcgDebateVisualTokens {
  static const feedCardRadius = 16.0;
  static const vsBarRadius = 20.0;
  static const vsBarHeight = 54.0;
  static const vsCenterEmoji = '✨';
  static const argumentPillRadius = 12.0;

  static const macaronLeftStart = Color(0xFFB8DFF5);
  static const macaronLeftEnd = Color(0xFFA8D4F0);
  static const macaronRightStart = Color(0xFFFFD4DC);
  static const macaronRightEnd = Color(0xFFFFB5C5);

  static const macaronLabelColor = Color(0xFF2D4A66);
  static const macaronPercentColor = Color(0xFF5B7FA8);
  static const macaronPercentRightColor = Color(0xFFC45C7A);
}

/// 广场 Feed 假玻璃 panel：半透明白底 + primary 轻渐变 + 白边，无 blur。
class UcgFeedFakeGlassPanel extends StatelessWidget {
  const UcgFeedFakeGlassPanel({
    super.key,
    required this.child,
    this.contentPadding,
    this.borderRadius,
    this.eventAccent,
  });

  final Widget child;
  final EdgeInsets? contentPadding;
  final double? borderRadius;
  final Color? eventAccent;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final accent = eventAccent ?? scheme.primary;
    final radius = borderRadius ?? UcgDebateVisualTokens.feedCardRadius;

    final base = tokens?.recordsCardColor ?? themePrimaryBlend(context, alpha: 0.04);
    final fillTop = Color.alphaBlend(Colors.white.withValues(alpha: 0.78), base);
    final fillBottom = Color.lerp(fillTop, accent.withValues(alpha: 0.08), 0.4) ?? fillTop;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [fillTop, fillBottom],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: contentPadding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

Color ucgFeedFakeGlassTextColor(BuildContext context) {
  final tokens = Theme.of(context).extension<AppVisualTokens>();
  return tokens?.onRecordsCard ?? Theme.of(context).colorScheme.onSurface;
}

Color ucgFeedFakeGlassHintColor(BuildContext context) {
  return ucgFeedFakeGlassTextColor(context).withValues(alpha: 0.42);
}

Color ucgFeedFakeGlassSecondaryColor(BuildContext context) {
  return ucgFeedFakeGlassTextColor(context).withValues(alpha: 0.62);
}

Color ucgFeedFakeGlassArgumentPillColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary.withValues(alpha: 0.05);
}

Color ucgFeedFakeGlassBorderColor(BuildContext context) {
  return Colors.white.withValues(alpha: 0.82);
}
