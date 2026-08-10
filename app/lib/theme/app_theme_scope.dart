import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import 'app_color.dart';
import 'app_visual_tokens.dart';
import 'theme_preset.dart';

/// 登录后由业务写入，用于全局主题默认色。
final babySexProvider = StateProvider<BabySex>((ref) => BabySex.unknown);

/// 用户在设置页保存的主题基线（持久化来源）。
final customBackgroundProvider = StateProvider<Color?>((ref) => null);

final themePresetProvider = StateProvider<ThemePreset?>((ref) => null);

/// 是否启用 19:00–05:00 自动夜空（默认 false，未持久化时视为关闭）。
final themeScheduleEnabledProvider = StateProvider<bool>((ref) => false);

/// 定时主题 tick；变更后 [effectiveThemeProvider] 重算展示主题。
final themeScheduleTickProvider = StateProvider<int>((ref) => 0);

/// 经典浅色 preset 用性别主色；其它 preset / 自定义背景从 bundle 种子推导 accent。
Color _resolveSchemeSeed(VisualBundle bundle, BabySex sex) {
  if (bundle.preset == ThemePreset.classicLight) {
    return sexPrimary(sex);
  }
  return bundle.seedColor;
}

Color _resolveThemePrimary(VisualBundle bundle, BabySex sex) {
  if (bundle.preset == ThemePreset.classicLight) {
    return sexPrimary(sex);
  }
  if (bundle.isDarkShell) {
    return bundle.seedColor;
  }
  return ColorScheme.fromSeed(seedColor: bundle.seedColor).primary;
}

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

/// 内容卡玻璃底 → [AppColor.contentCard]（alpha 参数忽略，保留签名兼容）。
@Deprecated('Use AppColor.contentCard / AppColor.modalFill by role')
Color themeGlassFill(
  BuildContext context, {
  double lightWhiteAlpha = 0.55,
  double darkPrimaryAlpha = 0.12,
}) {
  return AppColor.contentCard(context);
}

/// 内容卡描边 → divider / content 边（兼容旧调用）。
@Deprecated('Use AppColor.divider or AppColor.modalBorder by role')
Color themeGlassBorder(
  BuildContext context, {
  double lightWhiteAlpha = 0.45,
}) {
  return AppColor.divider(context);
}

/// 次要/取消类前景 → [AppColor.textMuted]。
Color themeMutedForeground(BuildContext context, {double alpha = 0.55}) {
  if ((alpha - 0.55).abs() < 0.001) return AppColor.textMuted(context);
  return AppColor.textPrimary(context).withValues(alpha: alpha);
}

/// 壳上主文字 → [AppColor.textPrimary]。
Color themeShellForeground(BuildContext context) => AppColor.textPrimary(context);

/// 实心主色按钮字色 → [AppColor.onPrimary]。
Color themeOnPrimary(BuildContext context) => AppColor.onPrimary(context);

ThemeData buildAppTheme({
  required BabySex sex,
  Color? customBackground,
  ThemePreset? preset,
}) {
  final bundle = resolveVisualBundle(sex: sex, seed: customBackground, preset: preset);
  final tokens = bundle.toTokens();
  final schemeSeed = _resolveSchemeSeed(bundle, sex);
  final primaryColor = _resolveThemePrimary(bundle, sex);

  final scheme = ColorScheme.fromSeed(
    seedColor: schemeSeed,
    brightness: tokens.isDarkShell ? Brightness.dark : Brightness.light,
  ).copyWith(
    surface: tokens.surfaceColor,
    primary: primaryColor,
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
