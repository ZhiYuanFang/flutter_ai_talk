import 'package:flutter/material.dart';

import '../data/models.dart';
import 'app_visual_tokens.dart';

/// 主题预设标识（持久化用）。
enum ThemePreset {
  classicLight('classic_light'),
  nightSky('night_sky'),
  softBlue('soft_blue'),
  softPink('soft_pink'),
  softGreen('soft_green'),
  softYellow('soft_yellow'),
  softGrey('soft_grey'),
  softPurple('soft_purple');

  const ThemePreset(this.id);
  final String id;

  static ThemePreset? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final p in ThemePreset.values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// 夜空 shell：更深的海军蓝。
const kNightSkyShell = Color(0xFF0B1D42);

/// 夜空 surface：略亮于 shell 的深蓝。
const kNightSkySurface = Color(0xFF122A52);

/// 夜空 accent：用于 ColorScheme.primary 与浅色推导。
const kNightSkyAccent = Color(0xFF4A82E0);

/// 纯黑背景迁移前旧值。
const kLegacyPureBlack = Color(0xFF000000);

/// Material 浅色块（设置页 picker / 预设网格）。
const kThemeSoftSwatchColors = <Color>[
  Color(0xFFE3F2FD),
  Color(0xFFFFEBEE),
  Color(0xFFE8F5E9),
  Color(0xFFFFF8E1),
  Color(0xFFECEFF1),
  Color(0xFFE1BEE7),
];

const _darkLuminanceThreshold = 0.25;

Color sexPrimary(BabySex sex) {
  switch (sex) {
    case BabySex.male:
      return const Color(0xFF0D47A1);
    case BabySex.female:
      return const Color(0xFFC62828);
    case BabySex.unknown:
      return const Color(0xFF455A64);
  }
}

class VisualBundle {
  const VisualBundle({
    required this.seedColor,
    required this.shellColor,
    required this.surfaceColor,
    required this.isDarkShell,
    this.preset,
  });

  final Color seedColor;
  final Color shellColor;
  final Color surfaceColor;
  final bool isDarkShell;
  final ThemePreset? preset;

  AppVisualTokens toTokens() {
    final onShell = _readableOn(shellColor);
    final onSurface = _readableOn(surfaceColor);
    final pillBg = _adjustLightness(surfaceColor, isDarkShell ? 0.06 : 0.04);
    final pillBorder = _adjustLightness(surfaceColor, isDarkShell ? 0.12 : 0.08);
    final borderAlpha = isDarkShell ? 0.22 : 0.14;
    final recordsCard = recordsCardColorForBundle(
      seedColor: seedColor,
      shellColor: shellColor,
      isDarkShell: isDarkShell,
    );
    return AppVisualTokens(
      shellColor: shellColor,
      surfaceColor: surfaceColor,
      surfaceBorderColor: onSurface.withValues(alpha: borderAlpha),
      pillBackground: pillBg,
      pillBorder: pillBorder.withValues(alpha: isDarkShell ? 0.45 : 0.35),
      recordsCardColor: recordsCard,
      onShell: onShell,
      onSurface: onSurface,
      panelShadow: isDarkShell
          ? [
              BoxShadow(
                color: shellColor.withValues(alpha: 0.55),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -1),
              ),
            ],
      isDarkShell: isDarkShell,
    );
  }
}

VisualBundle resolveVisualBundle({
  required BabySex sex,
  Color? seed,
  ThemePreset? preset,
}) {
  if (preset == ThemePreset.classicLight) {
    return classicLightBundle(sex);
  }
  if (preset == ThemePreset.nightSky) {
    return nightSkyBundle();
  }
  final swatchPreset = _presetForSwatch(preset);
  if (swatchPreset != null) {
    return lightSwatchBundle(swatchPreset);
  }
  if (seed == null) {
    return classicLightBundle(sex);
  }
  if (seed == kLegacyPureBlack) {
    return nightSkyBundle();
  }
  if (seed.computeLuminance() < _darkLuminanceThreshold) {
    return deriveDarkBundle(seed);
  }
  return VisualBundle(
    seedColor: seed,
    shellColor: seed,
    surfaceColor: _adjustLightness(seed, 0.03),
    isDarkShell: false,
  );
}

ThemePreset? _presetForSwatch(ThemePreset? preset) {
  if (preset == null) return null;
  return switch (preset) {
    ThemePreset.softBlue ||
    ThemePreset.softPink ||
    ThemePreset.softGreen ||
    ThemePreset.softYellow ||
    ThemePreset.softGrey ||
    ThemePreset.softPurple =>
      preset,
    _ => null,
  };
}

VisualBundle classicLightBundle(BabySex sex) {
  final primary = sexPrimary(sex);
  final shell = Color.alphaBlend(primary.withValues(alpha: 0.08), Colors.white);
  return VisualBundle(
    seedColor: primary,
    shellColor: shell,
    surfaceColor: Color.alphaBlend(primary.withValues(alpha: 0.04), Colors.white),
    isDarkShell: false,
    preset: ThemePreset.classicLight,
  );
}

VisualBundle nightSkyBundle() {
  return const VisualBundle(
    seedColor: kNightSkyAccent,
    shellColor: kNightSkyShell,
    surfaceColor: kNightSkySurface,
    isDarkShell: true,
    preset: ThemePreset.nightSky,
  );
}

VisualBundle lightSwatchBundle(ThemePreset preset) {
  final color = _swatchColorForPreset(preset);
  return VisualBundle(
    seedColor: color,
    shellColor: color,
    surfaceColor: _adjustLightness(color, 0.03),
    isDarkShell: false,
    preset: preset,
  );
}

Color _swatchColorForPreset(ThemePreset preset) {
  return switch (preset) {
    ThemePreset.softBlue => kThemeSoftSwatchColors[0],
    ThemePreset.softPink => kThemeSoftSwatchColors[1],
    ThemePreset.softGreen => kThemeSoftSwatchColors[2],
    ThemePreset.softYellow => kThemeSoftSwatchColors[3],
    ThemePreset.softGrey => kThemeSoftSwatchColors[4],
    ThemePreset.softPurple => kThemeSoftSwatchColors[5],
    _ => kThemeSoftSwatchColors[0],
  };
}

ThemePreset? presetForSwatchColor(Color color) {
  final index = kThemeSoftSwatchColors.indexWhere((c) => c.value == color.value);
  return switch (index) {
    0 => ThemePreset.softBlue,
    1 => ThemePreset.softPink,
    2 => ThemePreset.softGreen,
    3 => ThemePreset.softYellow,
    4 => ThemePreset.softGrey,
    5 => ThemePreset.softPurple,
    _ => null,
  };
}

VisualBundle deriveDarkBundle(Color seed) {
  final hsl = HSLColor.fromColor(seed);
  final shellL = hsl.lightness.clamp(0.10, 0.16);
  final shell = hsl.withLightness(shellL).toColor();
  final surface = hsl.withLightness((shellL + 0.07).clamp(0.0, 1.0)).toColor();
  return VisualBundle(
    seedColor: seed,
    shellColor: shell,
    surfaceColor: surface,
    isDarkShell: true,
  );
}

Color _adjustLightness(Color base, double delta) {
  final hsl = HSLColor.fromColor(base);
  return hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0)).toColor();
}

/// 历史「按日记录」卡片：主题种子浅色化，与 shell 形成对比。
Color recordsCardColorForBundle({
  required Color seedColor,
  required Color shellColor,
  required bool isDarkShell,
}) {
  final hsl = HSLColor.fromColor(seedColor);
  if (isDarkShell) {
    return hsl
        .withLightness(0.94)
        .withSaturation((hsl.saturation * 0.2 + 0.04).clamp(0.0, 0.32))
        .toColor();
  }
  final lifted = Color.alphaBlend(Colors.white.withValues(alpha: 0.72), shellColor);
  return Color.alphaBlend(seedColor.withValues(alpha: 0.08), lifted);
}

Color _readableOn(Color background) {
  final bgL = background.computeLuminance();
  final light = Colors.white.withValues(alpha: 0.87);
  final dark = Colors.black.withValues(alpha: 0.87);
  final onLight = light.computeLuminance();
  final onDark = dark.computeLuminance();
  final contrastLight = (onLight - bgL).abs();
  final contrastDark = (onDark - bgL).abs();
  return contrastLight >= contrastDark ? light : dark;
}
