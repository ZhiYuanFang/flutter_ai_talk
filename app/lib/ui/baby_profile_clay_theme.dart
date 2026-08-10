import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_visual_tokens.dart';

/// 编辑宝宝信息页黏土拟态：壳/字/卡走 AppColor 原子；性别芯片为产品例外。
abstract final class BabyProfileClayTheme {
  /// 页面背景：shell → surface 轻渐变。
  static BoxDecoration pageDecoration(BuildContext context) {
    final tokens = Theme.of(context).extension<AppVisualTokens>();
    final shell = AppColor.pageBg(context);
    final surface = AppColor.surface(context);
    final end = tokens?.isDarkShell == true
        ? Color.lerp(shell, surface, 0.45) ?? surface
        : Color.lerp(shell, AppColor.contentCard(context), 0.22) ?? surface;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shell, end],
      ),
    );
  }

  static Color pageForeground(BuildContext context) =>
      AppColor.textPrimary(context);

  static const cardRadius = 28.0;
  static const fieldRadius = 20.0;
  static const chipRadius = 18.0;

  static Color cardColorOf(BuildContext context) => AppColor.surface(context);

  static Color textPrimaryOf(BuildContext context) =>
      AppColor.textPrimary(context);

  static Color textSecondaryOf(BuildContext context) =>
      AppColor.textSecondary(context);

  static Color insetFillOf(BuildContext context) => AppColor.fieldFill(context);

  static Color insetBorderOf(BuildContext context) =>
      AppColor.fieldBorder(context);

  // 性别芯片：产品语义色例外（非壳主题）
  static const maleChipFill = Color(0xFFD6EBFF);
  static const maleChipBorder = Color(0xFF90C8F5);
  static const femaleChipFill = Color(0xFFFFE0EC);
  static const femaleChipBorder = Color(0xFFF5A8C8);

  static const accentBlue = Color(0xFF5BA3E8);
  static const accentPink = Color(0xFFE88BB0);

  static List<BoxShadow> cardShadowOf(BuildContext context) {
    final dark =
        Theme.of(context).extension<AppVisualTokens>()?.isDarkShell == true;
    if (dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
    }
    return [
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
  }

  static List<BoxShadow> insetShadowOf(BuildContext context) {
    final dark =
        Theme.of(context).extension<AppVisualTokens>()?.isDarkShell == true;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.25 : 0.06),
        blurRadius: 6,
        offset: const Offset(0, 2),
        spreadRadius: -1,
      ),
    ];
  }
}
