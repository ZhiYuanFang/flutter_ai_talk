import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_color.dart';

/// 发布页玻璃 panel：挂 panelGlass 原子（与广场/预测 chrome 同族）。
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
    final accent = eventAccent ?? AppColor.primary(context);
    final radius = borderRadius ?? _radius;

    // 如果 eventAccent 为透明色，则不展示背景，直接展示子组件
    if (eventAccent == Colors.transparent) {
      return child;
    }
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColor.divider(context)),
              gradient: AppColor.panelGlassGradient(
                context,
                accent: eventAccent,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColor.pageBg(context).withValues(alpha: 0.35),
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

Color ucgComposeLightTextColor(BuildContext context) =>
    AppColor.textOnPanelGlass(context);

Color ucgComposeLightHintColor(BuildContext context) {
  return AppColor.textOnPanelGlassMuted(context).withValues(alpha: 0.55);
}

Color ucgComposeLightSecondaryColor(BuildContext context) {
  return AppColor.textOnPanelGlassMuted(context);
}
