import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../../theme/app_theme_scope.dart';
import '../../theme/app_visual_tokens.dart';

/// UCG 模块共享主题入口：仅转发 [AppColor]，不另起色源。
abstract final class UcgTheme {
  static ColorScheme scheme(BuildContext context) => Theme.of(context).colorScheme;

  /// 遗留兼容；新代码优先 [AppColor]。
  static AppVisualTokens? tokens(BuildContext context) => visualTokensOf(context);

  static Color onShell(BuildContext context) => AppColor.textPrimary(context);

  static Color primary(BuildContext context) => AppColor.primary(context);

  static Color onPrimary(BuildContext context) => AppColor.onPrimary(context);

  static Color surface(BuildContext context) => AppColor.surface(context);

  static Color transparentFill(BuildContext context, {double alpha = 0.9}) =>
      surface(context).withValues(alpha: alpha);

  static Color scrim(BuildContext context, {double alpha = 0.26}) =>
      onShell(context).withValues(alpha: alpha);

  static Color primaryGradientEnd(BuildContext context) {
    final p = primary(context);
    return Color.lerp(p, surface(context), 0.15)!;
  }

  static Color pillBorder(BuildContext context) =>
      visualTokensOf(context)?.pillBorder ??
      primary(context).withValues(alpha: 0.35);

  static Color pillBackground(BuildContext context) =>
      visualTokensOf(context)?.pillBackground ??
      themePrimaryBlend(context, alpha: 0.08);

  /// 内容卡正文；广场假玻璃请用 [AppColor.textOnPanelGlass]。
  static Color onRecordsCard(BuildContext context) =>
      AppColor.textOnContentCard(context);

  static Color surfaceBorder(BuildContext context) => AppColor.divider(context);
}
