import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import 'app_visual_tokens.dart';
import 'theme_preset.dart';

/// 登录后由业务写入，用于全局主题默认色。
final babySexProvider = StateProvider<BabySex>((ref) => BabySex.unknown);

final customBackgroundProvider = StateProvider<Color?>((ref) => null);

final themePresetProvider = StateProvider<ThemePreset?>((ref) => null);

Color _sexPrimary(BabySex sex) => sexPrimary(sex);

/// 主题主色叠在 shell 或 surface 上（随深色 shell 分支变化）。
Color themePrimaryBlend(BuildContext context, {double alpha = 0.12}) {
  final theme = Theme.of(context);
  final tokens = theme.extension<AppVisualTokens>();
  final base = tokens != null && tokens.isDarkShell
      ? tokens.surfaceColor
      : theme.scaffoldBackgroundColor;
  return Color.alphaBlend(
    theme.colorScheme.primary.withValues(alpha: alpha),
    base,
  );
}

Color themePrimaryBlendFromTheme(ThemeData theme, ColorScheme scheme, {double alpha = 0.12}) {
  final tokens = theme.extension<AppVisualTokens>();
  final base = tokens != null && tokens.isDarkShell
      ? tokens.surfaceColor
      : theme.scaffoldBackgroundColor;
  return Color.alphaBlend(
    scheme.primary.withValues(alpha: alpha),
    base,
  );
}

ThemeData buildAppTheme({
  required BabySex sex,
  Color? customBackground,
  ThemePreset? preset,
}) {
  final bundle = resolveVisualBundle(sex: sex, seed: customBackground, preset: preset);
  final tokens = bundle.toTokens();
  final sexPrimaryColor = _sexPrimary(sex);
  final accentSeed = tokens.isDarkShell ? bundle.seedColor : sexPrimaryColor;

  final scheme = ColorScheme.fromSeed(
    seedColor: accentSeed,
    brightness: tokens.isDarkShell ? Brightness.dark : Brightness.light,
  ).copyWith(
    surface: tokens.surfaceColor,
    primary: tokens.isDarkShell ? accentSeed : sexPrimaryColor,
  );

  final shell = ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.shellColor,
    useMaterial3: true,
    extensions: [tokens],
  );

  final appBarBg = tokens.isDarkShell
      ? tokens.shellColor
      : themePrimaryBlendFromTheme(shell, scheme, alpha: 0.12);
  final appBarFg = tokens.isDarkShell
      ? tokens.onShell
      : (ThemeData.estimateBrightnessForColor(appBarBg) == Brightness.dark
          ? Colors.white
          : Colors.black87);

  return shell.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBg,
      foregroundColor: appBarFg,
      iconTheme: IconThemeData(color: appBarFg),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: tokens.isDarkShell
          ? tokens.surfaceColor
          : themePrimaryBlendFromTheme(shell, scheme, alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.surfaceRadius)),
    ),
  );
}
