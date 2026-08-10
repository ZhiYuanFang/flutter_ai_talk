import 'package:flutter/material.dart';

import '../../../theme/app_color.dart';

/// Feed / 分享用假玻璃视觉 token（几何/emoji；色经 [AppColor]）。
abstract final class UcgDebateVisualTokens {
  static const feedCardRadius = 16.0;
  static const vsBarRadius = 20.0;
  static const vsBarHeight = 54.0;
  static const vsCenterEmoji = '✨';
  static const argumentPillRadius = 12.0;
}

/// 广场 Feed 假玻璃 panel：panelGlass 原子（与预测 chrome 同族）。
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
    final accent = eventAccent ?? AppColor.primary(context);
    final radius = borderRadius ?? UcgDebateVisualTokens.feedCardRadius;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColor.divider(context)),
          // 主题色暗浮层 / 浅壳玻璃：A 默认 + B 可选 accent
          gradient: AppColor.panelGlassGradient(context, accent: eventAccent),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColor.pageBg(context).withValues(alpha: 0.35),
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

Color ucgFeedFakeGlassTextColor(BuildContext context) =>
    AppColor.textOnPanelGlass(context);

Color ucgFeedFakeGlassHintColor(BuildContext context) {
  return AppColor.textOnPanelGlassMuted(context).withValues(alpha: 0.55);
}

Color ucgFeedFakeGlassSecondaryColor(BuildContext context) {
  return AppColor.textOnPanelGlassMuted(context);
}

Color ucgFeedFakeGlassArgumentPillColor(BuildContext context) {
  return AppColor.primary(context).withValues(alpha: 0.05);
}

Color ucgFeedFakeGlassBorderColor(BuildContext context) =>
    AppColor.divider(context);