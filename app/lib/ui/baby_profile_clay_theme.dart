import 'package:flutter/material.dart';

import '../theme/app_visual_tokens.dart';

/// 编辑宝宝信息页黏土拟态色板与尺寸；页面背景随 [AppVisualTokens.shellColor]。
abstract final class BabyProfileClayTheme {
  /// 页面背景：shell → surface 轻渐变，跟随当前主题预设。
  static BoxDecoration pageDecoration(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final scheme = Theme.of(context).colorScheme;
    final shell = tokens?.shellColor ?? scheme.surface;
    final surface = tokens?.surfaceColor ?? shell;
    final isDark = tokens?.isDarkShell ?? (Theme.of(context).brightness == Brightness.dark);
    final end = isDark
        ? Color.lerp(shell, surface, 0.45) ?? surface
        : Color.lerp(shell, Colors.white, 0.22) ?? surface;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shell, end],
      ),
    );
  }

  static Color pageForeground(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    return tokens?.onShell ?? Theme.of(context).colorScheme.onSurface;
  }

  static const cardColor = Color(0xFFFAFAFA);
  static const cardRadius = 28.0;
  static const fieldRadius = 20.0;
  static const chipRadius = 18.0;

  static const textPrimary = Color(0xFF3D454C);
  static const textSecondary = Color(0xFF7A8690);
  static const insetFill = Color(0xFFEEF1F4);
  static const insetBorder = Color(0xFFD8DEE4);

  static const maleChipFill = Color(0xFFD6EBFF);
  static const maleChipBorder = Color(0xFF90C8F5);
  static const femaleChipFill = Color(0xFFFFE0EC);
  static const femaleChipBorder = Color(0xFFF5A8C8);

  static const accentBlue = Color(0xFF5BA3E8);
  static const accentPink = Color(0xFFE88BB0);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFFE8C4A8).withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.85),
          blurRadius: 0,
          offset: const Offset(0, -1),
        ),
      ];

  static List<BoxShadow> get insetShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
          spreadRadius: -1,
        ),
      ];
}
