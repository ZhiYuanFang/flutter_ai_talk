import 'package:flutter/material.dart';

import '../../theme/app_theme_scope.dart';
import '../../theme/app_visual_tokens.dart';

/// UCG 模块共享主题语义色，避免硬编码 [Colors.*]。
abstract final class UcgTheme {
  static ColorScheme scheme(BuildContext context) => Theme.of(context).colorScheme;

  static AppVisualTokens? tokens(BuildContext context) =>
      Theme.of(context).extension<AppVisualTokens>();

  static Color onShell(BuildContext context) =>
      tokens(context)?.onShell ?? scheme(context).onSurface;

  static Color primary(BuildContext context) => scheme(context).primary;

  static Color onPrimary(BuildContext context) => scheme(context).onPrimary;

  static Color surface(BuildContext context) =>
      tokens(context)?.surfaceColor ?? scheme(context).surface;

  static Color transparentFill(BuildContext context, {double alpha = 0.9}) =>
      surface(context).withValues(alpha: alpha);

  static Color scrim(BuildContext context, {double alpha = 0.26}) =>
      onShell(context).withValues(alpha: alpha);

  static Color primaryGradientEnd(BuildContext context) {
    final p = primary(context);
    return Color.lerp(p, surface(context), 0.15)!;
  }

  static Color pillBorder(BuildContext context) =>
      tokens(context)?.pillBorder ?? primary(context).withValues(alpha: 0.35);

  static Color pillBackground(BuildContext context) =>
      tokens(context)?.pillBackground ?? themePrimaryBlend(context, alpha: 0.08);

  static Color onRecordsCard(BuildContext context) =>
      tokens(context)?.onRecordsCard ?? onShell(context);

  static Color surfaceBorder(BuildContext context) =>
      tokens(context)?.surfaceBorderColor ?? onShell(context).withValues(alpha: 0.22);
}
