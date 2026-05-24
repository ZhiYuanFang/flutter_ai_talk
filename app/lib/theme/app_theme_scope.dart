import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';

/// 登录后由业务写入，用于全局主题默认色。
final babySexProvider = StateProvider<BabySex>((ref) => BabySex.unknown);

final customBackgroundProvider = StateProvider<Color?>((ref) => null);

Color _sexPrimary(BabySex sex) {
  switch (sex) {
    case BabySex.male:
      return const Color(0xFF0D47A1);
    case BabySex.female:
      return const Color(0xFFC62828);
    case BabySex.unknown:
      return const Color(0xFF455A64);
  }
}

/// 主题主色叠在 [ThemeData.scaffoldBackgroundColor] 上（随性别主题与自定义背景变化）。
Color themePrimaryBlend(BuildContext context, {double alpha = 0.12}) {
  final theme = Theme.of(context);
  return Color.alphaBlend(
    theme.colorScheme.primary.withValues(alpha: alpha),
    theme.scaffoldBackgroundColor,
  );
}

Color themePrimaryBlendFromTheme(ThemeData theme, ColorScheme scheme, {double alpha = 0.12}) {
  return Color.alphaBlend(
    scheme.primary.withValues(alpha: alpha),
    theme.scaffoldBackgroundColor,
  );
}

ThemeData buildAppTheme({
  required BabySex sex,
  Color? customBackground,
}) {
  final primary = _sexPrimary(sex);
  final bg = customBackground ?? Color.alphaBlend(primary.withValues(alpha: 0.08), Colors.white);
  final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light);
  final shell = ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    useMaterial3: true,
  );
  final appBarBg = themePrimaryBlendFromTheme(shell, scheme, alpha: 0.12);
  final appBarFg = ThemeData.estimateBrightnessForColor(appBarBg) == Brightness.dark
      ? Colors.white
      : Colors.black87;
  return shell.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBg,
      foregroundColor: appBarFg,
      iconTheme: IconThemeData(color: appBarFg),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: themePrimaryBlendFromTheme(shell, scheme, alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
