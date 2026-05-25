import 'package:flutter/material.dart';

/// 产品 shell / surface / pill / panel 语义色，与 [ColorScheme] 并存。
class AppVisualTokens extends ThemeExtension<AppVisualTokens> {
  const AppVisualTokens({
    required this.shellColor,
    required this.surfaceColor,
    required this.surfaceBorderColor,
    required this.pillBackground,
    required this.pillBorder,
    required this.recordsCardColor,
    required this.onShell,
    required this.onSurface,
    required this.panelShadow,
    required this.isDarkShell,
    this.surfaceRadius = 14,
  });

  final Color shellColor;
  final Color surfaceColor;
  final Color surfaceBorderColor;
  final Color pillBackground;
  final Color pillBorder;
  /// 主页历史按日记录卡片背景（主题浅色）。
  final Color recordsCardColor;
  final Color onShell;
  final Color onSurface;
  final List<BoxShadow> panelShadow;
  final bool isDarkShell;
  final double surfaceRadius;

  @override
  AppVisualTokens copyWith({
    Color? shellColor,
    Color? surfaceColor,
    Color? surfaceBorderColor,
    Color? pillBackground,
    Color? pillBorder,
    Color? recordsCardColor,
    Color? onShell,
    Color? onSurface,
    List<BoxShadow>? panelShadow,
    bool? isDarkShell,
    double? surfaceRadius,
  }) {
    return AppVisualTokens(
      shellColor: shellColor ?? this.shellColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      surfaceBorderColor: surfaceBorderColor ?? this.surfaceBorderColor,
      pillBackground: pillBackground ?? this.pillBackground,
      pillBorder: pillBorder ?? this.pillBorder,
      recordsCardColor: recordsCardColor ?? this.recordsCardColor,
      onShell: onShell ?? this.onShell,
      onSurface: onSurface ?? this.onSurface,
      panelShadow: panelShadow ?? this.panelShadow,
      isDarkShell: isDarkShell ?? this.isDarkShell,
      surfaceRadius: surfaceRadius ?? this.surfaceRadius,
    );
  }

  @override
  AppVisualTokens lerp(ThemeExtension<AppVisualTokens>? other, double t) {
    if (other is! AppVisualTokens) return this;
    return AppVisualTokens(
      shellColor: Color.lerp(shellColor, other.shellColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      surfaceBorderColor: Color.lerp(surfaceBorderColor, other.surfaceBorderColor, t)!,
      pillBackground: Color.lerp(pillBackground, other.pillBackground, t)!,
      pillBorder: Color.lerp(pillBorder, other.pillBorder, t)!,
      recordsCardColor: Color.lerp(recordsCardColor, other.recordsCardColor, t)!,
      onShell: Color.lerp(onShell, other.onShell, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      panelShadow: t < 0.5 ? panelShadow : other.panelShadow,
      isDarkShell: t < 0.5 ? isDarkShell : other.isDarkShell,
      surfaceRadius: surfaceRadius + (other.surfaceRadius - surfaceRadius) * t,
    );
  }
}

AppVisualTokens? visualTokensOf(BuildContext context) {
  return Theme.of(context).extension<AppVisualTokens>();
}
