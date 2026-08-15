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

/// 历史 soft 预设（设置页已移除，加载时迁移为自定义 seed）。
bool isSoftSwatchThemePreset(ThemePreset preset) {
  return switch (preset) {
    ThemePreset.softBlue ||
    ThemePreset.softPink ||
    ThemePreset.softGreen ||
    ThemePreset.softYellow ||
    ThemePreset.softGrey ||
    ThemePreset.softPurple =>
      true,
    _ => false,
  };
}
Color sexPrimary(BabySex sex) {
  switch (sex) {
    case BabySex.male:
      return const Color(0xFF0D47A1);
    case BabySex.female:
      return const Color(0xFFE91E63);
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
    final onRecordsCard = _readableOn(recordsCard);

    // modal：暗壳 = surface 暗浮层；浅壳 = 浅玻璃（勿与 content 浅卡混用前景）
    final Color modalFill;
    final Color modalBorder;
    final Color onModal;
    if (isDarkShell) {
      modalFill = Color.alphaBlend(
        seedColor.withValues(alpha: 0.14),
        surfaceColor,
      );
      onModal = _readableOn(modalFill);
      modalBorder = onModal.withValues(alpha: 0.22);
    } else {
      modalFill = Color.alphaBlend(
        Colors.white.withValues(alpha: 0.55),
        recordsCard,
      );
      onModal = _readableOn(modalFill);
      modalBorder = Colors.white.withValues(alpha: 0.45);
    }

    // 输入壳：暗壳 surface+seed；浅壳浅 inset
    final fieldFill = isDarkShell
        ? Color.alphaBlend(seedColor.withValues(alpha: 0.08), surfaceColor)
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.35), surfaceColor);
    final fieldBorder = isDarkShell
        ? onSurface.withValues(alpha: 0.28)
        : onSurface.withValues(alpha: 0.14);

    // 页内 chrome：暗壳 surface+亮 accent；浅壳近白 base+seed（经典/彩色同构）
    final Color panelGlassTop;
    final Color panelGlassBottom;
    if (isDarkShell) {
      final lifted = _adjustLightness(surfaceColor, 0.06);
      panelGlassTop = Color.alphaBlend(
        seedColor.withValues(alpha: 0.26),
        lifted,
      );
      panelGlassBottom = Color.alphaBlend(
        seedColor.withValues(alpha: 0.10),
        surfaceColor,
      );
    } else {
      // 近白玻璃底：不绑满色 shell/recordsCard，避免彩色 top≈bottom
      final lightGlassBase = Color.alphaBlend(
        seedColor.withValues(alpha: 0.04),
        Colors.white,
      );
      panelGlassTop = Color.alphaBlend(
        seedColor.withValues(alpha: 0.18),
        lightGlassBase,
      );
      // bottom 更白，保证可辨 ΔL 渐变
      panelGlassBottom = Color.alphaBlend(
        Colors.white.withValues(alpha: 0.55),
        lightGlassBase,
      );
    }
    final onPanelGlass = _readableOn(panelGlassTop);

    // 辩论马卡龙初值对齐历史 hex；暗壳略叠 surface 降刺眼、字色保持可辨。
    const leftStart = Color(0xFFB8DFF5);
    const leftEnd = Color(0xFFA8D4F0);
    const rightStart = Color(0xFFFFD4DC);
    const rightEnd = Color(0xFFFFB5C5);
    const leftLabel = Color(0xFF2D4A66);
    const leftPercent = Color(0xFF5B7FA8);
    const rightPercent = Color(0xFFC45C7A);
    final debateLeftStart = isDarkShell
        ? Color.alphaBlend(leftStart.withValues(alpha: 0.88), surfaceColor)
        : leftStart;
    final debateLeftEnd = isDarkShell
        ? Color.alphaBlend(leftEnd.withValues(alpha: 0.88), surfaceColor)
        : leftEnd;
    final debateRightStart = isDarkShell
        ? Color.alphaBlend(rightStart.withValues(alpha: 0.88), surfaceColor)
        : rightStart;
    final debateRightEnd = isDarkShell
        ? Color.alphaBlend(rightEnd.withValues(alpha: 0.88), surfaceColor)
        : rightEnd;
    // VS chrome：浅玻璃白边/白钮；暗壳改用 onPanelGlass 系，避免硬编码白。
    final debateVsChipFill = isDarkShell
        ? Color.alphaBlend(onPanelGlass.withValues(alpha: 0.92), panelGlassTop)
        : Colors.white.withValues(alpha: 0.94);
    final debateVsChipBorder = isDarkShell
        ? onPanelGlass.withValues(alpha: 0.98)
        : Colors.white.withValues(alpha: 0.98);
    final debateVsOnChip = _readableOn(debateVsChipFill);
    final debateVsBarBorder = isDarkShell
        ? onPanelGlass.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.75);
    final debateVsBarGlassTop = isDarkShell
        ? onPanelGlass.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.55);
    final debateVsSideBorder = isDarkShell
        ? onPanelGlass.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.45);
    final debateVsSideBorderSelected = isDarkShell
        ? onPanelGlass.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.92);
    final debateVsStickerFill = isDarkShell
        ? Color.alphaBlend(onPanelGlass.withValues(alpha: 0.88), panelGlassTop)
        : Colors.white.withValues(alpha: 0.9);
    final debateVsStickerBorder = isDarkShell
        ? onPanelGlass.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.95);

    return AppVisualTokens(
      shellColor: shellColor,
      surfaceColor: surfaceColor,
      surfaceBorderColor: onSurface.withValues(alpha: borderAlpha),
      pillBackground: pillBg,
      pillBorder: pillBorder.withValues(alpha: isDarkShell ? 0.45 : 0.35),
      recordsCardColor: recordsCard,
      onRecordsCard: onRecordsCard,
      onShell: onShell,
      onSurface: onSurface,
      modalFill: modalFill,
      modalBorder: modalBorder,
      onModal: onModal,
      fieldFill: fieldFill,
      fieldBorder: fieldBorder,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      panelGlassTop: panelGlassTop,
      panelGlassBottom: panelGlassBottom,
      onPanelGlass: onPanelGlass,
      debateLeftStart: debateLeftStart,
      debateLeftEnd: debateLeftEnd,
      debateRightStart: debateRightStart,
      debateRightEnd: debateRightEnd,
      debateLeftLabel: leftLabel,
      debateLeftPercent: leftPercent,
      debateRightLabel: leftLabel,
      debateRightPercent: rightPercent,
      debateVsChipFill: debateVsChipFill,
      debateVsChipBorder: debateVsChipBorder,
      debateVsOnChip: debateVsOnChip,
      debateVsBarBorder: debateVsBarBorder,
      debateVsBarGlassTop: debateVsBarGlassTop,
      debateVsSideBorder: debateVsSideBorder,
      debateVsSideBorderSelected: debateVsSideBorderSelected,
      debateVsStickerFill: debateVsStickerFill,
      debateVsStickerBorder: debateVsStickerBorder,
      mediaScrim: Colors.black.withValues(alpha: 0.92),
      onMediaScrim: Colors.white.withValues(alpha: 0.92),
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
  // 设置「彩色」自定义浅色：与经典同构近白壳+染料（禁止 shell=满色 seed）
  return lightTintedBundle(seed: seed);
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

/// 浅色同构配方：近白壳 + seed 染料（经典 / 设置「彩色」/ soft swatch 共用）。
VisualBundle lightTintedBundle({
  required Color seed,
  ThemePreset? preset,
}) {
  final shell = Color.alphaBlend(seed.withValues(alpha: 0.08), Colors.white);
  return VisualBundle(
    seedColor: seed,
    shellColor: shell,
    surfaceColor:
        Color.alphaBlend(seed.withValues(alpha: 0.04), Colors.white),
    isDarkShell: false,
    preset: preset,
  );
}

VisualBundle classicLightBundle(BabySex sex) {
  return lightTintedBundle(
    seed: sexPrimary(sex),
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
  // 与经典同构：色板色作染料，页底近白淡染（避免满色壳灌 BackdropFilter）
  return lightTintedBundle(
    seed: _swatchColorForPreset(preset),
    preset: preset,
  );
}

Color swatchColorForThemePreset(ThemePreset preset) => _swatchColorForPreset(preset);

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
  // chrome 染料：偏亮 accent（对齐夜空 seed 角色），勿用暗壳色暗叠暗
  final accent = _darkChromeAccentFromSeed(hsl);
  return VisualBundle(
    seedColor: accent,
    shellColor: shell,
    surfaceColor: surface,
    isDarkShell: true,
  );
}

/// 预测横屏 TV 压暗：对浅色 shell/surface 黑叠降亮，保留 seed 与相对色差。
/// 不得把粉彩 seed 夹死到同一暗区（对比 [deriveDarkBundle]）。
VisualBundle deriveLandscapeTvDimBundle(VisualBundle light) {
  // 黑叠压暗近白淡染壳，粉/蓝相对差得以保留
  final shell = Color.alphaBlend(
    Colors.black.withValues(alpha: 0.44),
    light.shellColor,
  );
  final surface = Color.alphaBlend(
    Colors.black.withValues(alpha: 0.32),
    light.surfaceColor,
  );
  final isDarkShell = shell.computeLuminance() < _darkLuminanceThreshold;
  return VisualBundle(
    seedColor: light.seedColor,
    shellColor: shell,
    surfaceColor: surface,
    isDarkShell: isDarkShell,
    preset: light.preset,
  );
}

/// 自暗色输入派生 panelGlass / ColorScheme 用亮染料（结构对齐 kNightSkyAccent）。
Color _darkChromeAccentFromSeed(HSLColor seedHsl) {
  final accentL = (seedHsl.lightness + 0.38).clamp(0.42, 0.58);
  final accentS =
      (seedHsl.saturation * 0.75 + 0.22).clamp(0.35, 0.78);
  return seedHsl.withLightness(accentL).withSaturation(accentS).toColor();
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
