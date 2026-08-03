import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_theme_scope.dart';
import '../../../theme/app_visual_tokens.dart';

/// 发布页专用浅色玻璃 panel（磨砂白底 + primary 轻 tint，深色正文）。
class UcgComposeLightGlassPanel extends StatelessWidget {
  const UcgComposeLightGlassPanel({
    super.key,
    required this.child,
    this.eventAccent,
    this.contentPadding,
    this.borderRadius,
    /// 默认抗锯齿裁剪；选区手柄场景可传 [Clip.none] 避免裁掉手柄
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final Color? eventAccent;
  final EdgeInsets? contentPadding;
  final double? borderRadius;
  final Clip clipBehavior;

  static const _radius = 22.0;
  static const _blurSigma = 18.0;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final accent = eventAccent ?? scheme.primary;
    final radius = borderRadius ?? _radius;

    final base =
        tokens?.recordsCardColor ?? themePrimaryBlend(context, alpha: 0.04);
    final fillTop =
        Color.alphaBlend(Colors.white.withValues(alpha: 0.78), base);
    final fillBottom = Color.lerp(
          fillTop,
          accent.withValues(alpha: 0.10),
          0.45,
        ) ??
        fillTop;
    // 如果eventAccent为透明色，则不展示背景，直接展示子组件
    if (eventAccent == Colors.transparent) {
      return child;
    } else {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: clipBehavior,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                  colors: [fillTop, fillBottom],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    contentPadding ?? const EdgeInsets.fromLTRB(18, 20, 18, 16),
                child: child,
              ),
            ),
          ),
        ),
      );
    }
  }
}

Color ucgComposeLightTextColor(BuildContext context) {
  final tokens = Theme.of(context).extension<AppVisualTokens>();
  return tokens?.onRecordsCard ?? Theme.of(context).colorScheme.onSurface;
}

Color ucgComposeLightHintColor(BuildContext context) {
  final fg = ucgComposeLightTextColor(context);
  return fg.withValues(alpha: 0.42);
}

Color ucgComposeLightSecondaryColor(BuildContext context) {
  final fg = ucgComposeLightTextColor(context);
  return fg.withValues(alpha: 0.62);
}
